package com.darkmintis.network_simulator.stack

import android.os.ParcelFileDescriptor
import com.darkmintis.network_simulator.config.TunnelConfig
import com.darkmintis.network_simulator.packet.Ipv4Packet
import com.darkmintis.network_simulator.shaper.NetworkConditionShaper
import com.darkmintis.network_simulator.shaper.TrafficShaper
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Local VPN packet pipeline: TUN → queue → TCP/UDP NAT → shaped upstream.
 *
 * The TUN reader stays non-blocking; shaping and socket IO run on workers.
 */
class LocalForwardingPipeline(
    private val protector: SocketProtector,
    private val shaper: TrafficShaper = NetworkConditionShaper(),
    val stats: TunnelStatsCollector = TunnelStatsCollector(),
) : PacketPipeline {
    private val running = AtomicBoolean(false)
    private var tunInterface: ParcelFileDescriptor? = null
    private var readerThread: Thread? = null
    private var executor: ExecutorService? = null
    private var packetExecutor: ExecutorService? = null
    private var udpSessions: UdpSessionManager? = null
    private var tcpSessions: TcpSessionManager? = null
    private val writeLock = Any()

    override fun start(tunInterface: ParcelFileDescriptor) {
        stop()
        this.tunInterface = tunInterface
        stats.reset()

        // Session pumps (connect + remote→TUN) share a bounded pool.
        val executor = ThreadPoolExecutor(
            4,
            32,
            60L,
            TimeUnit.SECONDS,
            LinkedBlockingQueue(256),
            Executors.defaultThreadFactory(),
            ThreadPoolExecutor.CallerRunsPolicy(),
        )
        this.executor = executor

        // Packet handling / shaping runs off the TUN reader.
        val packetExecutor = Executors.newFixedThreadPool(4)
        this.packetExecutor = packetExecutor

        val output = FileOutputStream(tunInterface.fileDescriptor)
        val writer: (ByteArray) -> Unit = { packet ->
            synchronized(writeLock) {
                runCatching { output.write(packet) }
            }
        }

        udpSessions = UdpSessionManager(protector, shaper, stats, writer, executor)
        tcpSessions = TcpSessionManager(protector, shaper, stats, writer, executor)

        running.set(true)
        readerThread = Thread({
            val input = FileInputStream(tunInterface.fileDescriptor)
            val buffer = ByteArray(32767)
            while (running.get()) {
                val length = try {
                    input.read(buffer)
                } catch (_: Exception) {
                    break
                }
                if (length < 0) break
                if (length == 0) {
                    try {
                        Thread.sleep(1)
                    } catch (_: InterruptedException) {
                        break
                    }
                    continue
                }
                val raw = buffer.copyOf(length)
                packetExecutor.execute {
                    if (!running.get()) return@execute
                    try {
                        val packet = Ipv4Packet.parse(raw) ?: return@execute
                        when (packet.protocol) {
                            Ipv4Packet.PROTOCOL_UDP -> udpSessions?.handlePacket(packet)
                            Ipv4Packet.PROTOCOL_TCP -> tcpSessions?.handlePacket(packet)
                            else -> stats.onDrop()
                        }
                    } catch (_: Exception) {
                        stats.onDrop()
                    }
                }
            }
        }, "network-simulator-tun-reader")
        readerThread?.start()
    }

    override fun stop() {
        running.set(false)
        readerThread?.interrupt()
        readerThread = null
        udpSessions?.closeAll()
        tcpSessions?.closeAll()
        udpSessions = null
        tcpSessions = null
        packetExecutor?.shutdownNow()
        packetExecutor = null
        executor?.shutdownNow()
        executor = null
        tunInterface = null
    }

    override fun updateConfig(config: TunnelConfig) {
        shaper.updateConfig(config)
    }
}

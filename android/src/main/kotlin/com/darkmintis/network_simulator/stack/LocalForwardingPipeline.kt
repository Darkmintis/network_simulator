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
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Local VPN packet pipeline: TUN → parse → TCP/UDP NAT → shaped upstream.
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
    private var udpSessions: UdpSessionManager? = null
    private var tcpSessions: TcpSessionManager? = null
    private val writeLock = Any()

    override fun start(tunInterface: ParcelFileDescriptor) {
        stop()
        this.tunInterface = tunInterface
        stats.reset()
        val executor = Executors.newFixedThreadPool(8)
        this.executor = executor

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
                if (length <= 0) {
                    Thread.sleep(1)
                    continue
                }
                val raw = buffer.copyOf(length)
                val packet = Ipv4Packet.parse(raw) ?: continue
                when (packet.protocol) {
                    Ipv4Packet.PROTOCOL_UDP -> udpSessions?.handlePacket(packet)
                    Ipv4Packet.PROTOCOL_TCP -> tcpSessions?.handlePacket(packet)
                    else -> {
                        // ICMP and others are dropped in MVP.
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
        executor?.shutdownNow()
        executor = null
        tunInterface = null
    }

    override fun updateConfig(config: TunnelConfig) {
        shaper.updateConfig(config)
    }
}

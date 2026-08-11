package com.darkmintis.network_simulator.stack

import com.darkmintis.network_simulator.packet.Ipv4Packet
import com.darkmintis.network_simulator.packet.PacketBuilder
import com.darkmintis.network_simulator.packet.TcpSegment
import com.darkmintis.network_simulator.shaper.TrafficDirection
import com.darkmintis.network_simulator.shaper.TrafficShaper
import java.io.InputStream
import java.io.OutputStream
import java.net.InetSocketAddress
import java.net.Socket
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.random.Random

/**
 * Userspace TCP proxy sessions. Terminates TCP on the TUN side and relays
 * through protected sockets to the real network.
 */
class TcpSessionManager(
    private val protector: SocketProtector,
    private val shaper: TrafficShaper,
    private val stats: TunnelStatsCollector,
    private val writer: (ByteArray) -> Unit,
    private val executor: ExecutorService,
) {
    private data class Key(
        val clientIp: Int,
        val clientPort: Int,
        val remoteIp: Int,
        val remotePort: Int,
    )

    private class Session(
        val key: Key,
        val socket: Socket,
        var clientNextSeq: Long,
        var serverSeq: Long,
        val closed: AtomicBoolean = AtomicBoolean(false),
    )

    private val sessions = ConcurrentHashMap<Key, Session>()

    fun handlePacket(packet: Ipv4Packet) {
        val segment = TcpSegment.parse(packet) ?: return
        val key = Key(
            clientIp = packet.sourceAddress,
            clientPort = segment.sourcePort,
            remoteIp = packet.destinationAddress,
            remotePort = segment.destinationPort,
        )

        if (segment.isRst) {
            sessions.remove(key)?.let { closeSession(it) }
            return
        }

        if (segment.isSyn && !segment.isAck) {
            openSession(key, segment, packet.totalLength)
            return
        }

        val session = sessions[key] ?: return
        if (!shaper.admit(TrafficDirection.UPLOAD, packet.totalLength)) {
            stats.onDrop()
            return
        }
        shaper.shape(TrafficDirection.UPLOAD, packet.totalLength)
        stats.onUpload(packet.totalLength)

        if (segment.payload.isNotEmpty()) {
            try {
                val out: OutputStream = session.socket.getOutputStream()
                out.write(segment.payload)
                out.flush()
                session.clientNextSeq =
                    (segment.sequenceNumber + segment.payload.size) and 0xFFFFFFFFL
                ackClient(session)
            } catch (_: Exception) {
                closeSession(session)
                sessions.remove(key)
            }
        }

        if (segment.isFin) {
            session.clientNextSeq = (segment.sequenceNumber + 1) and 0xFFFFFFFFL
            ackClient(session)
            runCatching { session.socket.shutdownOutput() }
        }
    }

    private fun openSession(key: Key, segment: TcpSegment, packetSize: Int) {
        if (!shaper.admit(TrafficDirection.UPLOAD, packetSize)) {
            stats.onDrop()
            return
        }
        shaper.shape(TrafficDirection.UPLOAD, packetSize)
        stats.onUpload(packetSize)

        executor.execute {
            try {
                val socket = Socket()
                protector.protect(socket)
                socket.tcpNoDelay = true
                socket.connect(
                    InetSocketAddress(
                        Ipv4Packet.addressToString(key.remoteIp),
                        key.remotePort,
                    ),
                    10_000,
                )

                val serverSeq = Random.nextLong(0, Int.MAX_VALUE.toLong())
                val session = Session(
                    key = key,
                    socket = socket,
                    clientNextSeq = (segment.sequenceNumber + 1) and 0xFFFFFFFFL,
                    serverSeq = serverSeq,
                )
                sessions[key] = session

                val synAck = PacketBuilder.buildTcp(
                    sourceIp = key.remoteIp,
                    destIp = key.clientIp,
                    sourcePort = key.remotePort,
                    destPort = key.clientPort,
                    seq = serverSeq,
                    ack = session.clientNextSeq,
                    flags = TcpSegment.FLAG_SYN or TcpSegment.FLAG_ACK,
                    window = 65535,
                    payload = ByteArray(0),
                )
                shapeAndWriteDownload(synAck)
                session.serverSeq = (serverSeq + 1) and 0xFFFFFFFFL

                pumpRemoteToTun(session)
            } catch (_: Exception) {
                // Connection failed; client will retry.
            }
        }
    }

    private fun pumpRemoteToTun(session: Session) {
        executor.execute {
            val buffer = ByteArray(32 * 1024)
            try {
                val input: InputStream = session.socket.getInputStream()
                while (!session.closed.get()) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    if (read == 0) continue
                    val payload = buffer.copyOf(read)
                    val packet = PacketBuilder.buildTcp(
                        sourceIp = session.key.remoteIp,
                        destIp = session.key.clientIp,
                        sourcePort = session.key.remotePort,
                        destPort = session.key.clientPort,
                        seq = session.serverSeq,
                        ack = session.clientNextSeq,
                        flags = TcpSegment.FLAG_ACK or TcpSegment.FLAG_PSH,
                        window = 65535,
                        payload = payload,
                    )
                    shapeAndWriteDownload(packet)
                    session.serverSeq = (session.serverSeq + read) and 0xFFFFFFFFL
                }

                val fin = PacketBuilder.buildTcp(
                    sourceIp = session.key.remoteIp,
                    destIp = session.key.clientIp,
                    sourcePort = session.key.remotePort,
                    destPort = session.key.clientPort,
                    seq = session.serverSeq,
                    ack = session.clientNextSeq,
                    flags = TcpSegment.FLAG_FIN or TcpSegment.FLAG_ACK,
                    window = 65535,
                    payload = ByteArray(0),
                )
                shapeAndWriteDownload(fin)
            } catch (_: Exception) {
                // Remote closed.
            } finally {
                sessions.remove(session.key, session)
                closeSession(session)
            }
        }
    }

    private fun ackClient(session: Session) {
        val ack = PacketBuilder.buildTcp(
            sourceIp = session.key.remoteIp,
            destIp = session.key.clientIp,
            sourcePort = session.key.remotePort,
            destPort = session.key.clientPort,
            seq = session.serverSeq,
            ack = session.clientNextSeq,
            flags = TcpSegment.FLAG_ACK,
            window = 65535,
            payload = ByteArray(0),
        )
        shapeAndWriteDownload(ack)
    }

    private fun shapeAndWriteDownload(packet: ByteArray) {
        if (!shaper.admit(TrafficDirection.DOWNLOAD, packet.size)) {
            stats.onDrop()
            return
        }
        shaper.shape(TrafficDirection.DOWNLOAD, packet.size)
        stats.onDownload(packet.size)
        writer(packet)
    }

    private fun closeSession(session: Session) {
        if (session.closed.compareAndSet(false, true)) {
            runCatching { session.socket.close() }
        }
    }

    fun closeAll() {
        sessions.values.forEach { closeSession(it) }
        sessions.clear()
    }
}

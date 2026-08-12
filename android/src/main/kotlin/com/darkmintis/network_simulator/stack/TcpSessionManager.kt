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
import java.util.concurrent.ConcurrentLinkedQueue
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

    private data class HandshakeState(
        val serverSeq: Long,
        var clientNextSeq: Long,
        val pendingSegments: ConcurrentLinkedQueue<TcpSegment> = ConcurrentLinkedQueue(),
    )

    private class Session(
        val key: Key,
        val socket: Socket,
        var clientNextSeq: Long,
        var serverSeq: Long,
        val closed: AtomicBoolean = AtomicBoolean(false),
    )

    private val sessions = ConcurrentHashMap<Key, Session>()
    private val handshakes = ConcurrentHashMap<Key, HandshakeState>()

    fun handlePacket(packet: Ipv4Packet) {
        val segment = TcpSegment.parse(packet) ?: return
        val key = Key(
            clientIp = packet.sourceAddress,
            clientPort = segment.sourcePort,
            remoteIp = packet.destinationAddress,
            remotePort = segment.destinationPort,
        )

        if (segment.isRst) {
            handshakes.remove(key)
            sessions.remove(key)?.let { closeSession(it) }
            return
        }

        if (segment.isSyn && !segment.isAck) {
            handleSyn(key, segment, packet.totalLength)
            return
        }

        val session = sessions[key]
        if (session == null) {
            handshakes[key]?.let { state ->
                if (segment.isAck && !segment.isSyn) {
                    state.clientNextSeq = maxSeq(
                        state.clientNextSeq,
                        (segment.sequenceNumber + segment.payload.size) and 0xFFFFFFFFL,
                    )
                }
                if (segment.payload.isNotEmpty() || segment.isFin) {
                    state.pendingSegments.add(segment)
                }
            }
            return
        }

        handleSessionPacket(session, segment, packet.totalLength)
    }

    private fun handleSessionPacket(session: Session, segment: TcpSegment, packetSize: Int) {
        val key = session.key
        if (!shaper.admit(TrafficDirection.UPLOAD, packetSize)) {
            stats.onDrop()
            return
        }
        shaper.shape(TrafficDirection.UPLOAD, packetSize)
        stats.onUpload(packetSize)

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

    private fun flushPending(session: Session, state: HandshakeState) {
        session.clientNextSeq = state.clientNextSeq
        while (true) {
            val segment = state.pendingSegments.poll() ?: break
            handleSessionPacket(session, segment, segment.payload.size + 40)
        }
    }

    private fun maxSeq(current: Long, next: Long): Long {
        val delta = (next - current) and 0xFFFFFFFFL
        return if (delta < 0x80000000L) next else current
    }

    private fun handleSyn(key: Key, segment: TcpSegment, packetSize: Int) {
        handshakes[key]?.let { state ->
            // SYN retransmit — reply with the same SYN-ACK.
            shapeUpload(packetSize)
            writeSynAck(key, state)
            return
        }
        if (sessions.containsKey(key)) return

        if (!shaper.admit(TrafficDirection.UPLOAD, packetSize)) {
            stats.onDrop()
            return
        }
        shapeUpload(packetSize)

        val serverSeq = Random.nextLong(1, 0x7FFFFFFF)
        val clientNextSeq = (segment.sequenceNumber + 1) and 0xFFFFFFFFL
        val state = HandshakeState(serverSeq = serverSeq, clientNextSeq = clientNextSeq)
        handshakes[key] = state

        // Reply immediately so the client does not flood SYN retransmits.
        writeSynAck(key, state)

        executor.execute {
            try {
                val socket = Socket()
                if (!protector.protect(socket)) {
                    throw IllegalStateException("Failed to protect TCP socket from VPN loop")
                }
                socket.tcpNoDelay = true
                socket.connect(
                    InetSocketAddress(
                        Ipv4Packet.addressToString(key.remoteIp),
                        key.remotePort,
                    ),
                    15_000,
                )

                val session = Session(
                    key = key,
                    socket = socket,
                    clientNextSeq = clientNextSeq,
                    serverSeq = (serverSeq + 1) and 0xFFFFFFFFL,
                )
                val handshakeState = handshakes[key]
                sessions[key] = session
                handshakes.remove(key)
                if (handshakeState != null) {
                    flushPending(session, handshakeState)
                }
                pumpRemoteToTun(session)
            } catch (_: Exception) {
                handshakes.remove(key)
                writeRst(key, state)
            }
        }
    }

    private fun writeSynAck(key: Key, state: HandshakeState) {
        val packet = PacketBuilder.buildTcp(
            sourceIp = key.remoteIp,
            destIp = key.clientIp,
            sourcePort = key.remotePort,
            destPort = key.clientPort,
            seq = state.serverSeq,
            ack = state.clientNextSeq,
            flags = TcpSegment.FLAG_SYN or TcpSegment.FLAG_ACK,
            window = 65535,
            payload = ByteArray(0),
            mss = DEFAULT_MSS,
        )
        shapeAndWriteDownload(packet)
    }

    private fun writeRst(key: Key, state: HandshakeState) {
        val packet = PacketBuilder.buildTcp(
            sourceIp = key.remoteIp,
            destIp = key.clientIp,
            sourcePort = key.remotePort,
            destPort = key.clientPort,
            seq = (state.serverSeq + 1) and 0xFFFFFFFFL,
            ack = state.clientNextSeq,
            flags = TcpSegment.FLAG_RST or TcpSegment.FLAG_ACK,
            window = 0,
            payload = ByteArray(0),
        )
        shapeAndWriteDownload(packet)
    }

    private fun shapeUpload(packetSize: Int) {
        shaper.shape(TrafficDirection.UPLOAD, packetSize)
        stats.onUpload(packetSize)
    }

    private fun pumpRemoteToTun(session: Session) {
        executor.execute {
            val buffer = ByteArray(16 * 1024)
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
        handshakes.clear()
        sessions.values.forEach { closeSession(it) }
        sessions.clear()
    }

    companion object {
        private const val DEFAULT_MSS = 1400
    }
}

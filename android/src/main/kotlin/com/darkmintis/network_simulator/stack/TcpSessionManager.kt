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
 *
 * Packet loss is not applied to TCP download bytes (opaque drops would create
 * unrecoverable sequence holes). Latency and bandwidth still apply.
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
        val lock: Any = Any(),
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
                    val advance = segment.payload.size + if (segment.isFin) 1 else 0
                    state.clientNextSeq = maxSeq(
                        state.clientNextSeq,
                        (segment.sequenceNumber + advance) and 0xFFFFFFFFL,
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

        synchronized(session.lock) {
            if (session.closed.get()) return

            if (segment.payload.isNotEmpty()) {
                val expected = session.clientNextSeq
                val seq = segment.sequenceNumber and 0xFFFFFFFFL
                val delta = (seq - expected) and 0xFFFFFFFFL
                when {
                    delta == 0L -> {
                        try {
                            val out: OutputStream = session.socket.getOutputStream()
                            out.write(segment.payload)
                            out.flush()
                            session.clientNextSeq =
                                (seq + segment.payload.size) and 0xFFFFFFFFL
                            ackClientLocked(session)
                        } catch (_: Exception) {
                            closeSession(session)
                            sessions.remove(key)
                            return
                        }
                    }
                    delta > 0x80000000L -> {
                        ackClientLocked(session)
                    }
                    else -> {
                        ackClientLocked(session)
                    }
                }
            }

            if (segment.isFin) {
                val finSeq = if (segment.payload.isNotEmpty()) {
                    (segment.sequenceNumber + segment.payload.size) and 0xFFFFFFFFL
                } else {
                    segment.sequenceNumber and 0xFFFFFFFFL
                }
                if (finSeq == session.clientNextSeq) {
                    session.clientNextSeq = (finSeq + 1) and 0xFFFFFFFFL
                    ackClientLocked(session)
                    runCatching { session.socket.shutdownOutput() }
                }
            }
        }
    }

    private fun flushPending(session: Session, state: HandshakeState) {
        synchronized(session.lock) {
            session.clientNextSeq = state.clientNextSeq
        }
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
        writeSynAck(key, state)

        executor.execute {
            try {
                val socket = Socket()
                if (!protector.protect(socket)) {
                    throw IllegalStateException("Failed to protect TCP socket from VPN loop")
                }
                socket.tcpNoDelay = true
                socket.soTimeout = 0
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
        shapeTcpDownload(packet)
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
        shapeTcpDownload(packet)
    }

    private fun shapeUpload(packetSize: Int) {
        shaper.shape(TrafficDirection.UPLOAD, packetSize)
        stats.onUpload(packetSize)
    }

    private fun pumpRemoteToTun(session: Session) {
        executor.execute {
            val buffer = ByteArray(DEFAULT_MSS)
            try {
                val input: InputStream = session.socket.getInputStream()
                while (!session.closed.get()) {
                    val read = input.read(buffer)
                    if (read < 0) break
                    if (read == 0) continue
                    var offset = 0
                    while (offset < read && !session.closed.get()) {
                        val chunkLen = minOf(DEFAULT_MSS, read - offset)
                        val payload = buffer.copyOfRange(offset, offset + chunkLen)
                        val seq: Long
                        val ack: Long
                        synchronized(session.lock) {
                            seq = session.serverSeq
                            ack = session.clientNextSeq
                        }
                        val packet = PacketBuilder.buildTcp(
                            sourceIp = session.key.remoteIp,
                            destIp = session.key.clientIp,
                            sourcePort = session.key.remotePort,
                            destPort = session.key.clientPort,
                            seq = seq,
                            ack = ack,
                            flags = TcpSegment.FLAG_ACK or TcpSegment.FLAG_PSH,
                            window = 65535,
                            payload = payload,
                        )
                        shapeTcpDownload(packet)
                        synchronized(session.lock) {
                            session.serverSeq = (session.serverSeq + chunkLen) and 0xFFFFFFFFL
                        }
                        offset += chunkLen
                    }
                }

                val seq: Long
                val ack: Long
                synchronized(session.lock) {
                    seq = session.serverSeq
                    ack = session.clientNextSeq
                }
                val fin = PacketBuilder.buildTcp(
                    sourceIp = session.key.remoteIp,
                    destIp = session.key.clientIp,
                    sourcePort = session.key.remotePort,
                    destPort = session.key.clientPort,
                    seq = seq,
                    ack = ack,
                    flags = TcpSegment.FLAG_FIN or TcpSegment.FLAG_ACK,
                    window = 65535,
                    payload = ByteArray(0),
                )
                shapeTcpDownload(fin)
                synchronized(session.lock) {
                    session.serverSeq = (session.serverSeq + 1) and 0xFFFFFFFFL
                }
            } catch (_: Exception) {
                // Remote closed.
            } finally {
                sessions.remove(session.key, session)
                closeSession(session)
            }
        }
    }

    private fun ackClientLocked(session: Session) {
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
        shapeTcpDownload(ack)
    }

    private fun shapeTcpDownload(packet: ByteArray) {
        // Delay + bandwidth only; loss would create unrecoverable holes.
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

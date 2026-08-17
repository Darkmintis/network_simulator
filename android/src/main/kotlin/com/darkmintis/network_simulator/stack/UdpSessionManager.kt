package com.darkmintis.network_simulator.stack

import com.darkmintis.network_simulator.packet.Ipv4Packet
import com.darkmintis.network_simulator.packet.PacketBuilder
import com.darkmintis.network_simulator.packet.UdpSegment
import com.darkmintis.network_simulator.shaper.TrafficDirection
import com.darkmintis.network_simulator.shaper.TrafficShaper
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * Userspace UDP NAT sessions over protected datagram sockets.
 */
class UdpSessionManager(
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

    private data class UdpSession(
        val socket: DatagramSocket,
        @Volatile var lastActiveMillis: Long = System.currentTimeMillis(),
    )

    private val sessions = ConcurrentHashMap<Key, UdpSession>()
    private val janitor = Executors.newSingleThreadScheduledExecutor()

    init {
        janitor.scheduleAtFixedRate({ evictIdle() }, 30, 30, TimeUnit.SECONDS)
    }

    fun handlePacket(packet: Ipv4Packet) {
        val segment = UdpSegment.parse(packet) ?: return
        val key = Key(
            clientIp = packet.sourceAddress,
            clientPort = segment.sourcePort,
            remoteIp = packet.destinationAddress,
            remotePort = segment.destinationPort,
        )

        if (!shaper.admit(TrafficDirection.UPLOAD, packet.totalLength)) {
            stats.onDrop()
            return
        }
        shaper.shape(TrafficDirection.UPLOAD, packet.totalLength)
        stats.onUpload(packet.totalLength)

        if (sessions.size >= MAX_SESSIONS && !sessions.containsKey(key)) {
            stats.onDrop()
            return
        }

        val session = try {
            sessions.getOrPut(key) { createSession(key) }
        } catch (_: Exception) {
            stats.onDrop()
            return
        }
        session.lastActiveMillis = System.currentTimeMillis()

        val address = InetAddress.getByName(Ipv4Packet.addressToString(packet.destinationAddress))
        val datagram = DatagramPacket(
            segment.payload,
            segment.payload.size,
            address,
            segment.destinationPort,
        )
        try {
            session.socket.send(datagram)
        } catch (_: Exception) {
            sessions.remove(key, session)
            runCatching { session.socket.close() }
            stats.onDrop()
        }
    }

    private fun createSession(key: Key): UdpSession {
        val socket = DatagramSocket()
        if (!protector.protect(socket)) {
            throw IllegalStateException("Failed to protect UDP socket from VPN loop")
        }
        val session = UdpSession(socket)
        executor.execute {
            val buffer = ByteArray(65535)
            try {
                while (!socket.isClosed) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    socket.receive(packet)
                    session.lastActiveMillis = System.currentTimeMillis()
                    val payload =
                        packet.data.copyOfRange(packet.offset, packet.offset + packet.length)
                    val response = PacketBuilder.buildUdp(
                        sourceIp = key.remoteIp,
                        destIp = key.clientIp,
                        sourcePort = key.remotePort,
                        destPort = key.clientPort,
                        payload = payload,
                    )
                    if (!shaper.admit(TrafficDirection.DOWNLOAD, response.size)) {
                        stats.onDrop()
                        continue
                    }
                    shaper.shape(TrafficDirection.DOWNLOAD, response.size)
                    stats.onDownload(response.size)
                    writer(response)
                }
            } catch (_: Exception) {
                // Socket closed or network error ends the receive loop.
            } finally {
                sessions.remove(key, session)
                runCatching { socket.close() }
            }
        }
        return session
    }

    private fun evictIdle() {
        val cutoff = System.currentTimeMillis() - IDLE_TIMEOUT_MS
        sessions.entries.removeIf { (_, session) ->
            if (session.lastActiveMillis < cutoff) {
                runCatching { session.socket.close() }
                true
            } else {
                false
            }
        }
    }

    fun closeAll() {
        janitor.shutdownNow()
        sessions.values.forEach { runCatching { it.socket.close() } }
        sessions.clear()
    }

    companion object {
        private const val IDLE_TIMEOUT_MS = 60_000L
        private const val MAX_SESSIONS = 256
    }
}

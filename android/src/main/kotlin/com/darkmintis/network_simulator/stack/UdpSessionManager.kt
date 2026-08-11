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

    private val sessions = ConcurrentHashMap<Key, DatagramSocket>()

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

        val socket = sessions.getOrPut(key) { createSocket(key) }

        val address = InetAddress.getByName(Ipv4Packet.addressToString(packet.destinationAddress))
        val datagram = DatagramPacket(
            segment.payload,
            segment.payload.size,
            address,
            segment.destinationPort,
        )
        socket.send(datagram)
    }

    private fun createSocket(key: Key): DatagramSocket {
        val socket = DatagramSocket()
        protector.protect(socket)
        executor.execute {
            val buffer = ByteArray(65535)
            try {
                while (!socket.isClosed) {
                    val packet = DatagramPacket(buffer, buffer.size)
                    socket.receive(packet)
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
                sessions.remove(key, socket)
                runCatching { socket.close() }
            }
        }
        return socket
    }

    fun closeAll() {
        sessions.values.forEach { runCatching { it.close() } }
        sessions.clear()
    }
}

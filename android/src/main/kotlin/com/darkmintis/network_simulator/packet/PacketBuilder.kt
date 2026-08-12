package com.darkmintis.network_simulator.packet

/**
 * Builds IPv4 packets to inject back into the TUN interface.
 */
object PacketBuilder {
    fun buildUdp(
        sourceIp: Int,
        destIp: Int,
        sourcePort: Int,
        destPort: Int,
        payload: ByteArray,
    ): ByteArray {
        val udpLength = 8 + payload.size
        val totalLength = 20 + udpLength
        val packet = ByteArray(totalLength)

        packet[0] = 0x45
        packet[1] = 0
        packet[2] = ((totalLength ushr 8) and 0xFF).toByte()
        packet[3] = (totalLength and 0xFF).toByte()
        packet[6] = 0x40
        packet[8] = 64
        packet[9] = Ipv4Packet.PROTOCOL_UDP.toByte()
        Ipv4Packet.writeInt(packet, 12, sourceIp)
        Ipv4Packet.writeInt(packet, 16, destIp)
        writeChecksum(packet, 10, Ipv4Packet.checksum(packet, 0, 20))

        val udpOffset = 20
        packet[udpOffset] = ((sourcePort ushr 8) and 0xFF).toByte()
        packet[udpOffset + 1] = (sourcePort and 0xFF).toByte()
        packet[udpOffset + 2] = ((destPort ushr 8) and 0xFF).toByte()
        packet[udpOffset + 3] = (destPort and 0xFF).toByte()
        packet[udpOffset + 4] = ((udpLength ushr 8) and 0xFF).toByte()
        packet[udpOffset + 5] = (udpLength and 0xFF).toByte()
        // IPv4 UDP checksum may be zero (no checksum).
        packet[udpOffset + 6] = 0
        packet[udpOffset + 7] = 0
        System.arraycopy(payload, 0, packet, udpOffset + 8, payload.size)
        return packet
    }

    fun buildTcp(
        sourceIp: Int,
        destIp: Int,
        sourcePort: Int,
        destPort: Int,
        seq: Long,
        ack: Long,
        flags: Int,
        window: Int,
        payload: ByteArray,
        mss: Int? = null,
    ): ByteArray {
        val options = buildTcpOptions(mss)
        val optionsLength = options.size
        val dataOffset = 20 + optionsLength
        val tcpLength = dataOffset + payload.size
        val totalLength = 20 + tcpLength
        val packet = ByteArray(totalLength)

        packet[0] = 0x45
        packet[2] = ((totalLength ushr 8) and 0xFF).toByte()
        packet[3] = (totalLength and 0xFF).toByte()
        packet[6] = 0x40
        packet[8] = 64
        packet[9] = Ipv4Packet.PROTOCOL_TCP.toByte()
        Ipv4Packet.writeInt(packet, 12, sourceIp)
        Ipv4Packet.writeInt(packet, 16, destIp)
        writeChecksum(packet, 10, Ipv4Packet.checksum(packet, 0, 20))

        val tcpOffset = 20
        packet[tcpOffset] = ((sourcePort ushr 8) and 0xFF).toByte()
        packet[tcpOffset + 1] = (sourcePort and 0xFF).toByte()
        packet[tcpOffset + 2] = ((destPort ushr 8) and 0xFF).toByte()
        packet[tcpOffset + 3] = (destPort and 0xFF).toByte()
        writeUInt32(packet, tcpOffset + 4, seq)
        writeUInt32(packet, tcpOffset + 8, ack)
        packet[tcpOffset + 12] = ((dataOffset / 4) shl 4).toByte()
        packet[tcpOffset + 13] = (flags and 0x3F).toByte()
        packet[tcpOffset + 14] = ((window ushr 8) and 0xFF).toByte()
        packet[tcpOffset + 15] = (window and 0xFF).toByte()
        if (optionsLength > 0) {
            System.arraycopy(options, 0, packet, tcpOffset + 20, optionsLength)
        }
        if (payload.isNotEmpty()) {
            System.arraycopy(payload, 0, packet, tcpOffset + dataOffset, payload.size)
        }

        val tcpChecksum = transportChecksum(
            packet,
            sourceIp,
            destIp,
            Ipv4Packet.PROTOCOL_TCP,
            tcpOffset,
            tcpLength,
        )
        packet[tcpOffset + 16] = ((tcpChecksum ushr 8) and 0xFF).toByte()
        packet[tcpOffset + 17] = (tcpChecksum and 0xFF).toByte()
        return packet
    }

    private fun writeUInt32(buffer: ByteArray, offset: Int, value: Long) {
        buffer[offset] = ((value ushr 24) and 0xFF).toByte()
        buffer[offset + 1] = ((value ushr 16) and 0xFF).toByte()
        buffer[offset + 2] = ((value ushr 8) and 0xFF).toByte()
        buffer[offset + 3] = (value and 0xFF).toByte()
    }

    private fun writeChecksum(buffer: ByteArray, offset: Int, checksum: Int) {
        buffer[offset] = ((checksum ushr 8) and 0xFF).toByte()
        buffer[offset + 1] = (checksum and 0xFF).toByte()
    }

    private fun transportChecksum(
        packet: ByteArray,
        sourceIp: Int,
        destIp: Int,
        protocol: Int,
        offset: Int,
        length: Int,
    ): Int {
        var sum = 0L
        sum += (sourceIp ushr 16) and 0xFFFF
        sum += sourceIp and 0xFFFF
        sum += (destIp ushr 16) and 0xFFFF
        sum += destIp and 0xFFFF
        sum += protocol
        sum += length

        var i = offset
        val end = offset + length
        while (i + 1 < end) {
            if (i == offset + 6 && protocol == Ipv4Packet.PROTOCOL_UDP) {
                // skip checksum field while computing
            }
            if (!(protocol == Ipv4Packet.PROTOCOL_TCP && i == offset + 16) &&
                !(protocol == Ipv4Packet.PROTOCOL_UDP && i == offset + 6)
            ) {
                sum += ((packet[i].toInt() and 0xFF) shl 8) or (packet[i + 1].toInt() and 0xFF)
            }
            i += 2
        }
        if (i < end) {
            sum += (packet[i].toInt() and 0xFF) shl 8
        }
        while (sum ushr 16 != 0L) {
            sum = (sum and 0xFFFF) + (sum ushr 16)
        }
        val result = (sum.inv() and 0xFFFF).toInt()
        return if (result == 0 && protocol == Ipv4Packet.PROTOCOL_UDP) 0xFFFF else result
    }

    private fun buildTcpOptions(mss: Int?): ByteArray {
        if (mss == null) return ByteArray(0)
        return byteArrayOf(
            0x02,
            0x04,
            ((mss shr 8) and 0xFF).toByte(),
            (mss and 0xFF).toByte(),
        )
    }
}

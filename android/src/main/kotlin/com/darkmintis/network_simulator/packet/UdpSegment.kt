package com.darkmintis.network_simulator.packet

data class UdpSegment(
    val sourcePort: Int,
    val destinationPort: Int,
    val payload: ByteArray,
) {
    companion object {
        fun parse(packet: Ipv4Packet): UdpSegment? {
            if (packet.protocol != Ipv4Packet.PROTOCOL_UDP) return null
            if (packet.payloadLength < 8) return null
            val data = packet.raw
            val offset = packet.payloadOffset
            val sourcePort = ((data[offset].toInt() and 0xFF) shl 8) or (data[offset + 1].toInt() and 0xFF)
            val destPort = ((data[offset + 2].toInt() and 0xFF) shl 8) or (data[offset + 3].toInt() and 0xFF)
            val length = ((data[offset + 4].toInt() and 0xFF) shl 8) or (data[offset + 5].toInt() and 0xFF)
            val payloadLength = (length - 8).coerceAtLeast(0)
            val payload = data.copyOfRange(offset + 8, offset + 8 + payloadLength)
            return UdpSegment(sourcePort, destPort, payload)
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is UdpSegment) return false
        return sourcePort == other.sourcePort &&
            destinationPort == other.destinationPort &&
            payload.contentEquals(other.payload)
    }

    override fun hashCode(): Int {
        var result = sourcePort
        result = 31 * result + destinationPort
        result = 31 * result + payload.contentHashCode()
        return result
    }
}

package com.darkmintis.network_simulator.packet

data class TcpSegment(
    val sourcePort: Int,
    val destinationPort: Int,
    val sequenceNumber: Long,
    val acknowledgmentNumber: Long,
    val dataOffset: Int,
    val flags: Int,
    val window: Int,
    val payload: ByteArray,
) {
    val isSyn: Boolean get() = flags and FLAG_SYN != 0
    val isAck: Boolean get() = flags and FLAG_ACK != 0
    val isFin: Boolean get() = flags and FLAG_FIN != 0
    val isRst: Boolean get() = flags and FLAG_RST != 0
    val isPsh: Boolean get() = flags and FLAG_PSH != 0

    companion object {
        const val FLAG_FIN = 0x01
        const val FLAG_SYN = 0x02
        const val FLAG_RST = 0x04
        const val FLAG_PSH = 0x08
        const val FLAG_ACK = 0x10

        fun parse(packet: Ipv4Packet): TcpSegment? {
            if (packet.protocol != Ipv4Packet.PROTOCOL_TCP) return null
            if (packet.payloadLength < 20) return null
            val data = packet.raw
            val offset = packet.payloadOffset
            val sourcePort = ((data[offset].toInt() and 0xFF) shl 8) or (data[offset + 1].toInt() and 0xFF)
            val destPort = ((data[offset + 2].toInt() and 0xFF) shl 8) or (data[offset + 3].toInt() and 0xFF)
            val seq = readUInt32(data, offset + 4)
            val ack = readUInt32(data, offset + 8)
            val dataOffset = ((data[offset + 12].toInt() ushr 4) and 0x0F) * 4
            if (dataOffset < 20 || packet.payloadLength < dataOffset) return null
            val flags = data[offset + 13].toInt() and 0x3F
            val window = ((data[offset + 14].toInt() and 0xFF) shl 8) or (data[offset + 15].toInt() and 0xFF)
            val payload = data.copyOfRange(offset + dataOffset, offset + packet.payloadLength)
            return TcpSegment(
                sourcePort = sourcePort,
                destinationPort = destPort,
                sequenceNumber = seq,
                acknowledgmentNumber = ack,
                dataOffset = dataOffset,
                flags = flags,
                window = window,
                payload = payload,
            )
        }

        private fun readUInt32(buffer: ByteArray, offset: Int): Long {
            return ((buffer[offset].toLong() and 0xFF) shl 24) or
                ((buffer[offset + 1].toLong() and 0xFF) shl 16) or
                ((buffer[offset + 2].toLong() and 0xFF) shl 8) or
                (buffer[offset + 3].toLong() and 0xFF)
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is TcpSegment) return false
        return sourcePort == other.sourcePort &&
            destinationPort == other.destinationPort &&
            sequenceNumber == other.sequenceNumber &&
            acknowledgmentNumber == other.acknowledgmentNumber &&
            flags == other.flags &&
            payload.contentEquals(other.payload)
    }

    override fun hashCode(): Int {
        var result = sourcePort
        result = 31 * result + destinationPort
        result = 31 * result + sequenceNumber.hashCode()
        result = 31 * result + acknowledgmentNumber.hashCode()
        result = 31 * result + flags
        result = 31 * result + payload.contentHashCode()
        return result
    }
}

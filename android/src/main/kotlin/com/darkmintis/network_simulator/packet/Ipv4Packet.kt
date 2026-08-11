package com.darkmintis.network_simulator.packet

/**
 * Parsed IPv4 header + payload view over a raw TUN packet buffer.
 */
data class Ipv4Packet(
    val raw: ByteArray,
    val headerLength: Int,
    val protocol: Int,
    val sourceAddress: Int,
    val destinationAddress: Int,
    val totalLength: Int,
) {
    val payloadOffset: Int get() = headerLength
    val payloadLength: Int get() = totalLength - headerLength

    fun payload(): ByteArray =
        raw.copyOfRange(payloadOffset, payloadOffset + payloadLength)

    companion object {
        const val PROTOCOL_TCP = 6
        const val PROTOCOL_UDP = 17
        const val PROTOCOL_ICMP = 1

        fun parse(raw: ByteArray): Ipv4Packet? {
            if (raw.size < 20) return null
            val version = (raw[0].toInt() ushr 4) and 0x0F
            if (version != 4) return null
            val headerLength = (raw[0].toInt() and 0x0F) * 4
            if (headerLength < 20 || raw.size < headerLength) return null
            val totalLength = ((raw[2].toInt() and 0xFF) shl 8) or (raw[3].toInt() and 0xFF)
            if (totalLength > raw.size || totalLength < headerLength) return null
            val protocol = raw[9].toInt() and 0xFF
            val source = readInt(raw, 12)
            val dest = readInt(raw, 16)
            return Ipv4Packet(
                raw = raw.copyOf(totalLength),
                headerLength = headerLength,
                protocol = protocol,
                sourceAddress = source,
                destinationAddress = dest,
                totalLength = totalLength,
            )
        }

        fun readInt(buffer: ByteArray, offset: Int): Int {
            return ((buffer[offset].toInt() and 0xFF) shl 24) or
                ((buffer[offset + 1].toInt() and 0xFF) shl 16) or
                ((buffer[offset + 2].toInt() and 0xFF) shl 8) or
                (buffer[offset + 3].toInt() and 0xFF)
        }

        fun writeInt(buffer: ByteArray, offset: Int, value: Int) {
            buffer[offset] = ((value ushr 24) and 0xFF).toByte()
            buffer[offset + 1] = ((value ushr 16) and 0xFF).toByte()
            buffer[offset + 2] = ((value ushr 8) and 0xFF).toByte()
            buffer[offset + 3] = (value and 0xFF).toByte()
        }

        fun addressToString(address: Int): String {
            return "${(address ushr 24) and 0xFF}." +
                "${(address ushr 16) and 0xFF}." +
                "${(address ushr 8) and 0xFF}." +
                "${address and 0xFF}"
        }

        fun checksum(buffer: ByteArray, offset: Int, length: Int): Int {
            var sum = 0L
            var i = offset
            val end = offset + length
            while (i + 1 < end) {
                sum += ((buffer[i].toInt() and 0xFF) shl 8) or (buffer[i + 1].toInt() and 0xFF)
                i += 2
            }
            if (i < end) {
                sum += (buffer[i].toInt() and 0xFF) shl 8
            }
            while (sum ushr 16 != 0L) {
                sum = (sum and 0xFFFF) + (sum ushr 16)
            }
            return (sum.inv() and 0xFFFF).toInt()
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Ipv4Packet) return false
        return raw.contentEquals(other.raw)
    }

    override fun hashCode(): Int = raw.contentHashCode()
}

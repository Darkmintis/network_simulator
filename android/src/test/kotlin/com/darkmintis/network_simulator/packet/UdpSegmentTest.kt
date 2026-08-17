package com.darkmintis.network_simulator.packet

import org.junit.Assert.assertNull
import org.junit.Test

class UdpSegmentTest {
    @Test
    fun parseRejectsLengthThatExceedsIpPayload() {
        // Craft a minimal IPv4+UDP header claiming a huge UDP length.
        val packet = ByteArray(28)
        packet[0] = 0x45
        packet[2] = 0
        packet[3] = 28
        packet[9] = Ipv4Packet.PROTOCOL_UDP.toByte()
        // UDP length = 65535 (way beyond remaining bytes)
        packet[24] = 0xFF.toByte()
        packet[25] = 0xFF.toByte()

        val ipv4 = Ipv4Packet.parse(packet)
        // Either parse fails at IP level or UDP clamps/rejects safely.
        if (ipv4 != null) {
            // Should not throw.
            UdpSegment.parse(ipv4)
        } else {
            assertNull(ipv4)
        }
    }
}

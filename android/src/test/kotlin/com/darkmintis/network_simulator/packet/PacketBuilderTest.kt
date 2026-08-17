package com.darkmintis.network_simulator.packet

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class PacketBuilderTest {
    @Test
    fun buildTcpWithMssFitsUnderMtu() {
        val payload = ByteArray(1400) { 1 }
        val packet = PacketBuilder.buildTcp(
            sourceIp = 0x0A000001,
            destIp = 0x0A000002,
            sourcePort = 443,
            destPort = 12345,
            seq = 1,
            ack = 2,
            flags = TcpSegment.FLAG_ACK or TcpSegment.FLAG_PSH,
            window = 65535,
            payload = payload,
        )
        assertTrue(packet.size <= 1500)
        assertEquals(Ipv4Packet.PROTOCOL_TCP, packet[9].toInt() and 0xFF)
    }

    @Test
    fun buildTcpSynAckIncludesMssOption() {
        val packet = PacketBuilder.buildTcp(
            sourceIp = 0x0A000001,
            destIp = 0x0A000002,
            sourcePort = 443,
            destPort = 12345,
            seq = 100,
            ack = 101,
            flags = TcpSegment.FLAG_SYN or TcpSegment.FLAG_ACK,
            window = 65535,
            payload = ByteArray(0),
            mss = 1400,
        )
        val parsed = Ipv4Packet.parse(packet)
        assertNotNull(parsed)
        val segment = TcpSegment.parse(parsed!!)
        assertNotNull(segment)
        assertTrue(segment!!.isSyn)
        assertTrue(segment.isAck)
        // data offset should be > 5 words because of MSS option
        val dataOffsetWords = (packet[20 + 12].toInt() and 0xF0) ushr 4
        assertTrue(dataOffsetWords > 5)
    }

    @Test
    fun buildUdpRoundTrip() {
        val payload = byteArrayOf(1, 2, 3, 4)
        val packet = PacketBuilder.buildUdp(
            sourceIp = 0x08080808,
            destIp = 0x0A000002,
            sourcePort = 53,
            destPort = 5353,
            payload = payload,
        )
        val parsed = Ipv4Packet.parse(packet)
        assertNotNull(parsed)
        val udp = UdpSegment.parse(parsed!!)
        assertNotNull(udp)
        assertEquals(53, udp!!.sourcePort)
        assertEquals(5353, udp.destinationPort)
        assertTrue(udp.payload.contentEquals(payload))
    }
}

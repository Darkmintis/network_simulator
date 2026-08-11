package com.darkmintis.network_simulator.stack

import android.os.ParcelFileDescriptor
import com.darkmintis.network_simulator.config.TunnelConfig
import java.net.DatagramSocket
import java.net.Socket

/**
 * Processes packets from the TUN file descriptor.
 */
interface PacketPipeline {
    fun start(tunInterface: ParcelFileDescriptor)

    fun stop()

    fun updateConfig(config: TunnelConfig)
}

interface SocketProtector {
    fun protect(socket: DatagramSocket): Boolean

    fun protect(socket: Socket): Boolean
}

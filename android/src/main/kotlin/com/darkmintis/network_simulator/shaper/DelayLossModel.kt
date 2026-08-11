package com.darkmintis.network_simulator.shaper

import java.util.Random
import kotlin.math.max

/**
 * Applies latency, jitter, and Bernoulli packet loss.
 */
class DelayLossModel(
    private val random: Random = Random(),
) {
    @Volatile
    var latencyMs: Double = 0.0

    @Volatile
    var jitterMs: Double = 0.0

    @Volatile
    var packetLoss: Double = 0.0

    @Volatile
    var offline: Boolean = false

    fun shouldDrop(): Boolean {
        if (offline) return true
        if (packetLoss <= 0) return false
        return random.nextDouble() < packetLoss.coerceIn(0.0, 1.0)
    }

    fun nextDelayMillis(): Long {
        if (offline) return 0L
        if (latencyMs <= 0 && jitterMs <= 0) return 0L
        val jitter = if (jitterMs <= 0) {
            0.0
        } else {
            (random.nextDouble() * 2 - 1) * jitterMs
        }
        return max(0.0, latencyMs + jitter).toLong()
    }
}

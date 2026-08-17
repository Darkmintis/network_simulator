package com.darkmintis.network_simulator.shaper

import com.darkmintis.network_simulator.config.TunnelConfig

/**
 * Contract for applying real network conditions to packet/byte flows.
 */
interface TrafficShaper {
    fun updateConfig(config: TunnelConfig)

    /** Returns false when the unit must be dropped (loss/offline). */
    fun admit(direction: TrafficDirection, sizeBytes: Int): Boolean

    /** Blocks until bandwidth + latency/jitter allow transmission. */
    fun shape(direction: TrafficDirection, sizeBytes: Int)
}

class NetworkConditionShaper : TrafficShaper {
    private val delayLoss = DelayLossModel()
    private val uploadBucket = TokenBucket(Double.POSITIVE_INFINITY)
    private val downloadBucket = TokenBucket(Double.POSITIVE_INFINITY)

    @Volatile
    private var config: TunnelConfig = TunnelConfig()

    override fun updateConfig(config: TunnelConfig) {
        this.config = config
        delayLoss.latencyMs = config.latencyMs
        delayLoss.jitterMs = config.jitterMs
        delayLoss.packetLoss = config.packetLoss
        delayLoss.offline = config.isOffline
        uploadBucket.updateRate(mbpsToBytesPerSecond(config.uploadMbps))
        downloadBucket.updateRate(mbpsToBytesPerSecond(config.downloadMbps))
    }

    override fun admit(direction: TrafficDirection, sizeBytes: Int): Boolean {
        if (config.isOffline) return false
        return !delayLoss.shouldDrop()
    }

    override fun shape(direction: TrafficDirection, sizeBytes: Int) {
        val bucket = if (direction == TrafficDirection.UPLOAD) uploadBucket else downloadBucket
        while (!bucket.tryConsume(sizeBytes)) {
            val wait = bucket.waitTimeMillis(sizeBytes)
            interruptibleSleep(wait.coerceAtMost(50))
        }
        val delay = delayLoss.nextDelayMillis()
        if (delay > 0) {
            interruptibleSleep(delay)
        }
    }

    private fun interruptibleSleep(millis: Long) {
        try {
            Thread.sleep(millis)
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    private fun mbpsToBytesPerSecond(mbps: Double): Double {
        if (!mbps.isFinite()) return Double.POSITIVE_INFINITY
        if (mbps <= 0) return 0.0
        return mbps * 1024.0 * 1024.0 / 8.0
    }
}

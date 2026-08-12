package com.darkmintis.network_simulator.shaper

/**
 * Token-bucket rate limiter used for download/upload bandwidth caps.
 */
class TokenBucket(
    private var rateBytesPerSecond: Double,
    private var capacityBytes: Double = rateBytesPerSecond,
) {
    private var tokens: Double = capacityBytes
    private var lastRefillNanos: Long = System.nanoTime()

    @Synchronized
    fun updateRate(bytesPerSecond: Double) {
        rateBytesPerSecond = bytesPerSecond.coerceAtLeast(0.0)
        capacityBytes = if (rateBytesPerSecond.isFinite() && rateBytesPerSecond > 0) {
            rateBytesPerSecond.coerceAtLeast(1500.0)
        } else {
            Double.POSITIVE_INFINITY
        }
        tokens = capacityBytes
        lastRefillNanos = System.nanoTime()
    }

    @Synchronized
    fun tryConsume(bytes: Int): Boolean {
        if (!rateBytesPerSecond.isFinite()) {
            return true
        }
        if (rateBytesPerSecond <= 0) {
            return false
        }
        refill()
        if (tokens >= bytes) {
            tokens -= bytes
            return true
        }
        return false
    }

    @Synchronized
    fun waitTimeMillis(bytes: Int): Long {
        if (!rateBytesPerSecond.isFinite() || rateBytesPerSecond <= 0) {
            return 50L
        }
        refill()
        if (tokens >= bytes) return 0L
        val missing = bytes - tokens
        return ((missing / rateBytesPerSecond) * 1000.0).toLong().coerceAtLeast(1L)
    }

    private fun refill() {
        val now = System.nanoTime()
        val elapsedSec = (now - lastRefillNanos) / 1_000_000_000.0
        lastRefillNanos = now
        tokens = (tokens + elapsedSec * rateBytesPerSecond).coerceAtMost(capacityBytes)
    }
}

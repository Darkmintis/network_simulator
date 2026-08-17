package com.darkmintis.network_simulator.shaper

/**
 * Token-bucket rate limiter used for download/upload bandwidth caps.
 *
 * Capacity is large enough to admit a full TCP MSS so shaped relays never
 * busy-wait forever on a single segment larger than the bucket.
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
            rateBytesPerSecond.coerceAtLeast(DEFAULT_CAPACITY_BYTES)
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
        val needed = bytes.toDouble().coerceAtMost(capacityBytes)
        if (tokens >= needed) {
            tokens -= needed
            return true
        }
        return false
    }

    @Synchronized
    fun waitTimeMillis(bytes: Int): Long {
        if (!rateBytesPerSecond.isFinite()) {
            return 0L
        }
        if (rateBytesPerSecond <= 0) {
            return 50L
        }
        refill()
        val needed = bytes.toDouble().coerceAtMost(capacityBytes)
        if (tokens >= needed) return 0L
        val missing = needed - tokens
        return ((missing / rateBytesPerSecond) * 1000.0).toLong().coerceAtLeast(1L)
    }

    private fun refill() {
        val now = System.nanoTime()
        val elapsedSec = (now - lastRefillNanos) / 1_000_000_000.0
        lastRefillNanos = now
        tokens = (tokens + elapsedSec * rateBytesPerSecond).coerceAtMost(capacityBytes)
    }

    companion object {
        // Enough for one MTU-sized IP/TCP segment plus headroom.
        private const val DEFAULT_CAPACITY_BYTES = 64 * 1024.0
    }
}

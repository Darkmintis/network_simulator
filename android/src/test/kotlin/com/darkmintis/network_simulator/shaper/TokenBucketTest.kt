package com.darkmintis.network_simulator.shaper

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class TokenBucketTest {
    @Test
    fun unlimitedRateAlwaysConsumes() {
        val bucket = TokenBucket(Double.POSITIVE_INFINITY)
        assertTrue(bucket.tryConsume(16_384))
        assertTrue(bucket.tryConsume(65_535))
    }

    @Test
    fun zeroRateNeverConsumes() {
        val bucket = TokenBucket(0.0)
        assertFalse(bucket.tryConsume(1))
        assertTrue(bucket.waitTimeMillis(1) > 0)
    }

    @Test
    fun finiteRateAdmitsMssSizedChunk() {
        // 0.1 Mbps ≈ 13107 bytes/sec; capacity floor is 64 KiB.
        val bucket = TokenBucket(0.0)
        bucket.updateRate(0.1 * 1024.0 * 1024.0 / 8.0)
        assertTrue(bucket.tryConsume(1400))
    }
}

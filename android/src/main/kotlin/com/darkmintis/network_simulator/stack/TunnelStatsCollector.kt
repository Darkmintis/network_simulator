package com.darkmintis.network_simulator.stack

import java.util.concurrent.atomic.AtomicLong

class TunnelStatsCollector {
    private val bytesUploaded = AtomicLong(0)
    private val bytesDownloaded = AtomicLong(0)
    private val packetsUploaded = AtomicLong(0)
    private val packetsDownloaded = AtomicLong(0)
    private val packetsDropped = AtomicLong(0)

    private var lastSampleNanos = System.nanoTime()
    private var lastUp = 0L
    private var lastDown = 0L

    fun onUpload(bytes: Int) {
        bytesUploaded.addAndGet(bytes.toLong())
        packetsUploaded.incrementAndGet()
    }

    fun onDownload(bytes: Int) {
        bytesDownloaded.addAndGet(bytes.toLong())
        packetsDownloaded.incrementAndGet()
    }

    fun onDrop() {
        packetsDropped.incrementAndGet()
    }

    fun snapshot(): Map<String, Any> {
        val now = System.nanoTime()
        val elapsedSec = ((now - lastSampleNanos) / 1_000_000_000.0).coerceAtLeast(0.001)
        val up = bytesUploaded.get()
        val down = bytesDownloaded.get()
        val uploadMbps = ((up - lastUp) * 8.0 / elapsedSec) / (1024.0 * 1024.0)
        val downloadMbps = ((down - lastDown) * 8.0 / elapsedSec) / (1024.0 * 1024.0)
        lastSampleNanos = now
        lastUp = up
        lastDown = down

        return mapOf(
            "bytesUploaded" to up,
            "bytesDownloaded" to down,
            "packetsUploaded" to packetsUploaded.get(),
            "packetsDownloaded" to packetsDownloaded.get(),
            "packetsDropped" to packetsDropped.get(),
            "uploadMbps" to uploadMbps,
            "downloadMbps" to downloadMbps,
        )
    }

    fun reset() {
        bytesUploaded.set(0)
        bytesDownloaded.set(0)
        packetsUploaded.set(0)
        packetsDownloaded.set(0)
        packetsDropped.set(0)
        lastUp = 0
        lastDown = 0
        lastSampleNanos = System.nanoTime()
    }
}

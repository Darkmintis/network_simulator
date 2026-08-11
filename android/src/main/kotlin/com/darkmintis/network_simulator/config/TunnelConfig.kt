package com.darkmintis.network_simulator.config

/**
 * Immutable tunnel shaping parameters mirrored from Dart [NetworkSimulatorConfig].
 */
data class TunnelConfig(
    val mode: String = "normal",
    val latencyMs: Double = 0.0,
    val downloadMbps: Double = Double.POSITIVE_INFINITY,
    val uploadMbps: Double = Double.POSITIVE_INFINITY,
    val jitterMs: Double = 0.0,
    val packetLoss: Double = 0.0,
    val isOffline: Boolean = false,
) {
    companion object {
        fun fromMap(map: Map<*, *>?): TunnelConfig {
            if (map == null) return TunnelConfig()
            return TunnelConfig(
                mode = map["mode"] as? String ?: "normal",
                latencyMs = (map["latencyMs"] as? Number)?.toDouble() ?: 0.0,
                downloadMbps = mbpsFrom(map["downloadMbps"]),
                uploadMbps = mbpsFrom(map["uploadMbps"]),
                jitterMs = (map["jitterMs"] as? Number)?.toDouble() ?: 0.0,
                packetLoss = (map["packetLoss"] as? Number)?.toDouble() ?: 0.0,
                isOffline = map["isOffline"] as? Boolean ?: false,
            )
        }

        private fun mbpsFrom(value: Any?): Double {
            val number = (value as? Number)?.toDouble() ?: return Double.POSITIVE_INFINITY
            return if (number < 0) Double.POSITIVE_INFINITY else number
        }
    }
}

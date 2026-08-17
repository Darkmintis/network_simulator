/// Preset network condition profiles applied by the native traffic shaper.
enum NetworkMode {
  /// No shaping; unlimited bandwidth and zero artificial delay.
  normal,

  /// ~2000 ms latency, ~0.1 Mbps down, high jitter and loss.
  slow2G,

  /// ~800 ms latency, ~0.5 Mbps down, moderate jitter and loss.
  slow3G,

  /// ~300 ms latency, ~1.5 Mbps down, light jitter and loss.
  fast3G,

  /// ~120 ms latency with high jitter and packet loss spikes.
  unstable4G,

  /// Drops all traffic to simulate no connectivity.
  offline,

  /// User-defined latency, bandwidth, jitter, and loss values.
  custom,
}

/// UI labels for [NetworkMode] presets.
extension NetworkModeProfile on NetworkMode {
  /// Human-readable label shown in the debug UI.
  String get label {
    switch (this) {
      case NetworkMode.normal:
        return 'Normal';
      case NetworkMode.slow2G:
        return 'Slow 2G';
      case NetworkMode.slow3G:
        return 'Slow 3G';
      case NetworkMode.fast3G:
        return 'Fast 3G';
      case NetworkMode.unstable4G:
        return 'Unstable 4G';
      case NetworkMode.offline:
        return 'Offline';
      case NetworkMode.custom:
        return 'Custom';
    }
  }
}

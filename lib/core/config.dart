import 'mode.dart';

/// Immutable simulation parameters shared with native shapers.
class NetworkSimulatorConfig {
  /// Creates a config with explicit shaping values.
  const NetworkSimulatorConfig({
    required this.mode,
    required this.latencyMs,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.jitterMs,
    required this.packetLoss,
    required this.isOffline,
  });

  /// Unshaped network with unlimited bandwidth.
  const NetworkSimulatorConfig.normal()
    : this(
        mode: NetworkMode.normal,
        latencyMs: 0,
        downloadMbps: double.infinity,
        uploadMbps: double.infinity,
        jitterMs: 0,
        packetLoss: 0,
        isOffline: false,
      );

  /// Drops all traffic (100% packet loss).
  const NetworkSimulatorConfig.offline()
    : this(
        mode: NetworkMode.offline,
        latencyMs: 0,
        downloadMbps: 0,
        uploadMbps: 0,
        jitterMs: 0,
        packetLoss: 1,
        isOffline: true,
      );

  /// Returns the default [NetworkSimulatorConfig] for a [NetworkMode] preset.
  factory NetworkSimulatorConfig.forMode(NetworkMode mode) {
    switch (mode) {
      case NetworkMode.normal:
        return const NetworkSimulatorConfig.normal();
      case NetworkMode.slow2G:
        return const NetworkSimulatorConfig(
          mode: NetworkMode.slow2G,
          latencyMs: 2000,
          downloadMbps: 0.1,
          uploadMbps: 0.05,
          jitterMs: 300,
          packetLoss: 0.20,
          isOffline: false,
        );
      case NetworkMode.slow3G:
        return const NetworkSimulatorConfig(
          mode: NetworkMode.slow3G,
          latencyMs: 800,
          downloadMbps: 0.5,
          uploadMbps: 0.25,
          jitterMs: 150,
          packetLoss: 0.10,
          isOffline: false,
        );
      case NetworkMode.fast3G:
        return const NetworkSimulatorConfig(
          mode: NetworkMode.fast3G,
          latencyMs: 300,
          downloadMbps: 1.5,
          uploadMbps: 0.75,
          jitterMs: 50,
          packetLoss: 0.03,
          isOffline: false,
        );
      case NetworkMode.unstable4G:
        return const NetworkSimulatorConfig(
          mode: NetworkMode.unstable4G,
          latencyMs: 120,
          downloadMbps: 4.0,
          uploadMbps: 2.0,
          jitterMs: 80,
          packetLoss: 0.15,
          isOffline: false,
        );
      case NetworkMode.offline:
        return const NetworkSimulatorConfig.offline();
      case NetworkMode.custom:
        return const NetworkSimulatorConfig.normal().copyWith(
          mode: NetworkMode.custom,
        );
    }
  }

  /// Active preset or custom profile.
  final NetworkMode mode;

  /// Base one-way latency in milliseconds.
  final double latencyMs;

  /// Download bandwidth cap in megabits per second.
  final double downloadMbps;

  /// Upload bandwidth cap in megabits per second.
  final double uploadMbps;

  /// Random latency variation applied on top of [latencyMs].
  final double jitterMs;

  /// Fraction of packets dropped (0.0–1.0).
  final double packetLoss;

  /// When `true`, all traffic is blocked regardless of other fields.
  final bool isOffline;

  /// Backward-compatible average bandwidth helper for UI.
  double get bandwidthMbps {
    if (!downloadMbps.isFinite && !uploadMbps.isFinite) {
      return double.infinity;
    }
    if (!downloadMbps.isFinite) return uploadMbps;
    if (!uploadMbps.isFinite) return downloadMbps;
    return (downloadMbps + uploadMbps) / 2;
  }

  /// Serializes this config for the native MethodChannel bridge.
  Map<String, dynamic> toPlatformMap() {
    return <String, dynamic>{
      'mode': mode.name,
      'latencyMs': latencyMs,
      'downloadMbps': downloadMbps.isFinite ? downloadMbps : -1.0,
      'uploadMbps': uploadMbps.isFinite ? uploadMbps : -1.0,
      'jitterMs': jitterMs,
      'packetLoss': packetLoss,
      'isOffline': isOffline,
    };
  }

  /// Returns a copy with the given fields replaced.
  NetworkSimulatorConfig copyWith({
    NetworkMode? mode,
    double? latencyMs,
    double? downloadMbps,
    double? uploadMbps,
    double? jitterMs,
    double? packetLoss,
    bool? isOffline,
  }) {
    return NetworkSimulatorConfig(
      mode: mode ?? this.mode,
      latencyMs: latencyMs ?? this.latencyMs,
      downloadMbps: downloadMbps ?? this.downloadMbps,
      uploadMbps: uploadMbps ?? this.uploadMbps,
      jitterMs: jitterMs ?? this.jitterMs,
      packetLoss: packetLoss ?? this.packetLoss,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

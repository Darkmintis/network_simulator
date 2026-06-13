import 'mode.dart';

class NetworkSimulatorConfig {
  const NetworkSimulatorConfig({
    required this.mode,
    required this.latencyMs,
    required this.bandwidthMbps,
    required this.packetLoss,
    required this.isOffline,
  });

  const NetworkSimulatorConfig.normal()
    : this(
        mode: NetworkMode.normal,
        latencyMs: 0,
        bandwidthMbps: double.infinity,
        packetLoss: 0,
        isOffline: false,
      );

  const NetworkSimulatorConfig.offline()
    : this(
        mode: NetworkMode.offline,
        latencyMs: 0,
        bandwidthMbps: 0,
        packetLoss: 1,
        isOffline: true,
      );

  final NetworkMode mode;
  final double latencyMs;
  final double bandwidthMbps;
  final double packetLoss;
  final bool isOffline;

  NetworkSimulatorConfig copyWith({
    NetworkMode? mode,
    double? latencyMs,
    double? bandwidthMbps,
    double? packetLoss,
    bool? isOffline,
  }) {
    return NetworkSimulatorConfig(
      mode: mode ?? this.mode,
      latencyMs: latencyMs ?? this.latencyMs,
      bandwidthMbps: bandwidthMbps ?? this.bandwidthMbps,
      packetLoss: packetLoss ?? this.packetLoss,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

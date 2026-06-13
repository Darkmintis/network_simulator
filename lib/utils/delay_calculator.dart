import '../core/config.dart';

class DelayCalculator {
  const DelayCalculator._();

  static Duration calculateDelay(NetworkSimulatorConfig config, {int bytes = 0}) {
    if (config.isOffline) {
      return Duration.zero;
    }

    final latency = config.latencyMs.isFinite ? config.latencyMs : 0;
    final bandwidthMbps = config.bandwidthMbps;
    if (!bandwidthMbps.isFinite || bandwidthMbps <= 0) {
      return Duration(milliseconds: latency.round());
    }

    final speedBps = (bandwidthMbps * 1024 * 1024) / 8;
    final transferTimeMs = bytes <= 0 ? 0 : (bytes / speedBps) * 1000;
    final totalDelayMs = latency + transferTimeMs;

    return Duration(milliseconds: totalDelayMs.round());
  }
}

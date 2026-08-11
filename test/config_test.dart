import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';

void main() {
  group('NetworkMode', () {
    test('labels are human readable', () {
      expect(NetworkMode.normal.label, 'Normal');
      expect(NetworkMode.slow2G.label, 'Slow 2G');
      expect(NetworkMode.slow3G.label, 'Slow 3G');
      expect(NetworkMode.fast3G.label, 'Fast 3G');
      expect(NetworkMode.unstable4G.label, 'Unstable 4G');
      expect(NetworkMode.offline.label, 'Offline');
      expect(NetworkMode.custom.label, 'Custom');
    });
  });

  group('NetworkSimulatorConfig', () {
    test('normal factory defaults', () {
      const config = NetworkSimulatorConfig.normal();
      expect(config.mode, NetworkMode.normal);
      expect(config.latencyMs, 0);
      expect(config.jitterMs, 0);
      expect(config.packetLoss, 0);
      expect(config.isOffline, isFalse);
      expect(config.downloadMbps, double.infinity);
      expect(config.uploadMbps, double.infinity);
      expect(config.bandwidthMbps, double.infinity);
    });

    test('offline factory', () {
      const config = NetworkSimulatorConfig.offline();
      expect(config.mode, NetworkMode.offline);
      expect(config.isOffline, isTrue);
      expect(config.packetLoss, 1);
      expect(config.downloadMbps, 0);
      expect(config.uploadMbps, 0);
    });

    test('forMode covers all presets', () {
      for (final mode in NetworkMode.values) {
        final config = NetworkSimulatorConfig.forMode(mode);
        expect(config.mode, mode == NetworkMode.custom ? NetworkMode.custom : mode);
      }

      final slow2g = NetworkSimulatorConfig.forMode(NetworkMode.slow2G);
      expect(slow2g.latencyMs, 2000);
      expect(slow2g.downloadMbps, 0.1);
      expect(slow2g.uploadMbps, 0.05);
      expect(slow2g.jitterMs, 300);
      expect(slow2g.packetLoss, 0.20);

      final unstable = NetworkSimulatorConfig.forMode(NetworkMode.unstable4G);
      expect(unstable.latencyMs, 120);
      expect(unstable.downloadMbps, 4.0);
      expect(unstable.packetLoss, 0.15);
    });

    test('copyWith preserves unspecified fields', () {
      final base = NetworkSimulatorConfig.forMode(NetworkMode.slow3G);
      final copy = base.copyWith(latencyMs: 900);
      expect(copy.latencyMs, 900);
      expect(copy.downloadMbps, base.downloadMbps);
      expect(copy.mode, NetworkMode.slow3G);
    });

    test('toPlatformMap encodes unlimited bandwidth as -1', () {
      final map = const NetworkSimulatorConfig.normal().toPlatformMap();
      expect(map['mode'], 'normal');
      expect(map['downloadMbps'], -1.0);
      expect(map['uploadMbps'], -1.0);
      expect(map['isOffline'], isFalse);
    });

    test('toPlatformMap encodes finite bandwidth', () {
      final map = NetworkSimulatorConfig.forMode(NetworkMode.fast3G).toPlatformMap();
      expect(map['downloadMbps'], 1.5);
      expect(map['uploadMbps'], 0.75);
      expect(map['latencyMs'], 300);
    });

    test('bandwidthMbps averages finite directions', () {
      const config = NetworkSimulatorConfig(
        mode: NetworkMode.custom,
        latencyMs: 0,
        downloadMbps: 4,
        uploadMbps: 2,
        jitterMs: 0,
        packetLoss: 0,
        isOffline: false,
      );
      expect(config.bandwidthMbps, 3);
    });
  });
}

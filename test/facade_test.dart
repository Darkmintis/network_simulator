import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';
import 'package:network_simulator/platform/network_simulator_platform.dart';

import 'support/fake_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNetworkSimulatorPlatform platform;

  setUp(() async {
    platform = FakeNetworkSimulatorPlatform();
    NetworkSimulatorPlatform.instance = platform;
    await NetworkSimulator.init();
  });

  tearDown(() async {
    try {
      await NetworkSimulator.stopTunnel();
    } catch (_) {}
    NetworkSimulator.reset();
    await platform.dispose();
  });

  group('NetworkSimulator facade', () {
    test('isSupported delegates to platform', () async {
      expect(await NetworkSimulator.isSupported(), isTrue);
      platform.supported = false;
      expect(await NetworkSimulator.isSupported(), isFalse);
    });

    test('setMode and custom update controller config', () {
      NetworkSimulator.setMode(NetworkMode.fast3G);
      expect(NetworkSimulator.controller.mode, NetworkMode.fast3G);

      NetworkSimulator.custom(
        latencyMs: 40,
        downloadMbps: 8,
        uploadMbps: 4,
        jitterMs: 5,
        packetLoss: 0.02,
      );
      expect(NetworkSimulator.controller.mode, NetworkMode.custom);
      expect(NetworkSimulator.controller.latencyMs, 40);
      expect(NetworkSimulator.controller.downloadMbps, 8);
    });

    test('offline and reset', () {
      NetworkSimulator.offline();
      expect(NetworkSimulator.controller.isOffline, isTrue);
      NetworkSimulator.reset();
      expect(NetworkSimulator.controller.mode, NetworkMode.normal);
    });

    test('startTunnel and stopTunnel', () async {
      NetworkSimulator.setMode(NetworkMode.slow3G);
      await NetworkSimulator.startTunnel();
      expect(platform.startCount, greaterThan(0));
      expect(NetworkSimulator.controller.status, TunnelStatus.connected);

      await NetworkSimulator.stopTunnel();
      expect(NetworkSimulator.controller.status, TunnelStatus.idle);
    });
  });
}

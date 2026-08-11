import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';

import 'support/fake_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNetworkSimulatorPlatform platform;
  late NetworkSimulatorController controller;

  setUp(() {
    platform = FakeNetworkSimulatorPlatform();
    NetworkSimulatorPlatform.instance = platform;
    controller = NetworkSimulatorController(platform: platform);
  });

  tearDown(() async {
    controller.dispose();
    await platform.dispose();
  });

  group('NetworkSimulatorController', () {
    test('setMode applies preset values', () {
      controller.setMode(NetworkMode.fast3G);
      expect(controller.mode, NetworkMode.fast3G);
      expect(controller.latencyMs, 300);
      expect(controller.downloadMbps, 1.5);
      expect(controller.uploadMbps, 0.75);
      expect(controller.jitterMs, 50);
      expect(controller.packetLoss, 0.03);
      expect(controller.isOffline, isFalse);
    });

    test('setCustom uses bandwidthMbps for both directions', () {
      controller.setCustom(
        latencyMs: 100,
        bandwidthMbps: 2,
        jitterMs: 10,
        packetLoss: 0.05,
      );
      expect(controller.mode, NetworkMode.custom);
      expect(controller.latencyMs, 100);
      expect(controller.downloadMbps, 2);
      expect(controller.uploadMbps, 2);
      expect(controller.jitterMs, 10);
      expect(controller.packetLoss, 0.05);
    });

    test('setCustom prefers explicit download/upload over bandwidthMbps', () {
      controller.setCustom(
        bandwidthMbps: 9,
        downloadMbps: 3,
        uploadMbps: 1,
      );
      expect(controller.downloadMbps, 3);
      expect(controller.uploadMbps, 1);
    });

    test('packet loss percent and fraction normalization', () {
      controller.setCustom(packetLoss: 25);
      expect(controller.packetLoss, 0.25);

      controller.setCustom(packetLoss: 0.4);
      expect(controller.packetLoss, 0.4);

      controller.setCustom(packetLoss: -5);
      expect(controller.packetLoss, 0);

      controller.setCustom(packetLoss: 150);
      expect(controller.packetLoss, 1.0);
    });

    test('enableOffline and reset', () {
      controller.setMode(NetworkMode.slow3G);
      controller.enableOffline();
      expect(controller.isOffline, isTrue);
      expect(controller.mode, NetworkMode.offline);

      controller.reset();
      expect(controller.mode, NetworkMode.normal);
      expect(controller.isOffline, isFalse);
      expect(controller.lastError, isNull);
    });

    test('startTunnel and stopTunnel lifecycle', () async {
      controller.setMode(NetworkMode.slow2G);
      await controller.startTunnel();

      expect(platform.startCount, 1);
      expect(platform.lastConfig?.mode, NetworkMode.slow2G);
      expect(controller.status, TunnelStatus.connected);
      expect(controller.isTunnelActive, isTrue);

      await controller.stopTunnel();
      expect(platform.stopCount, 1);
      expect(controller.status, TunnelStatus.idle);
      expect(controller.stats.bytesDownloaded, 0);
    });

    test('startTunnel failure sets error status and rethrows', () async {
      platform.startError = Exception('vpn denied');
      expect(controller.startTunnel(), throwsA(isA<Exception>()));
      await pumpEventQueue();
      expect(controller.status, TunnelStatus.error);
      expect(controller.lastError, contains('vpn denied'));
    });

    test('stopTunnel failure sets error status and rethrows', () async {
      await controller.startTunnel();
      platform.stopError = Exception('stop failed');
      expect(controller.stopTunnel(), throwsA(isA<Exception>()));
      await pumpEventQueue();
      expect(controller.status, TunnelStatus.error);
      expect(controller.lastError, contains('stop failed'));
    });

    test('updateConfig is pushed while connected', () async {
      await controller.startTunnel();
      platform.updateCount = 0;
      controller.setMode(NetworkMode.slow3G);
      await pumpEventQueue();
      expect(platform.updateCount, 1);
      expect(platform.lastConfig?.mode, NetworkMode.slow3G);
    });

    test('updateConfig is not pushed while idle', () async {
      controller.setMode(NetworkMode.slow3G);
      await pumpEventQueue();
      expect(platform.updateCount, 0);
    });

    test('bindPlatformListeners mirrors streams', () async {
      await controller.bindPlatformListeners();
      platform.statsController.add(
        const TunnelStats(
          bytesUploaded: 1,
          bytesDownloaded: 2,
          packetsUploaded: 1,
          packetsDownloaded: 1,
          packetsDropped: 0,
          uploadMbps: 0.5,
          downloadMbps: 1.0,
        ),
      );
      await pumpEventQueue();
      expect(controller.stats.downloadMbps, 1.0);

      platform.errorController.add('native boom');
      await pumpEventQueue();
      expect(controller.status, TunnelStatus.error);
      expect(controller.lastError, 'native boom');
    });

    test('isSupported delegates to platform', () async {
      platform.supported = false;
      expect(await controller.isSupported(), isFalse);
      platform.supported = true;
      expect(await controller.isSupported(), isTrue);
    });

    test('configure stores provider bundle id for startTunnel', () async {
      controller.configure(providerBundleIdentifier: 'com.example.tunnel');
      await controller.startTunnel();
      expect(platform.lastProviderBundleId, 'com.example.tunnel');
    });
  });
}

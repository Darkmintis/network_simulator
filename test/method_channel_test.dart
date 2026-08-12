import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';
import 'package:network_simulator/platform/method_channel_network_simulator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('network_simulator/tunnel');
  final log = <MethodCall>[];

  late MethodChannelNetworkSimulator platform;

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, (call) async {
          log.add(call);
          switch (call.method) {
            case 'isSupported':
              return true;
            case 'getStatus':
              return 'connected';
            case 'startTunnel':
            case 'stopTunnel':
            case 'updateConfig':
              return null;
            default:
              return null;
          }
        });
    platform = MethodChannelNetworkSimulator(methodChannel: methodChannel);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(methodChannel, null);
  });

  group('MethodChannelNetworkSimulator', () {
    test('isSupported', () async {
      expect(await platform.isSupported(), isTrue);
      expect(log.single.method, 'isSupported');
    });

    test('getStatus parses wire value', () async {
      expect(await platform.getStatus(), TunnelStatus.connected);
    });

    test('startTunnel sends config and provider id', () async {
      final config = NetworkSimulatorConfig.forMode(NetworkMode.slow3G);
      await platform.startTunnel(
        config: config,
        providerBundleIdentifier: 'com.example.NetworkSimulatorTunnel',
      );

      expect(log.single.method, 'startTunnel');
      final args = log.single.arguments as Map;
      expect(
        args['providerBundleIdentifier'],
        'com.example.NetworkSimulatorTunnel',
      );
      final sent = args['config'] as Map;
      expect(sent['mode'], 'slow3G');
      expect(sent['latencyMs'], 800);
      expect(sent['downloadMbps'], 0.5);
    });

    test('stopTunnel', () async {
      await platform.stopTunnel();
      expect(log.single.method, 'stopTunnel');
    });

    test('updateConfig sends platform map', () async {
      await platform.updateConfig(const NetworkSimulatorConfig.offline());
      expect(log.single.method, 'updateConfig');
      final args = log.single.arguments as Map;
      expect(args['isOffline'], isTrue);
      expect(args['packetLoss'], 1);
    });
  });
}

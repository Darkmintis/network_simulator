import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';
import 'package:network_simulator/platform/network_simulator_platform.dart';

import 'support/fake_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNetworkSimulatorPlatform platform;

  setUp(() {
    platform = FakeNetworkSimulatorPlatform();
    NetworkSimulatorPlatform.instance = platform;
  });

  tearDown(() async {
    await platform.dispose();
  });

  testWidgets('panel shows Android-only footer and surfaces start errors', (
    tester,
  ) async {
    final controller = NetworkSimulatorController(platform: platform);
    platform.startError = Exception('vpn denied');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkSimulatorPanel(controller: controller),
        ),
      ),
    );

    expect(find.textContaining('Android only'), findsOneWidget);

    await tester.tap(find.text('Start tunnel'));
    await tester.pumpAndSettle();

    expect(controller.status, TunnelStatus.error);
    expect(find.textContaining('vpn denied'), findsOneWidget);

    controller.dispose();
  });

  testWidgets('applying Slow 3G updates controller mode', (tester) async {
    final controller = NetworkSimulatorController(platform: platform);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkSimulatorPanel(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('Slow 3G'));
    await tester.pump();

    expect(controller.mode, NetworkMode.slow3G);
    expect(controller.latencyMs, 800);

    controller.dispose();
  });
}

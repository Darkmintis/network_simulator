import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';
import 'package:network_simulator/platform/network_simulator_platform.dart';

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

  testWidgets('floating button invokes callback', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkSimulatorFloatingButton(onPressed: () => pressed = true),
        ),
      ),
    );

    await tester.tap(find.byType(NetworkSimulatorFloatingButton));
    expect(pressed, isTrue);
  });

  testWidgets('control panel shows tunnel controls and stats', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () =>
                    NetworkSimulatorControlPanel.show(context, controller),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Network Simulator'), findsOneWidget);
    expect(find.text('Start tunnel'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('control panel start tunnel triggers platform', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NetworkSimulatorControlPanel(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('Start tunnel'));
    await tester.pumpAndSettle();

    expect(platform.startCount, 1);
    expect(controller.status, TunnelStatus.connected);
    expect(find.text('Stop tunnel'), findsOneWidget);
  });
}

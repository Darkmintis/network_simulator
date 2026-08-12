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

  testWidgets('launcher icon pushes simulator screen', (tester) async {
    await NetworkSimulator.init();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: const [NetworkSimulatorLauncherIcon()]),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.wifi_tethering_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Network Simulator'), findsOneWidget);
    expect(find.text('Start tunnel'), findsOneWidget);
    expect(find.text('Slow 3G'), findsOneWidget);
    expect(find.text('Real network speed — no artificial limits'), findsOneWidget);
  });

  testWidgets('simulator screen start tunnel triggers platform', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NetworkSimulatorScreen(controller: controller),
      ),
    );

    await tester.tap(find.text('Start tunnel'));
    await tester.pumpAndSettle();

    expect(platform.startCount, 1);
    expect(controller.status, TunnelStatus.connected);
    expect(find.text('Stop tunnel'), findsOneWidget);
  });

  testWidgets('simulator screen closes with back', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => NetworkSimulatorScreen.open(
                  context,
                  controller: controller,
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Start tunnel'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}

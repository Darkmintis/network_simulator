import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator_example/main.dart';

void main() {
  testWidgets('Demo home loads', (tester) async {
    await tester.pumpWidget(
      NetworkSimulatorExampleApp(
        navigatorKey: GlobalKey<NavigatorState>(),
      ),
    );
    expect(find.text('Network Simulator'), findsOneWidget);
    expect(find.text('Start tunnel'), findsOneWidget);
  });
}

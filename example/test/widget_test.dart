import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:network_simulator_example/main.dart';

void main() {
  testWidgets('builds the Network Simulator example app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      NetworkSimulatorExampleApp(dio: Dio(), navigatorKey: GlobalKey<NavigatorState>()),
    );

    expect(find.text('Network Simulator Example'), findsOneWidget);
    expect(find.text('Login request'), findsOneWidget);
  });
}

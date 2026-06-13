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

    expect(find.text('Network Simulator'), findsOneWidget);
    expect(find.text('GET /posts'), findsOneWidget);
    expect(find.text('GET /posts/1'), findsOneWidget);
    expect(find.text('GET /comments'), findsOneWidget);
  });
}

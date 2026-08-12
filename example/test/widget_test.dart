import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator_example/main.dart';

void main() {
  testWidgets('Example app loads with HTTP buttons', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Example'), findsOneWidget);
    expect(find.text('GET /posts'), findsOneWidget);
    expect(find.text('GET /posts/1'), findsOneWidget);
    expect(find.text('POST /posts'), findsOneWidget);
  });
}

import 'dart:convert';

import '../core/config.dart';
import 'delay_calculator.dart';

class ThrottleEngine {
  const ThrottleEngine._();

  static Future<void> simulate(NetworkSimulatorConfig config, {Object? body}) async {
    final bytes = estimateBytes(body);
    final delay = DelayCalculator.calculateDelay(config, bytes: bytes);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
  }

  static int estimateBytes(Object? value) {
    if (value == null) {
      return 0;
    }
    if (value is String) {
      return utf8.encode(value).length;
    }
    if (value is List<int>) {
      return value.length;
    }
    if (value is Map || value is Iterable) {
      return utf8.encode(jsonEncode(value)).length;
    }
    return utf8.encode(value.toString()).length;
  }
}

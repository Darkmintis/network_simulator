import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_simulator/network_simulator.dart';

void main() {
  group('NetworkSimulatorConfig', () {
    test('normal config has zero impact', () {
      const config = NetworkSimulatorConfig.normal();

      expect(config.mode, NetworkMode.normal);
      expect(config.latencyMs, 0);
      expect(config.bandwidthMbps, double.infinity);
      expect(config.packetLoss, 0);
      expect(config.isOffline, isFalse);
    });

    test('offline config blocks all requests', () {
      const config = NetworkSimulatorConfig.offline();

      expect(config.mode, NetworkMode.offline);
      expect(config.latencyMs, 0);
      expect(config.bandwidthMbps, 0);
      expect(config.packetLoss, 1);
      expect(config.isOffline, isTrue);
    });

    test('copyWith overrides only specified fields', () {
      const original = NetworkSimulatorConfig(
        mode: NetworkMode.slow3G,
        latencyMs: 800,
        bandwidthMbps: 0.5,
        packetLoss: 0.10,
        isOffline: false,
      );

      final copy = original.copyWith(latencyMs: 1200);

      expect(copy.mode, NetworkMode.slow3G);
      expect(copy.latencyMs, 1200);
      expect(copy.bandwidthMbps, 0.5);
      expect(copy.packetLoss, 0.10);
      expect(copy.isOffline, isFalse);
    });
  });

  group('NetworkSimulatorController', () {
    test('starts in normal mode', () {
      final controller = NetworkSimulatorController();

      expect(controller.mode, NetworkMode.normal);
      expect(controller.isOffline, isFalse);
      expect(controller.latencyMs, 0);
    });

    test('applies all predefined profiles', () {
      final profiles = {
        NetworkMode.normal: (0, double.infinity, 0.0, false),
        NetworkMode.slow2G: (2000, 0.1, 0.20, false),
        NetworkMode.slow3G: (800, 0.5, 0.10, false),
        NetworkMode.fast3G: (300, 1.5, 0.03, false),
        NetworkMode.unstable4G: (120, 4.0, 0.15, false),
        NetworkMode.offline: (0, 0.0, 1.0, true),
      };

      for (final entry in profiles.entries) {
        final controller = NetworkSimulatorController();
        controller.setMode(entry.key);

        expect(controller.mode, entry.key,
            reason: 'mode should be ${entry.key}');
        expect(controller.latencyMs, entry.value.$1);
        expect(controller.bandwidthMbps, entry.value.$2);
        expect(controller.packetLoss, entry.value.$3);
        expect(controller.isOffline, entry.value.$4);
      }
    });

    test('setCustom updates config and sets mode to custom', () {
      final controller = NetworkSimulatorController();

      controller.setCustom(latencyMs: 500, bandwidthMbps: 2, packetLoss: 0.05);

      expect(controller.mode, NetworkMode.custom);
      expect(controller.latencyMs, 500);
      expect(controller.bandwidthMbps, 2);
      expect(controller.packetLoss, 0.05);
    });

    test('normalizes packet loss from percentage to fraction', () {
      final controller = NetworkSimulatorController();

      controller.setCustom(packetLoss: 25);

      expect(controller.packetLoss, 0.25);
    });

    test('clamps packet loss to valid range', () {
      final controller = NetworkSimulatorController();

      controller.setCustom(packetLoss: -0.5);
      expect(controller.packetLoss, 0);

      controller.setCustom(packetLoss: 200);
      expect(controller.packetLoss, 1.0);
    });

    test('enableOffline forces offline mode', () {
      final controller = NetworkSimulatorController();

      controller.setMode(NetworkMode.slow3G);
      controller.enableOffline();

      expect(controller.isOffline, isTrue);
      expect(controller.mode, NetworkMode.offline);
    });

    test('reset clears config and logs', () {
      final controller = NetworkSimulatorController();

      controller.setMode(NetworkMode.slow3G);
      controller.logger.log(NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        durationMs: 100,
        success: true,
      ));
      controller.reset();

      expect(controller.mode, NetworkMode.normal);
      expect(controller.isOffline, isFalse);
      expect(controller.logger.logs, isEmpty);
    });

    test('shouldFail returns false in normal mode', () {
      final controller = NetworkSimulatorController();
      final fixed = Random(0);

      expect(controller.shouldFail(random: fixed), isFalse);
    });

    test('shouldFail returns true based on packet loss probability', () {
      final controller = NetworkSimulatorController();
      controller.setCustom(packetLoss: 1.0);

      expect(controller.shouldFail(), isTrue);
    });

    test('shouldFail returns false when offline', () {
      final controller = NetworkSimulatorController();
      controller.enableOffline();

      expect(controller.shouldFail(), isFalse);
    });

    test('estimateDelay returns zero for normal config', () {
      final controller = NetworkSimulatorController();

      final delay = controller.estimateDelay();

      expect(delay.inMilliseconds, 0);
    });

    test('estimateDelay includes latency and bandwidth components', () {
      final controller = NetworkSimulatorController();
      controller.setCustom(latencyMs: 100, bandwidthMbps: 1.0);

      final delay = controller.estimateDelay(body: '{"data":"test"}');

      expect(delay.inMilliseconds, greaterThan(0));
    });

    test('notifies listeners on state changes', () {
      final controller = NetworkSimulatorController();
      int notifyCount = 0;

      controller.addListener(() => notifyCount++);
      controller.setMode(NetworkMode.slow3G);

      expect(notifyCount, greaterThan(0));
    });
  });

  group('NetworkSimulatorLogger', () {
    test('stores logged entries', () {
      final logger = NetworkSimulatorLogger();

      logger.log(NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        durationMs: 120,
        success: true,
        statusCode: 200,
      ));

      expect(logger.logs, hasLength(1));
    });

    test('inserts newest entries at the front', () {
      final logger = NetworkSimulatorLogger();

      logger.log(NetworkLog(
        method: 'GET',
        url: '/first',
        durationMs: 100,
        success: true,
      ));
      logger.log(NetworkLog(
        method: 'POST',
        url: '/second',
        durationMs: 200,
        success: true,
      ));

      expect(logger.logs.first.url, '/second');
      expect(logger.logs.last.url, '/first');
    });

    test('caps at 100 entries', () {
      final logger = NetworkSimulatorLogger();

      for (int i = 0; i < 110; i++) {
        logger.log(NetworkLog(
          method: 'GET',
          url: '/api/$i',
          durationMs: i,
          success: true,
        ));
      }

      expect(logger.logs.length, 100);
    });

    test('clears all entries', () {
      final logger = NetworkSimulatorLogger();

      logger.log(NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        durationMs: 50,
        success: true,
      ));
      logger.clear();

      expect(logger.logs, isEmpty);
    });

    test('clear is no-op on empty logger', () {
      final logger = NetworkSimulatorLogger();

      expect(() => logger.clear(), returnsNormally);
    });

    test('notifies listeners on log and clear', () {
      final logger = NetworkSimulatorLogger();
      int notifyCount = 0;

      logger.addListener(() => notifyCount++);
      logger.log(NetworkLog(
        method: 'GET',
        url: '/test',
        durationMs: 10,
        success: true,
      ));

      expect(notifyCount, 1);
    });
  });

  group('NetworkLog', () {
    test('sets timestamp on creation', () {
      final log = NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        durationMs: 100,
        success: true,
      );

      expect(log.timestamp, isNotNull);
      expect(
        DateTime.now().difference(log.timestamp).inSeconds,
        lessThan(5),
      );
    });

    test('summary includes method, url, duration and status', () {
      final log = NetworkLog(
        method: 'POST',
        url: 'https://api.example.com/login',
        durationMs: 350,
        success: true,
        statusCode: 200,
      );

      expect(log.summary, contains('POST'));
      expect(log.summary, contains('350ms'));
      expect(log.summary, contains('OK'));
      expect(log.summary, contains('200'));
    });

    test('failure summary shows FAIL', () {
      final log = NetworkLog(
        method: 'GET',
        url: 'https://example.com',
        durationMs: 5000,
        success: false,
        errorMessage: 'Timeout',
      );

      expect(log.summary, contains('FAIL'));
    });
  });

  group('DelayCalculator', () {
    test('returns zero for offline config', () {
      const config = NetworkSimulatorConfig.offline();

      final delay = DelayCalculator.calculateDelay(config, bytes: 1000);

      expect(delay.inMilliseconds, 0);
    });

    test('returns latency only when bandwidth is infinite', () {
      const config = NetworkSimulatorConfig.normal();

      final delay = DelayCalculator.calculateDelay(config, bytes: 100000);

      expect(delay.inMilliseconds, 0);
    });

    test('includes bandwidth transfer time for finite bandwidth', () {
      const config = NetworkSimulatorConfig(
        mode: NetworkMode.slow3G,
        latencyMs: 100,
        bandwidthMbps: 0.5,
        packetLoss: 0.10,
        isOffline: false,
      );

      final delay = DelayCalculator.calculateDelay(config, bytes: 500000);

      expect(delay.inMilliseconds, greaterThan(100));
    });

    test('returns latency only when bytes is zero', () {
      const config = NetworkSimulatorConfig(
        mode: NetworkMode.custom,
        latencyMs: 200,
        bandwidthMbps: 1.0,
        packetLoss: 0,
        isOffline: false,
      );

      final delay = DelayCalculator.calculateDelay(config, bytes: 0);

      expect(delay.inMilliseconds, 200);
    });
  });

  group('ThrottleEngine', () {
    test('estimateBytes returns 0 for null', () {
      expect(ThrottleEngine.estimateBytes(null), 0);
    });

    test('estimateBytes returns length for string', () {
      expect(ThrottleEngine.estimateBytes('hello'), greaterThan(0));
    });

    test('estimateBytes returns length for byte list', () {
      expect(ThrottleEngine.estimateBytes([1, 2, 3, 4, 5]), 5);
    });

    test('estimateBytes handles maps', () {
      expect(
        ThrottleEngine.estimateBytes({'key': 'value'}),
        greaterThan(0),
      );
    });
  });

  group('NetworkSimulator facade', () {
    test('controller and logger are accessible', () {
      expect(NetworkSimulator.controller, isNotNull);
      expect(NetworkSimulator.logger, isNotNull);
    });

    test('setMode updates controller state', () {
      NetworkSimulator.setMode(NetworkMode.slow3G);

      expect(NetworkSimulator.controller.mode, NetworkMode.slow3G);
      expect(NetworkSimulator.controller.latencyMs, 800);
    });

    test('custom updates controller with custom values', () {
      NetworkSimulator.custom(latencyMs: 400, bandwidthMbps: 1, packetLoss: 0.1);

      expect(NetworkSimulator.controller.mode, NetworkMode.custom);
      expect(NetworkSimulator.controller.latencyMs, 400);
    });

    test('offline sets offline mode', () {
      NetworkSimulator.offline();

      expect(NetworkSimulator.controller.isOffline, isTrue);
    });

    test('reset restores default state', () {
      NetworkSimulator.offline();
      NetworkSimulator.reset();

      expect(NetworkSimulator.controller.mode, NetworkMode.normal);
      expect(NetworkSimulator.controller.isOffline, isFalse);
    });
  });
}

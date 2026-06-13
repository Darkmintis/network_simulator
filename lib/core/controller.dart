import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../logger/request_logger.dart';
import '../utils/delay_calculator.dart';
import '../utils/throttle_engine.dart';
import 'config.dart';
import 'mode.dart';

class NetworkSimulatorController extends ChangeNotifier {
  NetworkSimulatorController({NetworkSimulatorLogger? logger})
    : logger = logger ?? NetworkSimulatorLogger();

  final NetworkSimulatorLogger logger;
  final Random _random = Random();

  NetworkSimulatorConfig _config = const NetworkSimulatorConfig.normal();
  Dio? _dio;

  NetworkMode get mode => _config.mode;
  double get latencyMs => _config.latencyMs;
  double get bandwidthMbps => _config.bandwidthMbps;
  double get packetLoss => _config.packetLoss;
  bool get isOffline => _config.isOffline;
  NetworkSimulatorConfig get config => _config;

  void attachDio(Dio dio) {
    _dio = dio;
  }

  Dio? get dio => _dio;

  void setMode(NetworkMode mode) {
    switch (mode) {
      case NetworkMode.normal:
        _config = const NetworkSimulatorConfig.normal();
      case NetworkMode.slow2G:
        _config = const NetworkSimulatorConfig(
          mode: NetworkMode.slow2G,
          latencyMs: 2000,
          bandwidthMbps: 0.1,
          packetLoss: 0.20,
          isOffline: false,
        );
      case NetworkMode.slow3G:
        _config = const NetworkSimulatorConfig(
          mode: NetworkMode.slow3G,
          latencyMs: 800,
          bandwidthMbps: 0.5,
          packetLoss: 0.10,
          isOffline: false,
        );
      case NetworkMode.fast3G:
        _config = const NetworkSimulatorConfig(
          mode: NetworkMode.fast3G,
          latencyMs: 300,
          bandwidthMbps: 1.5,
          packetLoss: 0.03,
          isOffline: false,
        );
      case NetworkMode.unstable4G:
        _config = const NetworkSimulatorConfig(
          mode: NetworkMode.unstable4G,
          latencyMs: 120,
          bandwidthMbps: 4.0,
          packetLoss: 0.15,
          isOffline: false,
        );
      case NetworkMode.offline:
        _config = const NetworkSimulatorConfig.offline();
      case NetworkMode.custom:
        _config = _config.copyWith(mode: NetworkMode.custom);
    }

    notifyListeners();
  }

  void setCustom({
    double? latencyMs,
    double? bandwidthMbps,
    double? packetLoss,
  }) {
    _config = _config.copyWith(
      mode: NetworkMode.custom,
      latencyMs: latencyMs ?? _config.latencyMs,
      bandwidthMbps: bandwidthMbps ?? _config.bandwidthMbps,
      packetLoss: _normalizePacketLoss(packetLoss ?? _config.packetLoss),
      isOffline: false,
    );
    notifyListeners();
  }

  void enableOffline() {
    _config = const NetworkSimulatorConfig.offline();
    notifyListeners();
  }

  void reset() {
    _config = const NetworkSimulatorConfig.normal();
    logger.clear();
    notifyListeners();
  }

  Future<void> applyLatency() async {
    await Future<void>.delayed(
      Duration(milliseconds: _config.latencyMs.round()),
    );
  }

  Future<void> simulateBandwidth(Object? body) async {
    await ThrottleEngine.simulate(_config, body: body);
  }

  Future<void> applyNetworkDelay(Object? body) async {
    if (_config.isOffline) {
      return;
    }
    await applyLatency();
    await simulateBandwidth(body);
  }

  Duration estimateDelay({Object? body}) {
    return DelayCalculator.calculateDelay(
      _config,
      bytes: ThrottleEngine.estimateBytes(body),
    );
  }

  bool shouldFail({Random? random}) {
    final failureRandom = random ?? _random;
    return !_config.isOffline &&
        _config.packetLoss > 0 &&
        failureRandom.nextDouble() < _config.packetLoss;
  }

  double _normalizePacketLoss(double value) {
    if (value <= 0) {
      return 0;
    }
    if (value > 1) {
      return (value / 100).clamp(0, 1).toDouble();
    }
    return value.clamp(0, 1).toDouble();
  }
}

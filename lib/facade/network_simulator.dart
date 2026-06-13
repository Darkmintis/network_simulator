import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../interceptor/dio_interceptor.dart';
import '../logger/request_logger.dart';
import '../overlay/overlay.dart';

class NetworkSimulator {
  NetworkSimulator._();

  static final NetworkSimulatorController _controller = NetworkSimulatorController();
  static Dio? _dio;
  static NetworkSimulatorInterceptor? _interceptor;
  static GlobalKey<NavigatorState>? _navigatorKey;

  static NetworkSimulatorController get controller => _controller;
  static NetworkSimulatorLogger get logger => _controller.logger;

  static void init({
    required Dio dio,
    bool enableOverlay = false,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    if (!kDebugMode) return;

    _bindDio(dio);
    _navigatorKey = navigatorKey;

    if (enableOverlay && navigatorKey != null) {
      NetworkSimulatorOverlay.attach(
        controller: _controller,
        navigatorKey: navigatorKey,
      );
    }
  }

  static void enableOverlay() {
    if (!kDebugMode || _navigatorKey == null) return;

    NetworkSimulatorOverlay.attach(
      controller: _controller,
      navigatorKey: _navigatorKey!,
    );
  }

  static void setMode(NetworkMode mode) {
    if (!kDebugMode) return;
    _controller.setMode(mode);
  }

  static void custom({
    double? latencyMs,
    double? bandwidthMbps,
    double? packetLoss,
  }) {
    if (!kDebugMode) return;
    _controller.setCustom(
      latencyMs: latencyMs,
      bandwidthMbps: bandwidthMbps,
      packetLoss: packetLoss,
    );
  }

  static void offline() {
    if (!kDebugMode) return;
    _controller.enableOffline();
  }

  static void reset() {
    if (!kDebugMode) return;
    _controller.reset();
  }

  static void _bindDio(Dio dio) {
    if (_dio != null && _interceptor != null) {
      _dio!.interceptors.remove(_interceptor!);
    }

    _dio = dio;
    _controller.attachDio(dio);

    _interceptor = NetworkSimulatorInterceptor(_controller);
    if (!dio.interceptors.contains(_interceptor)) {
      dio.interceptors.add(_interceptor!);
    }
  }
}

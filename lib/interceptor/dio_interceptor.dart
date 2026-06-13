import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/controller.dart';
import '../models/network_log.dart';

const String _requestStartedAtKey = '_network_simulator_started_at';

class NetworkSimulatorInterceptor extends Interceptor {
  NetworkSimulatorInterceptor(this.controller, {Random? random})
    : _random = random ?? Random();

  final NetworkSimulatorController controller;
  final Random _random;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!kDebugMode) {
      handler.next(options);
      return;
    }

    if (controller.isOffline) {
      final exception = DioException.connectionError(
        requestOptions: options,
        reason: 'NetworkSimulator offline mode is enabled.',
      );
      controller.logger.log(
        _failureLog(options, 0, exception.message ?? 'Offline mode', null),
      );
      handler.reject(exception);
      return;
    }

    if (controller.shouldFail(random: _random)) {
      final exception = DioException.connectionError(
        requestOptions: options,
        reason: 'NetworkSimulator packet loss simulation triggered.',
      );
      controller.logger.log(
        _failureLog(options, 0, exception.message ?? 'Packet loss', null),
      );
      handler.reject(exception);
      return;
    }

    options.extra[_requestStartedAtKey] = DateTime.now().millisecondsSinceEpoch;

    final delay = controller.estimateDelay(body: options.data);
    final connectTimeout = options.connectTimeout;
    if (connectTimeout != null && delay > connectTimeout) {
      final exception = DioException.connectionTimeout(
        requestOptions: options,
        timeout: connectTimeout,
      );
      controller.logger.log(
        _failureLog(
          options,
          delay.inMilliseconds,
          exception.message ?? 'Connection timeout',
          null,
        ),
      );
      handler.reject(exception);
      return;
    }

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    if (!kDebugMode) {
      handler.next(response);
      return;
    }

    final delay = controller.estimateDelay(body: response.data);
    final receiveTimeout = response.requestOptions.receiveTimeout;
    if (receiveTimeout != null && delay > receiveTimeout) {
      final exception = DioException.receiveTimeout(
        requestOptions: response.requestOptions,
        timeout: receiveTimeout,
      );
      controller.logger.log(
        _failureLog(
          response.requestOptions,
          delay.inMilliseconds,
          exception.message ?? 'Receive timeout',
          response.statusCode,
        ),
      );
      handler.reject(exception);
      return;
    }

    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final durationMs = _durationMs(response.requestOptions);
    controller.logger.log(
      NetworkLog(
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        durationMs: durationMs,
        success: true,
        statusCode: response.statusCode,
      ),
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!kDebugMode) {
      handler.next(err);
      return;
    }

    final durationMs = _durationMs(err.requestOptions);
    controller.logger.log(
      _failureLog(
        err.requestOptions,
        durationMs,
        err.message ?? err.error?.toString() ?? 'Request failed',
        err.response?.statusCode,
      ),
    );
    handler.next(err);
  }

  NetworkLog _failureLog(
    RequestOptions options,
    int durationMs,
    String errorMessage,
    int? statusCode,
  ) {
    return NetworkLog(
      method: options.method,
      url: options.uri.toString(),
      durationMs: durationMs,
      success: false,
      statusCode: statusCode,
      errorMessage: errorMessage,
    );
  }

  int _durationMs(RequestOptions options) {
    final startedAt = options.extra[_requestStartedAtKey] as int?;
    if (startedAt == null) {
      return 0;
    }
    return DateTime.now().millisecondsSinceEpoch - startedAt;
  }
}

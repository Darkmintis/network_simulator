import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../overlay/overlay.dart';

/// Static facade for the local VPN network condition simulator.
///
/// All public APIs are no-ops outside [kDebugMode].
class NetworkSimulator {
  NetworkSimulator._();

  static final NetworkSimulatorController _controller =
      NetworkSimulatorController();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _initialized = false;

  static NetworkSimulatorController get controller => _controller;

  /// Initializes the debug simulator. Does not start the VPN.
  ///
  /// [providerBundleIdentifier] is required on iOS (Packet Tunnel extension id).
  static Future<void> init({
    bool enableOverlay = false,
    GlobalKey<NavigatorState>? navigatorKey,
    String? providerBundleIdentifier,
  }) async {
    if (!kDebugMode) return;

    _navigatorKey = navigatorKey;
    _controller.configure(providerBundleIdentifier: providerBundleIdentifier);
    await _controller.bindPlatformListeners();
    _initialized = true;

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

  static Future<bool> isSupported() async {
    if (!kDebugMode) return false;
    return _controller.isSupported();
  }

  static Future<void> startTunnel() async {
    if (!kDebugMode) return;
    _ensureInitialized();
    await _controller.startTunnel();
  }

  static Future<void> stopTunnel() async {
    if (!kDebugMode) return;
    await _controller.stopTunnel();
  }

  static void setMode(NetworkMode mode) {
    if (!kDebugMode) return;
    _controller.setMode(mode);
  }

  static void custom({
    double? latencyMs,
    double? downloadMbps,
    double? uploadMbps,
    double? bandwidthMbps,
    double? jitterMs,
    double? packetLoss,
  }) {
    if (!kDebugMode) return;
    _controller.setCustom(
      latencyMs: latencyMs,
      downloadMbps: downloadMbps,
      uploadMbps: uploadMbps,
      bandwidthMbps: bandwidthMbps,
      jitterMs: jitterMs,
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

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'NetworkSimulator.init() must be called before startTunnel().',
      );
    }
  }
}

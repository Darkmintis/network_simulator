import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/controller.dart';
import '../core/mode.dart';
import '../ui/network_simulator_screen.dart';

/// Static facade for the local VPN network condition simulator.
///
/// All public APIs are no-ops outside [kDebugMode].
class NetworkSimulator {
  NetworkSimulator._();

  static final NetworkSimulatorController _controller =
      NetworkSimulatorController();

  static bool _initialized = false;

  /// Shared controller for advanced integrations.
  static NetworkSimulatorController get controller => _controller;

  /// Initializes the debug simulator. Does not start the VPN.
  ///
  /// [providerBundleIdentifier] is required on iOS (Packet Tunnel extension id).
  static Future<void> init({String? providerBundleIdentifier}) async {
    if (!kDebugMode) return;

    _controller.configure(providerBundleIdentifier: providerBundleIdentifier);
    await _controller.bindPlatformListeners();
    _initialized = true;
  }

  /// Opens the full-screen network simulator UI. Back button or pop to close.
  static Future<void> open(BuildContext context) {
    if (!kDebugMode) return Future.value();
    _ensureInitialized();
    return NetworkSimulatorScreen.open(context, controller: _controller);
  }

  /// Returns whether the current platform supports a local VPN tunnel.
  static Future<bool> isSupported() async {
    if (!kDebugMode) return false;
    return _controller.isSupported();
  }

  /// Requests VPN permission and starts shaping app traffic.
  static Future<void> startTunnel() async {
    if (!kDebugMode) return;
    _ensureInitialized();
    await _controller.startTunnel();
  }

  /// Stops the VPN tunnel and restores normal networking.
  static Future<void> stopTunnel() async {
    if (!kDebugMode) return;
    await _controller.stopTunnel();
  }

  /// Applies a built-in [NetworkMode] preset to the active or next tunnel.
  static void setMode(NetworkMode mode) {
    if (!kDebugMode) return;
    _controller.setMode(mode);
  }

  /// Applies custom shaping values and switches to [NetworkMode.custom].
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

  /// Blocks all traffic through the tunnel (offline simulation).
  static void offline() {
    if (!kDebugMode) return;
    _controller.enableOffline();
  }

  /// Restores the normal (unshaped) preset.
  static void reset() {
    if (!kDebugMode) return;
    _controller.reset();
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'NetworkSimulator.init() must be called before using the simulator.',
      );
    }
  }
}

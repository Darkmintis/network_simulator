import 'dart:async';

import 'package:flutter/foundation.dart';

import '../platform/network_simulator_platform.dart';
import 'config.dart';
import 'mode.dart';
import 'tunnel_stats.dart';
import 'tunnel_status.dart';

/// Owns simulation config and tunnel lifecycle state for the Dart layer.
///
/// Prefer [NetworkSimulator] for app integration; use this class when you need
/// direct access to [ChangeNotifier] updates or custom platform injection.
class NetworkSimulatorController extends ChangeNotifier {
  /// Creates a controller, optionally overriding the platform implementation.
  NetworkSimulatorController({NetworkSimulatorPlatform? platform})
    : _platformOverride = platform;

  final NetworkSimulatorPlatform? _platformOverride;

  NetworkSimulatorPlatform get _platform =>
      _platformOverride ?? NetworkSimulatorPlatform.instance;

  NetworkSimulatorConfig _config = const NetworkSimulatorConfig.normal();
  TunnelStatus _status = TunnelStatus.idle;
  TunnelStats _stats = const TunnelStats.zero();
  String? _lastError;
  String? _providerBundleIdentifier;

  StreamSubscription<TunnelStatus>? _statusSub;
  StreamSubscription<TunnelStats>? _statsSub;
  StreamSubscription<String>? _errorSub;

  /// Active shaping preset.
  NetworkMode get mode => _config.mode;

  /// Current one-way latency in milliseconds.
  double get latencyMs => _config.latencyMs;

  /// Download bandwidth cap in megabits per second.
  double get downloadMbps => _config.downloadMbps;

  /// Upload bandwidth cap in megabits per second.
  double get uploadMbps => _config.uploadMbps;

  /// Average of [downloadMbps] and [uploadMbps] for display.
  double get bandwidthMbps => _config.bandwidthMbps;

  /// Random latency variation in milliseconds.
  double get jitterMs => _config.jitterMs;

  /// Packet loss fraction (0.0–1.0).
  double get packetLoss => _config.packetLoss;

  /// Whether offline mode is active.
  bool get isOffline => _config.isOffline;

  /// Full config snapshot sent to native code on tunnel updates.
  NetworkSimulatorConfig get config => _config;

  /// Latest tunnel lifecycle state from the platform layer.
  TunnelStatus get status => _status;

  /// Latest throughput counters from the platform layer.
  TunnelStats get stats => _stats;

  /// Last error message, if [status] is [TunnelStatus.error].
  String? get lastError => _lastError;

  /// Whether the tunnel is starting or connected.
  bool get isTunnelActive => _status.isActive;

  /// Stores the iOS Packet Tunnel provider bundle identifier.
  void configure({String? providerBundleIdentifier}) {
    _providerBundleIdentifier = providerBundleIdentifier;
  }

  /// Subscribes to native status, stats, and error event streams.
  Future<void> bindPlatformListeners() async {
    await _statusSub?.cancel();
    await _statsSub?.cancel();
    await _errorSub?.cancel();

    _statusSub = _platform.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });
    _statsSub = _platform.statsStream.listen((stats) {
      _stats = stats;
      notifyListeners();
    });
    _errorSub = _platform.errorStream.listen((message) {
      _lastError = message;
      _status = TunnelStatus.error;
      notifyListeners();
    });

    try {
      _status = await _platform.getStatus();
      notifyListeners();
    } catch (_) {
      _status = TunnelStatus.unsupported;
      notifyListeners();
    }
  }

  /// Returns whether the current platform exposes a supported tunnel.
  Future<bool> isSupported() => _platform.isSupported();

  /// Starts the VPN tunnel with the current [config].
  Future<void> startTunnel() async {
    _lastError = null;
    _status = TunnelStatus.preparing;
    notifyListeners();

    try {
      await _platform.startTunnel(
        config: _config,
        providerBundleIdentifier: _providerBundleIdentifier,
      );
      _status = await _platform.getStatus();
      if (_status == TunnelStatus.idle || _status == TunnelStatus.preparing) {
        _status = TunnelStatus.connected;
      }
      notifyListeners();
    } catch (error) {
      _lastError = error.toString();
      _status = TunnelStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Stops the VPN tunnel and resets live stats.
  Future<void> stopTunnel() async {
    _status = TunnelStatus.disconnecting;
    notifyListeners();
    try {
      await _platform.stopTunnel();
      _status = TunnelStatus.idle;
      _stats = const TunnelStats.zero();
      notifyListeners();
    } catch (error) {
      _lastError = error.toString();
      _status = TunnelStatus.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Applies a built-in [NetworkMode] preset.
  void setMode(NetworkMode mode) {
    _config = NetworkSimulatorConfig.forMode(mode);
    notifyListeners();
    _pushConfigIfActive();
  }

  /// Applies custom shaping values and switches to [NetworkMode.custom].
  void setCustom({
    double? latencyMs,
    double? downloadMbps,
    double? uploadMbps,
    double? bandwidthMbps,
    double? jitterMs,
    double? packetLoss,
  }) {
    final down = downloadMbps ?? bandwidthMbps ?? _config.downloadMbps;
    final up = uploadMbps ?? bandwidthMbps ?? _config.uploadMbps;

    _config = _config.copyWith(
      mode: NetworkMode.custom,
      latencyMs: latencyMs ?? _config.latencyMs,
      downloadMbps: down,
      uploadMbps: up,
      jitterMs: jitterMs ?? _config.jitterMs,
      packetLoss: _normalizePacketLoss(packetLoss ?? _config.packetLoss),
      isOffline: false,
    );
    notifyListeners();
    _pushConfigIfActive();
  }

  /// Blocks all traffic by applying the offline preset.
  void enableOffline() {
    _config = const NetworkSimulatorConfig.offline();
    notifyListeners();
    _pushConfigIfActive();
  }

  /// Restores the normal (unshaped) preset and clears the last error.
  void reset() {
    _config = const NetworkSimulatorConfig.normal();
    _lastError = null;
    notifyListeners();
    _pushConfigIfActive();
  }

  void _pushConfigIfActive() {
    if (_status == TunnelStatus.connected ||
        _status == TunnelStatus.connecting) {
      unawaited(_platform.updateConfig(_config));
    }
  }

  double _normalizePacketLoss(double value) {
    if (value <= 0) return 0;
    if (value > 1) return (value / 100).clamp(0, 1).toDouble();
    return value.clamp(0, 1).toDouble();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _statsSub?.cancel();
    _errorSub?.cancel();
    super.dispose();
  }
}

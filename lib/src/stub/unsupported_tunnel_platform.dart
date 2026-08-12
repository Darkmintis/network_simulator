import 'dart:async';

import '../../core/config.dart';
import '../../core/tunnel_stats.dart';
import '../../core/tunnel_status.dart';
import '../../platform/network_simulator_platform.dart';

/// Fallback [NetworkSimulatorPlatform] for platforms without a native VPN tunnel.
class UnsupportedTunnelPlatform extends NetworkSimulatorPlatform {
  UnsupportedTunnelPlatform();

  static final UnsupportedTunnelPlatform instance = UnsupportedTunnelPlatform();

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<TunnelStatus> getStatus() async => TunnelStatus.unsupported;

  @override
  Future<void> startTunnel({
    required NetworkSimulatorConfig config,
    String? providerBundleIdentifier,
  }) {
    throw UnsupportedError(
      'Network simulator tunnel is not available on this platform.',
    );
  }

  @override
  Future<void> stopTunnel() async {}

  @override
  Future<void> updateConfig(NetworkSimulatorConfig config) async {}

  @override
  Stream<TunnelStatus> get statusStream => const Stream<TunnelStatus>.empty();

  @override
  Stream<TunnelStats> get statsStream => const Stream<TunnelStats>.empty();

  @override
  Stream<String> get errorStream => const Stream<String>.empty();
}

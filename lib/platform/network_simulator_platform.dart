import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../core/config.dart';
import '../core/tunnel_stats.dart';
import '../core/tunnel_status.dart';
import 'method_channel_network_simulator.dart';

/// Contract between Dart and native VPN / packet-tunnel implementations.
abstract class NetworkSimulatorPlatform extends PlatformInterface {
  NetworkSimulatorPlatform() : super(token: _token);

  static final Object _token = Object();

  static NetworkSimulatorPlatform _instance = MethodChannelNetworkSimulator();

  static NetworkSimulatorPlatform get instance => _instance;

  static set instance(NetworkSimulatorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isSupported();

  Future<TunnelStatus> getStatus();

  Future<void> startTunnel({
    required NetworkSimulatorConfig config,
    String? providerBundleIdentifier,
  });

  Future<void> stopTunnel();

  Future<void> updateConfig(NetworkSimulatorConfig config);

  Stream<TunnelStatus> get statusStream;

  Stream<TunnelStats> get statsStream;

  Stream<String> get errorStream;
}

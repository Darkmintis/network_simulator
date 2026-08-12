import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:network_simulator/platform/network_simulator_platform.dart';
import 'package:network_simulator/src/stub/unsupported_tunnel_platform.dart';

/// Web plugin registration entry point.
class NetworkSimulatorPluginWeb {
  /// Registers the unsupported web tunnel implementation.
  static void registerWith(Registrar registrar) {
    NetworkSimulatorPlatform.instance = UnsupportedTunnelPlatform.instance;
  }
}

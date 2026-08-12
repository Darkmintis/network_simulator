import 'package:network_simulator/platform/network_simulator_platform.dart';
import 'package:network_simulator/src/stub/unsupported_tunnel_platform.dart';

/// macOS plugin registration entry point.
class NetworkSimulatorPluginMacOS {
  /// Registers the unsupported macOS tunnel implementation.
  static void registerWith() {
    NetworkSimulatorPlatform.instance = UnsupportedTunnelPlatform.instance;
  }
}

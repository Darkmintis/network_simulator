import 'package:network_simulator/platform/network_simulator_platform.dart';
import 'package:network_simulator/src/stub/unsupported_tunnel_platform.dart';

/// Linux plugin registration entry point.
class NetworkSimulatorPluginLinux {
  /// Registers the unsupported Linux tunnel implementation.
  static void registerWith() {
    NetworkSimulatorPlatform.instance = UnsupportedTunnelPlatform.instance;
  }
}

import 'package:network_simulator/platform/network_simulator_platform.dart';
import 'package:network_simulator/src/stub/unsupported_tunnel_platform.dart';

/// Windows plugin registration entry point.
class NetworkSimulatorPluginWindows {
  /// Registers the unsupported Windows tunnel implementation.
  static void registerWith() {
    NetworkSimulatorPlatform.instance = UnsupportedTunnelPlatform.instance;
  }
}

import 'dart:async';

import 'package:network_simulator/network_simulator.dart';
import 'package:network_simulator/platform/network_simulator_platform.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Shared fake platform for unit tests.
class FakeNetworkSimulatorPlatform extends NetworkSimulatorPlatform
    with MockPlatformInterfaceMixin {
  FakeNetworkSimulatorPlatform();

  TunnelStatus status = TunnelStatus.idle;
  NetworkSimulatorConfig? lastConfig;
  int startCount = 0;
  int stopCount = 0;
  int updateCount = 0;
  Object? startError;
  Object? stopError;
  bool supported = true;

  final StreamController<TunnelStatus> statusController =
      StreamController<TunnelStatus>.broadcast();
  final StreamController<TunnelStats> statsController =
      StreamController<TunnelStats>.broadcast();
  final StreamController<String> errorController =
      StreamController<String>.broadcast();

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<TunnelStatus> getStatus() async => status;

  @override
  Future<void> startTunnel({required NetworkSimulatorConfig config}) async {
    startCount++;
    lastConfig = config;
    if (startError != null) {
      throw startError!;
    }
    status = TunnelStatus.connected;
    statusController.add(status);
  }

  @override
  Future<void> stopTunnel() async {
    stopCount++;
    if (stopError != null) {
      throw stopError!;
    }
    status = TunnelStatus.idle;
    statusController.add(status);
  }

  @override
  Future<void> updateConfig(NetworkSimulatorConfig config) async {
    updateCount++;
    lastConfig = config;
  }

  @override
  Stream<TunnelStatus> get statusStream => statusController.stream;

  @override
  Stream<TunnelStats> get statsStream => statsController.stream;

  @override
  Stream<String> get errorStream => errorController.stream;

  Future<void> dispose() async {
    await statusController.close();
    await statsController.close();
    await errorController.close();
  }
}

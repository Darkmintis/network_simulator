import 'dart:async';

import 'package:flutter/services.dart';

import '../core/config.dart';
import '../core/tunnel_stats.dart';
import '../core/tunnel_status.dart';
import 'network_simulator_platform.dart';

/// MethodChannel + EventChannel bridge to the Android VPN tunnel.
class MethodChannelNetworkSimulator extends NetworkSimulatorPlatform {
  MethodChannelNetworkSimulator({
    MethodChannel? methodChannel,
    EventChannel? statusChannel,
    EventChannel? statsChannel,
    EventChannel? errorChannel,
  }) : _methodChannel =
           methodChannel ?? const MethodChannel('network_simulator/tunnel'),
       _statusChannel =
           statusChannel ??
           const EventChannel('network_simulator/tunnel_status'),
       _statsChannel =
           statsChannel ?? const EventChannel('network_simulator/tunnel_stats'),
       _errorChannel =
           errorChannel ??
           const EventChannel('network_simulator/tunnel_errors');

  final MethodChannel _methodChannel;
  final EventChannel _statusChannel;
  final EventChannel _statsChannel;
  final EventChannel _errorChannel;

  @override
  Future<bool> isSupported() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<TunnelStatus> getStatus() async {
    try {
      final raw = await _methodChannel.invokeMethod<String>('getStatus');
      return TunnelStatus.parse(raw);
    } on MissingPluginException {
      return TunnelStatus.unsupported;
    }
  }

  @override
  Future<void> startTunnel({required NetworkSimulatorConfig config}) {
    return _methodChannel.invokeMethod<void>('startTunnel', <String, dynamic>{
      'config': config.toPlatformMap(),
    });
  }

  @override
  Future<void> stopTunnel() {
    return _methodChannel.invokeMethod<void>('stopTunnel');
  }

  @override
  Future<void> updateConfig(NetworkSimulatorConfig config) {
    return _methodChannel.invokeMethod<void>(
      'updateConfig',
      config.toPlatformMap(),
    );
  }

  @override
  Stream<TunnelStatus> get statusStream {
    return _statusChannel.receiveBroadcastStream().map(
      (event) => TunnelStatus.parse(event?.toString()),
    );
  }

  @override
  Stream<TunnelStats> get statsStream {
    return _statsChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return TunnelStats.fromMap(event);
      }
      return const TunnelStats.zero();
    });
  }

  @override
  Stream<String> get errorStream {
    return _errorChannel.receiveBroadcastStream().map(
      (event) => event?.toString() ?? 'Unknown tunnel error',
    );
  }
}

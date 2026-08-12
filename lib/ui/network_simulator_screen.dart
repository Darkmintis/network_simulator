import 'package:flutter/material.dart';

import '../core/controller.dart';
import 'network_simulator_panel.dart';
import 'network_simulator_theme.dart';

/// Full-screen debug UI for tunnel controls and network presets.
///
/// Push with [NetworkSimulatorScreen.open] or the system back button to close.
class NetworkSimulatorScreen extends StatelessWidget {
  /// Creates the simulator screen bound to [controller].
  const NetworkSimulatorScreen({super.key, required this.controller});

  /// Controller that owns tunnel state and shaping config.
  final NetworkSimulatorController controller;

  /// Opens the simulator as a full-screen route. Pop to close.
  static Future<void> open(
    BuildContext context, {
    required NetworkSimulatorController controller,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NetworkSimulatorScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: NetworkSimulatorTheme.dark(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NetworkSimulatorTheme.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  color: NetworkSimulatorTheme.accentSoft,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Network Simulator'),
            ],
          ),
        ),
        body: NetworkSimulatorPanel(controller: controller),
      ),
    );
  }
}

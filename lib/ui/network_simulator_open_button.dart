import 'package:flutter/material.dart';

import '../core/controller.dart';
import 'network_simulator_screen.dart';

/// Button that opens the full-screen [NetworkSimulatorScreen].
class NetworkSimulatorOpenButton extends StatelessWidget {
  /// Creates a launcher button for [controller]'s simulator UI.
  const NetworkSimulatorOpenButton({
    super.key,
    required this.controller,
    this.label = 'Network Simulator',
    this.icon = Icons.wifi_tethering,
  });

  /// Controller that owns tunnel state and shaping config.
  final NetworkSimulatorController controller;

  /// Button label.
  final String label;

  /// Leading icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => NetworkSimulatorScreen.open(
        context,
        controller: controller,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

import 'package:flutter/material.dart';

import '../facade/network_simulator.dart';

/// App-bar icon that opens the network simulator debug screen.
///
/// Add to your debug menu or `AppBar.actions`. Requires [NetworkSimulator.init].
class NetworkSimulatorLauncherIcon extends StatelessWidget {
  /// Creates an icon button that opens [NetworkSimulator.open].
  const NetworkSimulatorLauncherIcon({
    super.key,
    this.icon = Icons.wifi_tethering_rounded,
    this.tooltip = 'Network Simulator',
  });

  /// Icon shown in the app bar.
  final IconData icon;

  /// Long-press / hover tooltip.
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => NetworkSimulator.open(context),
    );
  }
}

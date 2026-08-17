/// Real network condition simulation for Flutter debug builds.
///
/// Shapes app traffic through a local **Android** VPN tunnel using latency,
/// jitter, bandwidth caps, packet loss, and offline presets.
///
/// ```dart
/// await NetworkSimulator.init();
/// // Add NetworkSimulatorLauncherIcon() to your debug AppBar, then:
/// await NetworkSimulator.open(context);
/// await NetworkSimulator.startTunnel();
/// NetworkSimulator.setMode(NetworkMode.slow3G);
/// ```
library;

export 'src/network_simulator.dart';

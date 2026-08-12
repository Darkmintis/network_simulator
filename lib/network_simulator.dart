/// Real network condition simulation for Flutter debug builds.
///
/// Shapes app traffic through a local VPN tunnel on Android and iOS using
/// latency, jitter, bandwidth caps, packet loss, and offline presets.
///
/// ```dart
/// await NetworkSimulator.init(
///   enableOverlay: true,
///   navigatorKey: navigatorKey,
/// );
/// await NetworkSimulator.startTunnel();
/// NetworkSimulator.setMode(NetworkMode.slow3G);
/// ```
library;

export 'src/network_simulator.dart';

# Network Simulator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter **debug** plugin that simulates real-world network conditions through a **local VPN tunnel** — not fake HTTP delays.

**Supported platforms: Android and iOS only.** Web, Windows, macOS, and Linux are not supported.

**Repository:** [github.com/Darkmintis/network_simulator](https://github.com/Darkmintis/network_simulator)

```bash
flutter pub add network_simulator
```

## Features

- **Real traffic shaping** via Android `VpnService` / iOS `NEPacketTunnelProvider`
- Latency, jitter, download/upload bandwidth, packet loss, offline
- Presets: `normal`, `slow2G`, `slow3G`, `fast3G`, `unstable4G`, `offline`
- Floating debug overlay with live tunnel stats
- App-scoped on Android (only your Flutter app is shaped)
- Zero effect in release builds by default (`kDebugMode`)

| Platform | Status |
|----------|--------|
| Android | Supported |
| iOS | Experimental / needs device testing — see [doc/ios-wip.md](doc/ios-wip.md) |

## Usage

```dart
import 'package:network_simulator/network_simulator.dart';

final navigatorKey = GlobalKey<NavigatorState>();

await NetworkSimulator.init(
  enableOverlay: true,
  navigatorKey: navigatorKey,
  // iOS only — Packet Tunnel extension bundle id
  providerBundleIdentifier: 'com.example.app.NetworkSimulatorTunnel',
);

// Explicit opt-in — never auto-starts
await NetworkSimulator.startTunnel();

NetworkSimulator.setMode(NetworkMode.slow3G);
NetworkSimulator.custom(
  latencyMs: 500,
  downloadMbps: 1,
  uploadMbps: 0.5,
  jitterMs: 40,
  packetLoss: 0.1,
);
NetworkSimulator.offline();
await NetworkSimulator.stopTunnel();
NetworkSimulator.reset();
```

On Android the system VPN permission dialog appears once. While the tunnel is running you will see a foreground notification and a VPN indicator.

## Profiles

| Profile | Latency | Download | Upload | Loss | Jitter |
|---------|---------|----------|--------|------|--------|
| normal | 0 | unlimited | unlimited | 0% | 0 |
| slow2G | 2000 ms | 0.1 Mbps | 0.05 Mbps | 20% | 300 ms |
| slow3G | 800 ms | 0.5 Mbps | 0.25 Mbps | 10% | 150 ms |
| fast3G | 300 ms | 1.5 Mbps | 0.75 Mbps | 3% | 50 ms |
| unstable4G | 120 ms | 4 Mbps | 2 Mbps | 15% | 80 ms |
| offline | — | 0 | 0 | 100% | — |

## Requirements

- Flutter `3.44.1` (pinned via [FVM](https://fvm.app) — run `fvm use`)
- Dart `^3.12.0`
- Android: `compileSdk` / `targetSdk` **36**, `minSdk` 24+, Gradle **8.14**, AGP **8.13.0**
- iOS 13+ with Network Extension entitlements ([doc/ios-setup.md](doc/ios-setup.md))

```bash
fvm install 3.44.1
fvm use 3.44.1
fvm flutter pub get
cd example && fvm flutter run -d android
```

## Architecture

See [doc/ARCHITECTURE.md](doc/ARCHITECTURE.md).

## Example

```bash
cd example
flutter run -d android
```

Use the overlay to start the tunnel, pick Slow 3G, then hit any HTTP endpoint in the demo.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). iOS forwarder help is especially welcome.

## License

MIT

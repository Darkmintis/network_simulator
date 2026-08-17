# Network Simulator

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter **debug** plugin that simulates real-world network conditions through a **local Android VPN tunnel** - not fake HTTP delays.

**Supported platform: Android only.** iOS, web, Windows, macOS, and Linux are not supported.

**Repository:** [github.com/Darkmintis/network_simulator](https://github.com/Darkmintis/network_simulator)

```bash
flutter pub add network_simulator
```

## Features

- **Real traffic shaping** via Android `VpnService` + userspace TCP/UDP NAT
- Latency, jitter, download/upload bandwidth, packet loss, offline
- Presets: `normal`, `slow2G`, `slow3G`, `fast3G`, `unstable4G`, `offline`
- Full-screen debug UI via `NetworkSimulatorLauncherIcon`
- App-scoped VPN (only your Flutter app is shaped)
- Zero effect in release builds by default (`kDebugMode`)

## Usage

```dart
import 'package:network_simulator/network_simulator.dart';

await NetworkSimulator.init();

// AppBar: const NetworkSimulatorLauncherIcon()
await NetworkSimulator.open(context);

NetworkSimulator.setMode(NetworkMode.slow3G);
await NetworkSimulator.startTunnel();
await NetworkSimulator.stopTunnel();
NetworkSimulator.reset();
```

The system VPN permission dialog appears once. While the tunnel is running you will see a foreground notification and a VPN indicator.

## Profiles

| Profile | Latency | Download | Upload | Loss | Jitter |
|---------|---------|----------|--------|------|--------|
| normal | 0 | unlimited | unlimited | 0% | 0 |
| slow2G | 2000 ms | 0.1 Mbps | 0.05 Mbps | 20% | 300 ms |
| slow3G | 800 ms | 0.5 Mbps | 0.25 Mbps | 10% | 150 ms |
| fast3G | 300 ms | 1.5 Mbps | 0.75 Mbps | 3% | 50 ms |
| unstable4G | 120 ms | 4 Mbps | 2 Mbps | 15% | 80 ms |
| offline | - | 0 | 0 | 100% | - |

## Requirements

- Flutter `3.44.1` (pinned via [FVM](https://fvm.app) - run `fvm use`)
- Dart `^3.12.0`
- Android: `compileSdk` / `targetSdk` **36**, `minSdk` 24+, Gradle **8.14**, AGP **8.13.0**

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

Open the simulator from the app-bar wifi icon, start the tunnel (Normal), then hit any HTTP endpoint in the demo. Switch to Slow 3G / Offline to verify shaping.

## Known limitations

- Android only (IPv4 TCP/UDP; ICMP dropped in the MVP stack)
- IPv6 traffic is not shaped (VPN is IPv4)
- Debug builds only by default

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT

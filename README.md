# Network Simulator

[![pub.dev](https://img.shields.io/pub/v/network_simulator.svg)](https://pub.dev/packages/network_simulator)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter developer tool that simulates real-world network conditions by intercepting Dio requests inside your app.

```bash
flutter pub add network_simulator
```

## Features

- **Dio interceptor** — hooks into every request/response/error automatically
- **Latency & bandwidth** — simulate slow connections with configurable delay
- **Packet loss** — randomly fail requests at a set probability
- **Offline mode** — instantly block all requests
- **Predefined profiles** — `normal`, `slow2G`, `slow3G`, `fast3G`, `unstable4G`, `offline`
- **Floating debug overlay** — WiFi button opens a live control panel
- **Request logger** — view method, URL, timing and status in-app

## Usage

```dart
import 'package:network_simulator/network_simulator.dart';

final dio = Dio();
final navigatorKey = GlobalKey<NavigatorState>();

NetworkSimulator.init(
  dio: dio,
  enableOverlay: true,
  navigatorKey: navigatorKey,
);

// Switch profiles at runtime
NetworkSimulator.setMode(NetworkMode.slow3G);
NetworkSimulator.custom(latencyMs: 500, bandwidthMbps: 1, packetLoss: 0.1);
NetworkSimulator.offline();
NetworkSimulator.reset();
```

The interceptor is automatically wired — every request through your `Dio` instance gets simulated. Works only in debug mode and has zero impact on release builds.

## Profiles

| Profile | Latency | Bandwidth | Packet loss |
|---|---|---|---|
| normal | 0 ms | unlimited | 0% |
| slow2G | 2000 ms | 0.1 Mbps | 20% |
| slow3G | 800 ms | 0.5 Mbps | 10% |
| fast3G | 300 ms | 1.5 Mbps | 3% |
| unstable4G | 120 ms | 4.0 Mbps | 15% |
| offline | — | — | 100% |

## Requirements

- Dart `>=3.0.0 <4.0.0`
- Flutter `>=3.10.0`
- Dio `^5.7.0`

## Example

See the [`example/`](example/) directory for a complete app with login and user-fetching requests.

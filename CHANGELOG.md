# Changelog

## 0.1.0

- Android-only local VPN traffic shaper for Flutter debug builds
- `VpnService` app-scoped tunnel, userspace TCP/UDP NAT, traffic shaper
- Latency, jitter, download/upload bandwidth, packet loss, offline presets
- Full-screen debug UI via `NetworkSimulatorLauncherIcon`
- Hardened TCP handshake, MTU-safe segments, pipeline lifecycle, and allowlist safety
- Tooling: FVM Flutter `3.44.1`, Gradle `8.14`, AGP `8.13.0`, `compileSdk`/`targetSdk` `36`
- Package metadata: https://github.com/Darkmintis/network_simulator

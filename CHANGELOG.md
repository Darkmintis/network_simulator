# Changelog

## 0.1.0

- Initial development release: local VPN traffic shaper for Flutter debug builds
- Android: `VpnService` app-scoped tunnel, userspace TCP/UDP NAT, traffic shaper
- iOS: MethodChannel + `NETunnelProviderManager` + Packet Tunnel scaffolding (experimental)
- Latency, jitter, download/upload bandwidth, packet loss, offline presets
- Floating debug overlay with live tunnel stats
- Tooling: FVM Flutter `3.44.1`, Gradle `8.14`, AGP `8.13.0`, `compileSdk`/`targetSdk` `36`
- Package metadata: https://github.com/Darkmintis/network_simulator

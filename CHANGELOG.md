## 0.1.0

- Initial release
- Dio interceptor for request interception
- Network simulation engine (latency, bandwidth, packet loss, timeout, offline)
- Predefined profiles (normal, slow2G, slow3G, fast3G, unstable4G, offline, custom)
- Floating debug overlay with control panel
- Live request logger
- Minimal public API: `NetworkSimulator.init()`, `setMode()`, `custom()`, `offline()`, `reset()`

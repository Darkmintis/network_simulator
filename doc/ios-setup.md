# iOS setup

iOS requires a **Network Extension** target in the **host app**. Flutter plugins cannot run `NEPacketTunnelProvider` inside the Runner process.

## Checklist

1. Paid Apple Developer account
2. App ID + extension App ID with:
   - Network Extensions → Packet Tunnel
   - Personal VPN
   - App Groups (shared between app and extension)
3. In Xcode for the host/example app:
   - File → New → Target → Network Extension → Packet Tunnel
   - Name e.g. `NetworkSimulatorTunnel`
   - Bundle id e.g. `com.example.networkSimulator.NetworkSimulatorTunnel`
4. Add [example/ios/NetworkSimulatorTunnel/PacketTunnelProvider.swift](../example/ios/NetworkSimulatorTunnel/PacketTunnelProvider.swift)
5. Copy entitlements from `NetworkSimulatorTunnel.entitlements`
6. Enable the same Network Extension + App Group capabilities on **Runner**
7. Pass the extension bundle id into Dart:

```dart
await NetworkSimulator.init(
  providerBundleIdentifier: 'com.example.networkSimulator.NetworkSimulatorTunnel',
);
await NetworkSimulator.open(context);
await NetworkSimulator.startTunnel();
```

## Status

Android is the supported path. iOS tunnel code is present but **experimental / needs device testing**.

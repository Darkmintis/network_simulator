# Architecture

`network_simulator` is a Flutter **plugin** that simulates real-world network conditions using a **local VPN / packet tunnel**. It does **not** fake HTTP delays in Dart.

## Goals

- Shape real device traffic for the host Flutter app (latency, jitter, loss, bandwidth, offline)
- Debug / testing only (`kDebugMode` + explicit `startTunnel()`)
- Android: supported local `VpnService`
- iOS: experimental `NEPacketTunnelProvider` (needs device testing)

## Layers

```
Dart facade (NetworkSimulator)
  → NetworkSimulatorController (config + status)
  → NetworkSimulatorPlatform / MethodChannel
       → Android VpnService + LocalForwardingPipeline + TrafficShaper
       → iOS TunnelManager + PacketTunnelProvider + NetworkConditionShaper
```

## OOP boundaries

| Type | Role |
|------|------|
| `TrafficShaper` / `NetworkConditionShaper` | Apply network conditions |
| `PacketPipeline` / `LocalForwardingPipeline` | TUN read/write orchestration |
| `TcpSessionManager` / `UdpSessionManager` | Userspace NAT sessions |
| `SocketProtector` | Prevent VPN routing loops |
| `TunnelMethodHandler` | Platform channel adapter |
| `NetworkSimulatorController` | Dart state owner |

## Shared config contract

Native sides accept the same map:

- `mode`, `latencyMs`, `downloadMbps`, `uploadMbps`, `jitterMs`, `packetLoss`, `isOffline`
- Unlimited bandwidth is encoded as `-1`

## Android flow

1. `VpnService.prepare()` consent
2. Foreground `NetworkSimulatorVpnService`
3. TUN with `addAllowedApplication(hostPackage)` (app-scoped)
4. Parse IPv4 → TCP/UDP session managers → protected sockets
5. Shape upload/download independently

## iOS flow

1. Host app provides Packet Tunnel extension + entitlements
2. `NETunnelProviderManager` starts provider
3. Provider applies shaper; **full userspace forwarder is WIP**

See [ios-setup.md](ios-setup.md) and [ios-wip.md](ios-wip.md).

## Safety

- No-op outside `kDebugMode`
- Never auto-starts VPN in `init`
- Shows as a system VPN while active

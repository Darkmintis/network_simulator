# iOS WIP — help wanted

The iOS tunnel compiles as scaffolding and channel wiring, but **has not been validated on a real device** in this repository.

## Done

- Dart ↔ MethodChannel parity with Android
- `TunnelManager` using `NETunnelProviderManager`
- `NetworkConditionShaper` (latency / jitter / loss / bandwidth / offline)
- Example `PacketTunnelProvider` + entitlements templates
- Setup docs

## Needs contributor work

1. **Userspace forwarder** — current provider shapes then writes packets back; that is not a real NAT. Port the Android approach (`TcpSessionManager` / `UdpSessionManager`) using `NWConnection` / BSD sockets that bypass the tunnel.
2. **App Group config sync** — optional live updates via App Group + provider message (partially started).
3. **Xcode project wiring** — add the extension target to `example/ios/Runner.xcodeproj` on a Mac.
4. **Device test matrix** — Slow 3G, offline, HTTPS, WebSocket, DNS.
5. **Split tunneling / per-app** — iOS per-app VPN has MDM constraints; document limits.

## How to contribute

1. Read [ios-setup.md](ios-setup.md) and [ARCHITECTURE.md](ARCHITECTURE.md)
2. Match Android shaper semantics exactly
3. Open a PR with device logs + test checklist results

Label issues with `platform:ios` and `help wanted`.

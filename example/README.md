# Example

Demonstrates the real local-VPN network simulator.

```bash
flutter run -d android
```

1. Tap **Start tunnel** (or use the floating overlay) and accept the VPN permission.
2. Choose **Slow 3G** from the app bar or overlay.
3. Tap **GET /posts** — the request should feel slow under real shaping.

## iOS

iOS needs a Packet Tunnel extension target. Sources live in
`ios/NetworkSimulatorTunnel/` — see `../../docs/ios-setup.md`.
The extension is not fully wired in this example project yet (Mac/Xcode required).

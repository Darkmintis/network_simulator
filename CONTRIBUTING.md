# Contributing

Thanks for helping with **network_simulator**.

## Project direction

- Real local VPN traffic shaping only (no fake Dio delays)
- **Android and iOS only** — no web/desktop support
- Android is the supported reference implementation
- iOS is experimental — see [doc/ios-wip.md](doc/ios-wip.md)

## Development

```bash
fvm install 3.44.1
fvm use 3.44.1
fvm flutter pub get
cd example && fvm flutter pub get
fvm flutter test
cd example && fvm flutter run -d android
```

Android targets Play Console standards: `targetSdk`/`compileSdk` 36, Gradle 8.14, AGP 8.13.0.

## Design rules

- Prefer strict OOP: interfaces for shaper, pipeline, socket protection, platform bridge
- Keep Dart free of packet loops — native owns shaping
- Preserve the shared config map contract across Android and iOS
- Debug-only by default (`kDebugMode`)

## Pull requests

- Include a short test plan (Android emulator/device steps)
- For iOS changes, note entitlements and whether device-tested
- Do not commit secrets or provisioning profiles

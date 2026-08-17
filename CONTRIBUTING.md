# Contributing

Thanks for helping with **network_simulator**.

## Project direction

- Real local VPN traffic shaping only (no fake Dio delays)
- **Android only** - no iOS, web, or desktop support
- Debug-only by default (`kDebugMode`)

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
- Keep Dart free of packet loops - native owns shaping
- Preserve the shared config map contract on Android
- Never establish the VPN without a successful host-app allowlist

## Pull requests

- Include a short test plan (Android emulator/device steps)
- Prefer adding Dart and Android unit tests with behavior changes
- Do not commit secrets

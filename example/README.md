# Example

Demonstrates the Android local-VPN network simulator.

```bash
flutter run -d android
```

1. Tap the wifi icon in the app bar to open the simulator.
2. Tap **Start tunnel** and accept the VPN permission.
3. Leave **Normal** selected and tap **GET /posts** - the request should succeed.
4. Switch to **Slow 3G** or **Offline** and retry to verify shaping.

Android only. This package does not support iOS.

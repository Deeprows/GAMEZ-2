# Neon Velocity — Flutter 3D-style Racing Game

A mobile-first arcade racer built with Flutter + Flame. The road uses a perspective renderer to create a 3D-style racing view without external 3D assets.

## Features
- Perspective highway, neon skyline, road markings and glow effects
- Three-lane steering, traffic cars and collision detection
- Nitro boost with rechargeable meter
- Speed/distance HUD, pause, crash screen and replay
- No paid assets or API keys

## Run locally
```bash
flutter create . --platforms=android
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions
Push to `main` or run **Build Android APK** manually. The workflow generates Android platform files if needed, runs `flutter analyze`, builds the release APK and uploads it as `neon-velocity-apk`.

## Controls
- Left/right: steer between lanes
- Hold Nitro: temporary speed boost
- Pause: pause/resume

## Technical note
This is a 3D-style perspective racer rendered with Flutter Canvas and Flame, not a full polygonal 3D engine.

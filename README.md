# Neon Velocity — Racing Championship

A mobile-first Flutter + Flame arcade racer with a 3D-style perspective road and a full championship progression loop.

## Features
- **Car garage:** four selectable cars, unlock prices, colour identities and performance stats (top speed, acceleration, handling).
- **Four environments:** Neon City, Desert Run, Green Valley and Midnight Circuit.
- **Driving mechanics:** gas, brake, lane steering, drift, turbo boost, rechargeable nitro and speedometer HUD.
- **Career mode:** championship levels, race wins, coin rewards, best distance and unlockable cars.
- **Progress saved locally:** coins, level, selected/unlocked cars and records persist using SharedPreferences.
- Pause, collision, race completion and replay flows.

## Run
```bash
flutter pub get
flutter run
```

## Android release
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Actions
Push to `main` or manually run **Build Android APK**. The workflow creates Android platform files, installs packages, runs Dart analysis, builds a release APK and uploads the `neon-velocity-apk` artifact.

## Controls
- LEFT / RIGHT: steer
- GAS: accelerate
- BRAKE: slow down
- DRIFT: initiate drift and recharge turbo faster
- TURBO: hold for a burst of speed

## Rendering note
The game uses Flame for the real-time game loop and Flutter Canvas for a lightweight perspective 3D-style renderer. The scenery and cars are procedural; no external assets or API keys are required.

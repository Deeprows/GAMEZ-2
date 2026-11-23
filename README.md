# Neon Velocity — Racing Championship

A mobile-first Flutter + Flame arcade racer with a real pseudo-3D road engine (curves, hills, fog, traffic, lap racing) and a full championship progression loop.

## What's new in 2.0
- **Real road engine:** segment-based 3D road with curves, hills, fog, rumble strips, barriers, lap start/finish gantry and four unique closed-loop circuits.
- **Real racing:** multi-lap races, race countdown, live position, lap timer and best lap, damage model, wall and car collisions, slipstream and near-miss nitro bonuses.
- **Real traffic and rivals:** lane-changing traffic, rivals that avoid traffic, take racing lines and rubber-band by difficulty.
- **Detailed cars:** six procedural car bodies with tail lights, brake lights, exhausts, boost flames, wings and underglow.
- **Atmosphere:** parallax skylines/mountains, sun/moon/stars, speed lines, FOV kick on nitro, camera shake, tyre smoke, sparks.
- **Sound:** engine that follows RPM and gears, crash, nitro, countdown and lap sounds (generated `assets/audio/*.wav`).
- **HUD:** analogue speedometer with RPM arc and gear, nitro and damage bars, position and lap panel.

## Features
- **Car garage:** four selectable cars, unlock prices, colour identities and performance stats (top speed, acceleration, handling).
- **Four environments:** Neon City, Desert Run, Green Valley and Midnight Circuit.
- **Driving mechanics:** gas, brake, lane steering, drift, turbo boost, rechargeable nitro and speedometer HUD.
- **Race modes:** free drive, three-rival AI races (Rookie / Pro / Elite), and real-time online 1v1 matchmaking.
- **AI opponents:** three named rival drivers change lanes and race against your progress.
- **Career mode:** championship levels, race wins, coin rewards, best distance and unlockable cars.
- **Online multiplayer:** WebSocket matchmaking and live opponent position updates using the included Node.js server.
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

## Online multiplayer server

The online mode needs a deployed WebSocket server. This repository includes a lightweight matchmaking/state-relay server and a Render deployment blueprint (`render.yaml`).

1. Deploy this repository as a Render web service, or run the server yourself with `npm install && npm start`.
2. The server listens on the `PORT` environment variable (default `8080`).
3. In the game, open **Race Modes → Online Multiplayer**, enter the server WebSocket URL (`wss://...` for a hosted service), choose a racer name and tap **Find an Opponent**.
4. Keep two game clients connected to the same server to be paired. The server relays opponent position updates; it does not store accounts or rankings.

For local testing, use `ws://10.0.2.2:8080` from the Android emulator or your computer's LAN address from a physical phone. Do not use `localhost` on a phone.

## Controls
- LEFT / RIGHT: steer (hold). Accelerator is automatic.
- BRAKE: slow down
- DRIFT: hold while steering to slide through corners and recharge nitro
- NITRO: hold for a burst of speed
- Keyboard: arrows / A D steer, S brake, Space nitro, Shift drift, P / Esc pause

## Rendering note
The game uses Flame for the real-time game loop and Flutter Canvas for a segment-projection pseudo-3D renderer. Cars, scenery and skies are procedural. Only the small WAV sound files in `assets/audio/` are bundled; no API keys are required.

# Neon Velocity — Racing Championship

A mobile-first Flutter + Flame arcade racer with a 3D-style perspective road and a full championship progression loop.

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
- LEFT / RIGHT: steer
- GAS: accelerate
- BRAKE: slow down
- DRIFT: initiate drift and recharge turbo faster
- TURBO: hold for a burst of speed

## Rendering note
The game uses Flame for the real-time game loop and Flutter Canvas for a lightweight perspective 3D-style renderer. The scenery and cars are procedural; no external assets or API keys are required.

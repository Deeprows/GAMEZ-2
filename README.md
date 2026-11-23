# GAMEZ-2 — Neon Velocity

Neon Velocity is a mobile-first 3D racing game powered by the Godot 4 engine. The Godot project at the repository root is the primary game and Android app.

## Game flow

When the app opens, it shows the main championship menu. From there you can:

- Start a race.
- Choose and unlock cars in the garage.
- Select Neon City, Desert Run, Green Valley or Midnight Circuit.
- Choose Free Drive or race against three AI opponents.
- Set Rookie, Pro or Elite AI difficulty.
- View career level, wins, coins, best distance and best lap.
- Connect to the included WebSocket matchmaking server for online 1v1 races.

The 3D engine uses the supplied GLB car models, PBR textures, physics-based vehicle, procedural tracks, touch controls, nitro, drift, AI rivals and persistent career progress.

## Android

- Landscape orientation is forced for Android.
- Package: `com.deeprows.gamez2`
- App name: `Neon Velocity`
- One GitHub Actions workflow builds the Android APK: **Build Android APK**.
- The workflow uploads one artifact named `neon-velocity-apk`.

To download the APK, open the successful **Build Android APK** run in GitHub Actions, then download the `neon-velocity-apk` artifact and extract the APK from the ZIP.

## Build locally

1. Install Godot 4.3 or newer.
2. Install the matching Android export templates.
3. Configure the Android SDK and JDK in Godot Editor Settings.
4. Open this repository root in Godot.
5. Select the Android export preset and export the project.

The automated GitHub workflow performs the Android SDK setup, imports the project and creates a debug APK.

## Online multiplayer

The Node.js matchmaking relay remains in `server/`. Deploy the included service (Render blueprint: `render.yaml`) and enter its secure WebSocket URL (`wss://...`) in **Race Modes → Online Multiplayer**. Two clients must connect to the same server to be paired. The server relays player progress and does not store accounts or rankings.

## Validation

The separate **Godot 4 project validation** workflow verifies the supplied car and texture assets, imports the project, parses GDScript and performs a headless startup smoke test. A successful headless check is not a substitute for testing the Android APK on a physical phone.

## Repository contents

- `project.godot`, `scenes/`, `scripts/`: primary Godot 3D game.
- `assets/cars/`, `assets/textures/`, `assets/audio/`: game assets.
- `server/`, `render.yaml`, `package.json`: online matchmaking service.
- `.github/workflows/build.yml`: the single Android APK build.
- `.github/workflows/godot-validation.yml`: project validation only.

# GAMEZ-2 — Neon Velocity 3D (Godot 4 migration branch)

This branch adds the Godot 4 3D racing engine from the supplied upgrade ZIPs while keeping the original Flutter + Flame project files in the repository. The `main` branch is unchanged and remains the rollback point.

## Open the Godot game

1. Install Godot 4.3 or newer.
2. Open the repository root (the folder containing `project.godot`) in Godot Project Manager.
3. Allow Godot to scan and import the project, then run `scenes/main.tscn` (F6) or the project (F5).
4. The project uses the Compatibility renderer for broader mobile GPU support.

## Engine work included

- Physics-driven 3D player vehicle using `VehicleBody3D` and four `VehicleWheel3D` wheels.
- Procedurally generated closed-loop 3D circuit, collision geometry, lane markings, curbs, barriers and scenery.
- Four environment themes: Neon City, Desert Run, Green Valley and Midnight Circuit.
- Mobile touch steering, brake, drift and nitro HUD; desktop keyboard controls.
- Four-car garage catalogue, local career persistence, race rewards and collision damage.
- Three AI opponents with Rookie / Pro / Elite difficulty, lane changes and overtake behavior.
- WebSocket client using the existing join/state/finish/leave message protocol.

## Controls

- A / Left and D / Right: steer
- S / Down: brake
- Space: nitro
- Shift: drift
- Escape: pause
- Touchscreen: on-screen steering, brake, drift and nitro buttons

## Supplied assets

All 20 binary assets from the supplied upgrade ZIP are present on this branch:
- 4 GLB car models in `assets/cars/`
- 16 PBR PNG maps (albedo, roughness, normal and AO for asphalt, concrete, grass and sand) in `assets/textures/`

See [assets/README.md](assets/README.md) for the exact inventory. Procedural car and material fallbacks remain if an optional asset cannot be loaded.

## Multiplayer server

The original Node.js server remains under `server/`. Set the multiplayer WebSocket URL in the game before connecting. The Godot client uses the same basic `join`, `state`, `finish` and `leave` message types. A real two-device connection test is still required.

## Android export

Android export has not yet been configured or tested. In Godot, install the matching export templates, configure the Android SDK and JDK in Editor Settings, add an Android export preset, and create a debug APK. Test that APK on a physical Android device in landscape mode before preparing a release. Never commit signing keys.

## Validation status

The GitHub Actions workflow `.github/workflows/godot-validation.yml` has passed:
- Verified the expected 4 GLB and 16 PNG assets.
- Imported the project in headless Godot 4.3 and validated GDScript parsing.
- Completed a headless game startup smoke test.

These checks do not replace desktop gameplay or physical Android testing. Vehicle handling, camera behavior, touch controls, garage interaction, AI behavior, multiplayer connectivity, mobile performance and Android export still require hands-on testing. Keep the pull request unmerged until those checks are completed.

## Original Flutter project

The Flutter + Flame source remains available in the same repository tree. This migration adds a Godot project at the repository root; it does not replace the original implementation on `main`.

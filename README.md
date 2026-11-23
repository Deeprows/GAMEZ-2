# GAMEZ-2 — Neon Velocity 3D (Godot 4 migration branch)

This branch adds the Godot 4 real-time 3D racing engine from the supplied migration and Milestone 2 ZIPs. The original Flutter + Flame project files remain in their existing locations on this branch; the `main` branch is unchanged and remains the rollback point.

## Open the Godot game

1. Install Godot 4.3 or newer.
2. Open the repository root (the folder containing `project.godot`) in Godot Project Manager.
3. Allow Godot to scan/import the project, then run `scenes/main.tscn` (F6) or the project (F5).
4. The project uses the Compatibility renderer for broader mobile GPU support.

## Engine work included

- Physics-driven 3D player vehicle using `VehicleBody3D` and four `VehicleWheel3D` wheels.
- Procedurally generated closed-loop 3D circuit, collision geometry, lane markings, curbs and barriers.
- Four environment themes: Neon City, Desert Run, Green Valley and Midnight Circuit.
- Mobile touch steering, brake, drift and nitro HUD; desktop keyboard controls.
- Four-car garage catalogue with original Street R / Blaze GT / Phantom X / Volt RS names and 0 / 350 / 700 / 1100 coin prices.
- Local career and garage persistence, race rewards and collision damage.
- Three AI opponents with Rookie / Pro / Elite difficulty, lane changes and overtake behavior.
- WebSocket client using the existing join/state/finish/leave message protocol.

## Controls

- A / Left and D / Right: steer
- S / Down: brake
- Space: nitro
- Shift: drift
- Escape: pause
- Touchscreen: on-screen steering, brake, drift and nitro buttons

## Required asset upload still pending

The ZIP includes four GLB models and sixteen PBR texture PNGs. The current GitHub connection can commit UTF-8 source files but does not expose a binary-file upload operation, so those binary assets have **not** yet been committed. The game scripts now check whether those assets exist and use procedural car/material fallbacks if they do not.

Copy the files from the supplied first upgrade ZIP into the exact paths documented in [assets/README.md](assets/README.md). Once uploaded, the car catalogue and PBR materials will load the supplied models and textures.

## Multiplayer server

The original Node.js server remains in the repository under `server/`. Set the multiplayer WebSocket URL in the game before connecting. The Godot client uses the same basic `join`, `state`, `finish` and `leave` message types, but an actual two-device connection test is still required.

## Android export

Install Godot export templates, configure the Android SDK/JDK in Editor Settings, add an Android export preset, then build a debug APK. Test on a physical Android device in landscape mode before release. Do not commit signing keys.

## Validation status

This branch is a source integration, not a verified Android release. Godot is not installed in the current execution environment, so the editor parser, desktop runtime, physics tuning, touch layout, GLB import and Android export have not been run here. Validate those in Godot 4.3+ before merging.

## Original Flutter project

The Flutter + Flame source remains available in the same repository tree and the original `main` branch remains untouched. This migration branch adds a Godot project at the repository root rather than deleting the previous implementation.

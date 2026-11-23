# Godot 4 migration proposal

The uploaded Milestone 2 package is an incremental patch for an existing Godot 4 project, not for Flutter. The repository `main` branch is currently Flutter + Flame. This branch is reserved for a separately reviewed Godot migration so the original Flutter source and build process remain intact.

The complete candidate project is available as a source archive supplied in this chat. It contains the Godot project, scripts, car GLBs, PBR texture sets, original Node.js server, and the original Flutter source as `legacy_flutter/`.

Before merging this engine conversion, open the Godot project in Godot 4.3+, let the editor import GLB/PNG assets, verify gameplay and online transport, then create and test an Android export. No Godot runtime or Android APK validation has been performed by this chat environment.

# Godot 3D assets

The four supplied GLB car models and all sixteen PBR PNG texture maps are now committed on the `godot-3d-engine-upgrade` branch.

## Car models
- `cars/street_gt.glb`
- `cars/hyper_x.glb`
- `cars/muscle_v8.glb`
- `cars/rally_rs.glb`

## PBR textures
Each material has albedo, ambient-occlusion (AO), normal, and roughness maps:
- `textures/asphalt_*.png`
- `textures/concrete_*.png`
- `textures/grass_*.png`
- `textures/sand_*.png`

The Godot scripts load these assets when available and retain procedural fallbacks for missing resources. Open the root `project.godot` in Godot 4.3 or newer to import the GLB and texture resources.

## Validation status
GitHub confirms all 20 binary assets are present. The project has not yet been opened in the Godot editor or run/exported, so import, gameplay, physics, touch controls, and Android export still require testing.

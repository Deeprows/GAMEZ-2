# Godot 3D assets

The source upgrade archive contains four GLB car models and 16 PBR PNG maps. The archive's binary files could not be committed through the current GitHub file-write connection, so this folder is intentionally a placeholder until those binary assets are uploaded.

Copy the files from the first upgrade ZIP to these exact paths:

- cars/street_gt.glb
- cars/hyper_x.glb
- cars/muscle_v8.glb
- cars/rally_rs.glb
- textures/asphalt_{albedo,roughness,normal,ao}.png
- textures/grass_{albedo,roughness,normal,ao}.png
- textures/sand_{albedo,roughness,normal,ao}.png
- textures/concrete_{albedo,roughness,normal,ao}.png

The game scripts have procedural car visuals as a fallback when the GLBs are absent. The texture loader also falls back to solid materials when PNG maps are absent.

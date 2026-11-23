extends RefCounted

const SAMPLES := 128
const RX := 34.0
const RZ := 24.0
const ROAD_HALF := 6.2

func build(theme_id: int) -> Node3D:
	var root := Node3D.new()
	root.name = "WorldTrack"
	var palettes := [
		{"ground": Color("#18242a"), "road": Color("#343940"), "accent": Color("#00d9ff"), "curb": Color("#f5f5f2"), "night": true},
		{"ground": Color("#b58a55"), "road": Color("#3d3a38"), "accent": Color("#f5bb69"), "curb": Color("#d94c3d"), "night": false},
		{"ground": Color("#4e7b43"), "road": Color("#45494c"), "accent": Color("#8fe38c"), "curb": Color("#e9e9e4"), "night": false},
		{"ground": Color("#101321"), "road": Color("#242936"), "accent": Color("#9d83ff"), "curb": Color("#a58cff"), "night": true}
	]
	var p: Dictionary = palettes[theme_id]
	_add_plane(root, Vector3(0, -0.22, 0), Vector2(180, 140), p.ground, "sand" if theme_id == 1 else "grass")
	_add_road_mesh(root, p.road)
	_add_track_edges(root, p.curb, p.accent)
	_add_barriers(root, p.accent)
	_add_scenery(root, theme_id, p)
	return root

func _mat(color: Color, roughness := 0.88, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m

func _textured_mat(color: Color, roughness: float, _frequency: float, texture_kind: String = "concrete") -> StandardMaterial3D:
	var material := _mat(color, roughness)
	var base_path := "res://assets/textures/%s_" % texture_kind
	var albedo: Texture2D = load(base_path + "albedo.png") as Texture2D if ResourceLoader.exists(base_path + "albedo.png") else null
	var rough_map: Texture2D = load(base_path + "roughness.png") as Texture2D if ResourceLoader.exists(base_path + "roughness.png") else null
	var normal_map: Texture2D = load(base_path + "normal.png") as Texture2D if ResourceLoader.exists(base_path + "normal.png") else null
	if albedo:
		material.albedo_texture = albedo
		material.albedo_color = color.lightened(0.45)
	if rough_map: material.roughness_texture = rough_map
	if normal_map:
		material.normal_enabled = true
		material.normal_texture = normal_map
		material.normal_scale = 0.32
	var ao_map: Texture2D = load(base_path + "ao.png") as Texture2D if ResourceLoader.exists(base_path + "ao.png") else null
	if ao_map:
		material.ao_enabled = true
		material.ao_texture = ao_map
	material.uv1_scale = Vector3(7.0, 24.0, 1.0) if texture_kind == "asphalt" else Vector3(18.0, 18.0, 1.0)
	return material

func _add_plane(parent: Node3D, pos: Vector3, size: Vector2, color: Color, texture_kind: String = "grass") -> void:
	var mi := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = _textured_mat(color, 1.0, 0.035, texture_kind)
	mi.position = pos
	parent.add_child(mi)
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.4, size.y)
	cs.shape = box
	cs.position.y = -0.2
	body.add_child(cs)
	parent.add_child(body)

func _center(t: float) -> Vector3:
	return Vector3(RX * cos(t), 0.12 + 0.35 * sin(t * 3.0), RZ * sin(t))

func _normal(t: float) -> Vector3:
	return Vector3(cos(t) / RX, 0, sin(t) / RZ).normalized()

func _add_road_mesh(parent: Node3D, color: Color) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(SAMPLES + 1):
		var t := TAU * float(i) / SAMPLES
		var c: Vector3 = _center(t)
		var n: Vector3 = _normal(t)
		vertices.append(c - n * ROAD_HALF + Vector3.UP * 0.015)
		vertices.append(c + n * ROAD_HALF + Vector3.UP * 0.015)
		uvs.append(Vector2(0.0, float(i) / SAMPLES * 36.0))
		uvs.append(Vector2(1.0, float(i) / SAMPLES * 36.0))
		if i < SAMPLES:
			var a := i * 2
			indices.append_array(PackedInt32Array([a, a + 2, a + 1, a + 1, a + 2, a + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var road := MeshInstance3D.new()
	road.mesh = mesh
	road.material_override = _textured_mat(color, 0.96, 0.12, "asphalt")
	parent.add_child(road)
	road.create_trimesh_collision()
	for lane in [-2.05, 2.05]:
		_add_dashed_line(parent, lane, Color(0.88, 0.9, 0.91), 0.075)
	_add_dashed_line(parent, 0.0, Color(0.98, 0.76, 0.2), 0.045)

func _add_dashed_line(parent: Node3D, offset: float, color: Color, width: float) -> void:
	var material := _mat(color, 0.72)
	for i in range(0, SAMPLES, 4):
		var t0 := TAU * float(i) / SAMPLES
		var t1 := TAU * float(i + 2) / SAMPLES
		var c0 := _center(t0) + _normal(t0) * offset + Vector3.UP * 0.04
		var c1 := _center(t1) + _normal(t1) * offset + Vector3.UP * 0.04
		var mid := (c0 + c1) * 0.5
		var dir := (c1 - c0).normalized()
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, 0.025, c0.distance_to(c1))
		bar.mesh = box
		bar.material_override = material
		bar.position = mid
		bar.rotation.y = atan2(dir.x, dir.z)
		parent.add_child(bar)

func _add_track_edges(parent: Node3D, curb_color: Color, accent: Color) -> void:
	for side in [-1.0, 1.0]:
		for i in range(SAMPLES):
			var t := TAU * float(i) / SAMPLES
			var c: Vector3 = _center(t) + _normal(t) * side * (ROAD_HALF + 0.25)
			var next: Vector3 = _center(t + TAU / SAMPLES) + _normal(t + TAU / SAMPLES) * side * (ROAD_HALF + 0.25)
			var curb := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.55, 0.12, c.distance_to(next) + 0.03)
			curb.mesh = mesh
			curb.material_override = _mat(curb_color if (i / 3) % 2 == 0 else accent, 0.82)
			curb.position = (c + next) * 0.5 + Vector3.UP * 0.08
			var d: Vector3 = (next - c).normalized()
			curb.rotation.y = atan2(d.x, d.z)
			parent.add_child(curb)

func _add_barriers(parent: Node3D, accent: Color) -> void:
	for side in [-1.0, 1.0]:
		for i in range(0, SAMPLES, 2):
			var t := TAU * float(i) / SAMPLES
			var c: Vector3 = _center(t) + _normal(t) * side * 7.65 + Vector3.UP * 0.72
			var nxt: Vector3 = _center(t + TAU * 2.0 / SAMPLES) + _normal(t + TAU * 2.0 / SAMPLES) * side * 7.65 + Vector3.UP * 0.72
			var rail := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.24, 0.7, c.distance_to(nxt) + 0.12)
			rail.mesh = box
			rail.material_override = _mat(Color("#d9dde1").lerp(accent, 0.16), 0.38, 0.65)
			rail.position = (c + nxt) * 0.5
			var d: Vector3 = (nxt - c).normalized()
			rail.rotation.y = atan2(d.x, d.z)
			parent.add_child(rail)

func _add_scenery(parent: Node3D, theme_id: int, palette: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9812 + theme_id * 321
	for i in range(100):
		var t := TAU * float(i) / 100.0 + rng.randf_range(-0.025, 0.025)
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := _center(t) + _normal(t) * side * rng.randf_range(11.0, 23.0)
		if theme_id == 0:
			_add_building(parent, pos, rng, palette.accent)
		elif theme_id == 1:
			_add_rock_or_palm(parent, pos, rng, true)
		elif theme_id == 2:
			_add_tree(parent, pos, rng, false)
		else:
			if i % 3 == 0: _add_lamp(parent, pos, palette.accent)
			else: _add_tree(parent, pos, rng, true)

func _add_tree(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, dark: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	var trunk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.12
	cyl.bottom_radius = 0.22
	cyl.height = rng.randf_range(2.0, 3.4)
	trunk.mesh = cyl
	trunk.material_override = _mat(Color("#49392b"), 0.94)
	trunk.position.y = cyl.height * 0.5
	root.add_child(trunk)
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = rng.randf_range(1.0, 1.6)
	sphere.height = sphere.radius * 2.1
	crown.mesh = sphere
	crown.material_override = _mat(Color("#183b2c") if dark else Color("#347b43"), 0.9)
	crown.position.y = cyl.height + 0.55
	root.add_child(crown)
	parent.add_child(root)

func _add_rock_or_palm(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, desert: bool) -> void:
	if not desert:
		_add_tree(parent, pos, rng, false)
		return
	var rock := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = rng.randf_range(0.7, 1.8)
	mesh.height = mesh.radius * 1.25
	rock.mesh = mesh
	rock.material_override = _mat(Color("#82705b"), 1.0)
	rock.position = pos + Vector3.UP * 0.45
	rock.scale = Vector3(1.5, 0.75, 1.1)
	parent.add_child(rock)

func _add_building(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator, accent: Color) -> void:
	var b := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rng.randf_range(3, 6), rng.randf_range(5, 17), rng.randf_range(3, 6))
	b.mesh = box
	b.material_override = _mat(Color("#202c3d"), 0.55, 0.35)
	b.position = pos + Vector3.UP * box.size.y * 0.5
	parent.add_child(b)
	for floor in range(1, int(box.size.y / 1.8)):
		var strip := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(box.size.x + 0.03, 0.045, box.size.z + 0.03)
		strip.mesh = sm
		var glow := _mat(accent, 0.42, 0.2)
		glow.emission_enabled = true
		glow.emission = accent * 0.4
		strip.material_override = glow
		strip.position = pos + Vector3.UP * (floor * 1.8)
		parent.add_child(strip)

func _add_lamp(parent: Node3D, pos: Vector3, color: Color) -> void:
	var post := MeshInstance3D.new()
	var pole := CylinderMesh.new()
	pole.top_radius = 0.045
	pole.bottom_radius = 0.07
	pole.height = 5.0
	post.mesh = pole
	post.material_override = _mat(Color("#343a45"), 0.35, 0.7)
	post.position = pos + Vector3.UP * 2.5
	parent.add_child(post)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.4
	light.omni_range = 11
	light.position = pos + Vector3.UP * 4.8
	parent.add_child(light)

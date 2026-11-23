extends Node3D

func build(index: int) -> Node3D:
	name = "Traffic_%02d" % index
	var colors := [Color("#d82d35"), Color("#e5c22c"), Color("#dce2e8"), Color("#253e65"), Color("#1c2028")]
	var paint := StandardMaterial3D.new()
	paint.albedo_color = colors[index % colors.size()]
	paint.metallic = 0.55
	paint.roughness = 0.28
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.65, 0.55, 3.4)
	body.mesh = box
	body.material_override = paint
	body.position.y = 0.55
	add_child(body)
	var cabin := MeshInstance3D.new()
	var cab := BoxMesh.new()
	cab.size = Vector3(1.35, 0.52, 1.45)
	cabin.mesh = cab
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color("#182b39")
	glass.metallic = 0.35
	glass.roughness = 0.16
	cabin.material_override = glass
	cabin.position = Vector3(0, 1.03, -0.12)
	add_child(cabin)
	return self

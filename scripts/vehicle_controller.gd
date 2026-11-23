extends VehicleBody3D
class_name PlayerVehicle

const Catalog = preload("res://scripts/car_catalog.gd")

var damage := 0.0
var touch_steer := 0.0
var touch_brake := false
var touch_nitro := false
var touch_drift := false
var is_boosting := false
var is_drifting := false
var steering_input := 0.0
var selected_car_id := "street"
var max_forward_speed := 62.0
var acceleration_multiplier := 1.0
var handling_multiplier := 1.0
var brake_input := false
var nitro_input := false
var drift_input := false
var speed_kmh: float:
	get: return linear_velocity.length() * 3.6

func build(car_id: String, paint: Color) -> PlayerVehicle:
	name = "PlayerVehicle"
	selected_car_id = car_id
	var spec := Catalog.get_car(car_id)
	max_forward_speed = float(spec.top_speed) / 3.6
	acceleration_multiplier = float(spec.acceleration)
	handling_multiplier = float(spec.handling)
	mass = 1180.0
	contact_monitor = true
	max_contacts_reported = 8
	if not body_entered.is_connected(_on_body_collision): body_entered.connect(_on_body_collision)
	linear_damp = 0.08
	angular_damp = 1.8
	center_of_mass = Vector3(0, -0.35, 0.05)
	var chassis := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.82, 0.55, 4.25)
	chassis.shape = shape
	chassis.position.y = 0.48
	add_child(chassis)
	var packed: PackedScene = load(str(spec.model)) as PackedScene if ResourceLoader.exists(str(spec.model)) else null
	if packed:
		var model := packed.instantiate()
		model.name = "OptimizedGLBVehicle"
		add_child(model)
	else:
		_add_body_mesh(paint)
	_add_lights()
	_add_wheel(Vector3(-0.92, 0.22, -1.28), true, true)
	_add_wheel(Vector3(0.92, 0.22, -1.28), true, true)
	_add_wheel(Vector3(-0.92, 0.22, 1.28), false, true)
	_add_wheel(Vector3(0.92, 0.22, 1.28), false, true)
	return self

func _add_body_mesh(paint: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = paint
	mat.metallic = 0.78
	mat.roughness = 0.22
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.9
	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.82, 0.48, 4.05)
	body.mesh = mesh
	body.material_override = mat
	body.position.y = 0.48
	add_child(body)
	var cabin := MeshInstance3D.new()
	var cab := BoxMesh.new()
	cab.size = Vector3(1.48, 0.48, 1.85)
	cabin.mesh = cab
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.025, 0.055, 0.075, 0.88)
	glass.metallic = 0.45
	glass.roughness = 0.12
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin.material_override = glass
	cabin.position = Vector3(0, 0.91, -0.12)
	add_child(cabin)
	var hood := MeshInstance3D.new()
	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(1.72, 0.12, 1.05)
	hood.mesh = hood_mesh
	hood.material_override = mat
	hood.position = Vector3(0, 0.72, -1.45)
	add_child(hood)
	var spoiler := MeshInstance3D.new()
	var wing := BoxMesh.new()
	wing.size = Vector3(1.9, 0.08, 0.34)
	spoiler.mesh = wing
	spoiler.material_override = mat
	spoiler.position = Vector3(0, 0.98, 1.78)
	add_child(spoiler)

func _add_wheel(pos: Vector3, front: bool, driven: bool) -> void:
	var wheel := VehicleWheel3D.new()
	wheel.position = pos
	wheel.use_as_steering = front
	wheel.use_as_traction = driven
	wheel.wheel_radius = 0.36
	wheel.wheel_rest_length = 0.18
	wheel.suspension_stiffness = 32.0
	wheel.suspension_max_force = 8500.0
	wheel.damping_compression = 0.42
	wheel.damping_relaxation = 0.58
	wheel.wheel_friction_slip = 3.1
	wheel.wheel_roll_influence = 0.08
	add_child(wheel)

func _rubber() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.025, 0.028, 0.032)
	m.roughness = 0.92
	return m

func _add_lights() -> void:
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.025, 0.035)
	red.emission_enabled = true
	red.emission = Color(1.0, 0.015, 0.02)
	red.emission_energy_multiplier = 2.5
	for x in [-0.62, 0.62]:
		var lamp := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.42, 0.12, 0.045)
		lamp.mesh = m
		lamp.material_override = red
		lamp.position = Vector3(x, 0.52, 2.04)
		add_child(lamp)

func set_controls(steer_axis: float, braking: bool, boost: bool, drifting: bool) -> void:
	steering_input = clampf(steer_axis + touch_steer, -1.0, 1.0)
	brake_input = braking or touch_brake
	nitro_input = boost or touch_nitro
	drift_input = drifting or touch_drift

func _physics_process(delta: float) -> void:
	steering = lerpf(steering, steering_input * (0.42 * handling_multiplier), delta * 3.8)
	is_drifting = drift_input and absf(steering_input) > 0.12 and speed_kmh > 25.0
	is_boosting = nitro_input and not brake_input
	var forward_speed := -global_transform.basis.z.dot(linear_velocity)
	var accel := (92.0 if is_boosting else 58.0) * acceleration_multiplier
	engine_force = accel if forward_speed < (max_forward_speed * (1.18 if is_boosting else 1.0)) else 0.0
	brake = 48.0 if brake_input else 0.0
	if is_drifting:
		for wheel in get_children():
			if wheel is VehicleWheel3D: wheel.wheel_friction_slip = 1.65
		apply_torque(Vector3.UP * -steering_input * 420.0)
	else:
		for wheel in get_children():
			if wheel is VehicleWheel3D: wheel.wheel_friction_slip = 3.1
	if global_position.y < -8.0:
		global_position = Vector3(0, 2, 0)
		linear_velocity = Vector3.ZERO

func _on_body_collision(_body: Node) -> void:
	var impact_speed := linear_velocity.length()
	if impact_speed > 7.0:
		damage = clampf(damage + impact_speed / 180.0, 0.0, 1.0)
		engine_force *= 1.0 - damage * 0.25

extends Node3D
class_name AIRacer

const Catalog = preload("res://scripts/car_catalog.gd")
var race_progress := 0.0
var completed_laps := 0
var target_speed := 34.0
var current_speed := 30.0
var lane_offset := 0.0
var lane_target := 0.0
var skill := 0.75
var driver_name := "Rival"
var model_id := "muscle_v8"
var _lane_timer := 0.0

func setup(index: int, progress: float, difficulty: int = 1) -> void:
	race_progress = progress
	skill = [0.68, 0.82, 0.94][clampi(difficulty, 0, 2)]
	target_speed = 27.0 + skill * 17.0 + float(index % 2) * 1.5
	lane_offset = [-2.7, 0.0, 2.7][index % 3]
	lane_target = lane_offset
	driver_name = ["Apex", "Vortex", "Nitro", "Shadow", "Blaze"][index % 5]
	model_id = ["blaze", "phantom", "volt"][index % 3]
	var model_path: String = Catalog.get_car(model_id).model
	var model: PackedScene = load(model_path) as PackedScene if ResourceLoader.exists(model_path) else null
	if model:
		var visual := model.instantiate()
		add_child(visual)
	else:
		_add_fallback_visual()

func advance(delta: float, player_progress: float) -> void:
	_lane_timer -= delta
	if _lane_timer <= 0.0:
		_lane_timer = randf_range(2.0, 4.5)
		lane_target = [-2.7, 0.0, 2.7][randi() % 3]
		if absf(wrapf(player_progress - race_progress, -0.5, 0.5)) < 0.08:
			lane_target = clampf(lane_offset + (1.0 if randf() > 0.5 else -1.0) * 2.7, -2.7, 2.7)
	current_speed = move_toward(current_speed, target_speed, delta * (5.0 + skill * 4.0))
	var next_progress := race_progress + current_speed * delta / 182.0
	if next_progress >= 1.0: completed_laps += 1
	race_progress = fposmod(next_progress, 1.0)
	lane_offset = move_toward(lane_offset, lane_target, delta * 1.1)
	var angle := race_progress * TAU
	var center := Vector3(34.0 * cos(angle), 0.0, 24.0 * sin(angle))
	var tangent := Vector3(-34.0 * sin(angle), 0.0, 24.0 * cos(angle)).normalized()
	var side := Vector3(-tangent.z, 0.0, tangent.x)
	global_position = center + side * lane_offset + Vector3.UP * 0.03
	look_at(global_position + tangent, Vector3.UP)

func _add_fallback_visual() -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.8, 0.65, 4.0)
	mesh.mesh = box
	add_child(mesh)

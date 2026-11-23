extends Node3D

const TrackBuilder = preload("res://scripts/track_builder.gd")
const PlayerCar = preload("res://scripts/vehicle_controller.gd")
const TrafficCar = preload("res://scripts/traffic_car.gd")
const MobileHUD = preload("res://scripts/mobile_hud.gd")
const RaceNetwork = preload("res://scripts/multiplayer_client.gd")
const AIRacerScript = preload("res://scripts/ai_racer.gd")
const GarageScript = preload("res://scripts/garage_manager.gd")
const Catalog = preload("res://scripts/car_catalog.gd")

@export_enum("Neon City", "Desert Run", "Green Valley", "Midnight Circuit") var environment_id := 0
@export var traffic_count := 8
var track: Node3D
var player: PlayerVehicle
var camera: Camera3D
var hud: CanvasLayer
var network
var race_time := 0.0
var race_distance := 0.0
var race_active := true
var nitro := 1.0
var coins := 0
var career_level := 1
var wins := 0
var best_distance := 0
var best_lap := 0.0
var last_lap_time := 0.0
var lap_time := 0.0
var drift_time := 0.0
var race_mode := "versusComputer"
var selected_car := "street"
var opponents: Array[Node3D] = []
var garage: GarageManager
var lap_count := 0
var last_track_angle := 0.0
var total_laps := 2
var race_position := 1
var ai_difficulty := 1
var opponent_progress := 0.0
var opponent_lane := 0.0
var opponent_name := "Rival"

func _ready() -> void:
	garage = GarageScript.new()
	add_child(garage)
	garage.load_data()
	_load_progress()
	_setup_environment()
	track = TrackBuilder.new().build(environment_id)
	add_child(track)
	var car_spec := Catalog.get_car(garage.selected_car)
	player = PlayerCar.new().build(garage.selected_car, car_spec.paint)
	add_child(player)
	player.global_position = Vector3(34, 0.10, 0)
	player.rotation.y = PI
	_setup_camera()
	_spawn_ai_racers()
	hud = MobileHUD.new()
	add_child(hud)
	hud.setup(self)
	last_track_angle = 0.0

func _setup_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = [Color("#10244b"), Color("#eaa66f"), Color("#7db9dc"), Color("#050817")][environment_id]
	sky_mat.sky_horizon_color = [Color("#e58c73"), Color("#f7d39a"), Color("#d8e8f2"), Color("#342a65")][environment_id]
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.fog_enabled = true
	env.fog_light_color = sky_mat.sky_horizon_color
	env.fog_density = 0.0015
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.25 if environment_id != 3 else 0.42
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 76
	camera.near = 0.08
	camera.far = 500
	camera.position = Vector3(0, 4.1, 9.5)
	add_child(camera)

func _spawn_ai_racers() -> void:
	for old_rival in opponents:
		if is_instance_valid(old_rival): old_rival.queue_free()
	opponents.clear()
	if race_mode != "versusComputer": return
	for i in range(3):
		var rival := AIRacerScript.new()
		add_child(rival)
		rival.setup(i, 0.01 + float(i) * 0.018, ai_difficulty)
		opponents.append(rival)

func _process(delta: float) -> void:
	if not race_active or player == null: return
	race_time += delta
	lap_time += delta
	if player.is_drifting: drift_time += delta
	race_distance += maxf(player.linear_velocity.length(), 0.0) * delta
	nitro = clampf(nitro + (0.055 if player.is_drifting else 0.018) * delta, 0.0, 1.0)
	if player.is_boosting: nitro = maxf(0.0, nitro - 0.32 * delta)
	if player.damage >= 1.0:
		finish_race(true)
		return
	var target := player.global_position + player.global_transform.basis * Vector3(0, 3.6, 8.5)
	camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-5.5 * delta))
	camera.look_at(player.global_position + player.global_transform.basis * Vector3(0, 0.5, -5.5), Vector3.UP)
	camera.fov = lerpf(camera.fov, 83.0 if player.is_boosting else 76.0, delta * 3.0)
	var angle := fposmod(atan2(player.global_position.z / 24.0, player.global_position.x / 34.0), TAU)
	if last_track_angle > 5.2 and angle < 1.1:
		lap_count += 1
		last_lap_time = lap_time
		if best_lap <= 0.0 or lap_time < best_lap: best_lap = lap_time
		lap_time = 0.0
		if lap_count >= total_laps: finish_race()
	last_track_angle = angle
	var player_progress := (float(lap_count) + angle / TAU) / float(total_laps)
	var ahead := 0
	for rival in opponents:
		if rival is AIRacer:
			rival.advance(delta, angle / TAU)
			var rival_total := float(rival.completed_laps) + rival.race_progress
			if rival_total > float(lap_count) + angle / TAU: ahead += 1
	race_position = ahead + 1
	if network and network.connected:
		network.send_state(clampf(player_progress, 0.0, 1.0), player.global_position.x / 10.0, player.linear_velocity.length() / 85.0)

func _physics_process(_delta: float) -> void:
	if player and race_active:
		player.set_controls(Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left"), Input.is_action_pressed("brake"), Input.is_action_pressed("nitro") and nitro > 0.02, Input.is_action_pressed("drift"))

func set_touch_control(axis: String, pressed: bool) -> void:
	if player == null: return
	match axis:
		"left": player.touch_steer = -1.0 if pressed else (0.0 if player.touch_steer < 0 else player.touch_steer)
		"right": player.touch_steer = 1.0 if pressed else (0.0 if player.touch_steer > 0 else player.touch_steer)
		"brake": player.touch_brake = pressed
		"nitro": player.touch_nitro = pressed
		"drift": player.touch_drift = pressed

func pause_race() -> void:
	race_active = not race_active
	get_tree().paused = not race_active

func finish_race(crashed: bool = false) -> void:
	if not race_active: return
	race_active = false
	var won := not crashed and (race_mode == "freeDrive" or race_position == 1)
	var reward := 0
	if crashed:
		reward = int(race_distance / 30.0)
	else:
		var base := 60 + career_level * 25
		var multiplier := 1.0 if race_mode == "freeDrive" else (1.0 if race_position == 1 else (0.55 if race_position == 2 else (0.30 if race_position == 3 else 0.15)))
		reward = int(round(float(base) * multiplier))
		if drift_time > 3.0: reward += 25
		if player.damage < 0.10: reward += 40
	if won:
		wins += 1
		career_level += 1
	garage.add_reward(reward)
	coins = garage.coins
	best_distance = maxi(best_distance, int(race_distance))
	total_laps = clampi(2 + int((career_level - 1) / 2), 2, 6)
	_save_progress()
	if hud and hud.has_method("show_race_result"):
		hud.show_race_result(race_position, reward, crashed)

func change_environment(id: int) -> void:
	environment_id = clampi(id, 0, 3)
	get_tree().reload_current_scene()

func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://career.cfg") == OK:
		coins = int(cfg.get_value("career", "coins", garage.coins))
		garage.coins = coins
		career_level = int(cfg.get_value("career", "level", 1))
		total_laps = clampi(2 + int((career_level - 1) / 2), 2, 6)
		wins = int(cfg.get_value("career", "wins", 0))
		best_distance = int(cfg.get_value("career", "best_distance", 0))
		best_lap = float(cfg.get_value("career", "best_lap", 0.0))
		selected_car = str(cfg.get_value("garage", "selected", garage.selected_car))
		garage.selected_car = selected_car

func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("career", "coins", coins)
	cfg.set_value("career", "level", career_level)
	cfg.set_value("career", "wins", wins)
	cfg.set_value("career", "best_distance", best_distance)
	cfg.set_value("career", "best_lap", best_lap)
	cfg.set_value("garage", "selected", garage.selected_car)
	cfg.set_value("garage", "owned", Array(garage.owned))
	cfg.save("user://career.cfg")

func garage_buy_or_select(car_id: String) -> bool:
	var ok := garage.buy_or_select(car_id)
	if ok:
		selected_car = garage.selected_car
		if player:
			var old_position := player.global_position
			var old_rotation := player.global_rotation
			remove_child(player)
			player.queue_free()
			var spec := Catalog.get_car(garage.selected_car)
			player = PlayerCar.new().build(garage.selected_car, spec.paint)
			add_child(player)
			player.global_position = old_position
			player.global_rotation = old_rotation
	return ok

func set_race_mode(mode: String) -> void:
	race_mode = "freeDrive" if mode == "freeDrive" else "versusComputer"
	_spawn_ai_racers()

func set_ai_difficulty(level: int) -> void:
	ai_difficulty = clampi(level, 0, 2)
	for rival in opponents:
		if rival is AIRacer: rival.queue_free()
	_spawn_ai_racers()

func connect_multiplayer(url: String, driver_name: String) -> void:
	if network: network.disconnect_from_server()
	network = RaceNetwork.new()
	add_child(network)
	network.connect_to_server(url, driver_name)

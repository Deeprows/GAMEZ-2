extends CanvasLayer

var game
var root: Control
var gameplay_root: Control
var menu_overlay: ColorRect
var menu_card: PanelContainer
var menu_content: VBoxContainer
var speed_label: Label
var gear_label: Label
var lap_label: Label
var meta_label: Label
var nitro_bar: ProgressBar
var toast: Label
var garage_panel: PanelContainer
var online_url_input: LineEdit
var online_name_input: LineEdit
var online_status_label: Label
const Catalog = preload("res://scripts/car_catalog.gd")

func setup(owner_game: Node) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = owner_game
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	gameplay_root = Control.new()
	gameplay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(gameplay_root)
	_build_race_hud()
	_build_garage()
	_build_menu()
	show_main_menu()

func _build_race_hud() -> void:
	var top := HBoxContainer.new()
	top.anchor_left = 0.02
	top.anchor_top = 0.025
	top.anchor_right = 0.98
	top.anchor_bottom = 0.15
	gameplay_root.add_child(top)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	lap_label = _label("NEON VELOCITY  •  CAREER %02d" % game.career_level, 16, Color("#bfefff"))
	info.add_child(lap_label)
	meta_label = _label("LAP 1 / 2     DISTANCE 0.0 KM", 12, Color.WHITE)
	info.add_child(meta_label)
	var speedbox := VBoxContainer.new()
	speedbox.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(speedbox)
	speed_label = _label("000", 36, Color.WHITE)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speedbox.add_child(speed_label)
	gear_label = _label("KM/H  •  RACE", 11, Color("#00e5ff"))
	gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speedbox.add_child(gear_label)
	var pause := _button("Ⅱ", Vector2(54, 48))
	pause.pressed.connect(game.pause_race)
	top.add_child(pause)
	nitro_bar = ProgressBar.new()
	nitro_bar.min_value = 0
	nitro_bar.max_value = 1
	nitro_bar.value = 1
	nitro_bar.show_percentage = false
	nitro_bar.custom_minimum_size = Vector2(190, 12)
	nitro_bar.anchor_left = 0.02
	nitro_bar.anchor_top = 0.17
	nitro_bar.anchor_right = 0.30
	nitro_bar.anchor_bottom = 0.20
	gameplay_root.add_child(nitro_bar)
	var nitro_caption := _label("NITRO", 10, Color("#00dfff"))
	nitro_caption.anchor_left = 0.02
	nitro_caption.anchor_top = 0.205
	nitro_caption.anchor_right = 0.18
	nitro_caption.anchor_bottom = 0.24
	gameplay_root.add_child(nitro_caption)
	var left := HBoxContainer.new()
	left.anchor_left = 0.025
	left.anchor_top = 0.77
	left.anchor_right = 0.32
	left.anchor_bottom = 0.97
	gameplay_root.add_child(left)
	left.add_child(_hold_button("◀", "left", Vector2(82, 78)))
	left.add_child(_hold_button("▶", "right", Vector2(82, 78)))
	var right := HBoxContainer.new()
	right.anchor_left = 0.53
	right.anchor_top = 0.77
	right.anchor_right = 0.98
	right.anchor_bottom = 0.97
	right.alignment = BoxContainer.ALIGNMENT_END
	gameplay_root.add_child(right)
	right.add_child(_hold_button("GO", "accelerate", Vector2(82, 78)))
	right.add_child(_hold_button("DRIFT", "drift", Vector2(82, 78)))
	right.add_child(_hold_button("BRAKE", "brake", Vector2(82, 78)))
	right.add_child(_hold_button("N₂O", "nitro", Vector2(82, 78)))
	var envrow := HBoxContainer.new()
	envrow.anchor_left = 0.34
	envrow.anchor_top = 0.025
	envrow.anchor_right = 0.66
	envrow.anchor_bottom = 0.10
	envrow.alignment = BoxContainer.ALIGNMENT_CENTER
	gameplay_root.add_child(envrow)
	for i in range(4):
		var b := _button(["CITY", "DESERT", "VALLEY", "NIGHT"][i], Vector2(68, 34))
		b.add_theme_font_size_override("font_size", 9)
		b.pressed.connect(Callable(game, "change_environment").bind(i))
		envrow.add_child(b)
	var garage_button := _button("GARAGE  •  %d COINS" % game.garage.coins, Vector2(170, 34))
	garage_button.anchor_left = 0.40
	garage_button.anchor_top = 0.12
	garage_button.anchor_right = 0.60
	garage_button.anchor_bottom = 0.17
	garage_button.pressed.connect(_toggle_garage)
	gameplay_root.add_child(garage_button)
	toast = _label("", 12, Color.WHITE)
	toast.anchor_left = 0.30
	toast.anchor_top = 0.43
	toast.anchor_right = 0.70
	toast.anchor_bottom = 0.52
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gameplay_root.add_child(toast)

func _build_garage() -> void:
	garage_panel = PanelContainer.new()
	garage_panel.anchor_left = 0.06
	garage_panel.anchor_top = 0.06
	garage_panel.anchor_right = 0.94
	garage_panel.anchor_bottom = 0.94
	garage_panel.visible = false
	garage_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.035, 0.06, 0.97)))
	root.add_child(garage_panel)

func _build_menu() -> void:
	menu_overlay = ColorRect.new()
	menu_overlay.color = Color(0.015, 0.025, 0.055, 0.91)
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu_overlay)
	menu_card = PanelContainer.new()
	menu_card.anchor_left = 0.06
	menu_card.anchor_top = 0.06
	menu_card.anchor_right = 0.94
	menu_card.anchor_bottom = 0.94
	menu_card.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.055, 0.10, 0.98)))
	menu_overlay.add_child(menu_card)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	menu_card.add_child(scroll)
	menu_content = VBoxContainer.new()
	menu_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_content.add_theme_constant_override("separation", 10)
	scroll.add_child(menu_content)

func _show_menu_page(page: String) -> void:
	for child in menu_content.get_children():
		menu_content.remove_child(child)
		child.queue_free()
	var heading := HBoxContainer.new()
	menu_content.add_child(heading)
	var title := _label("NEON VELOCITY", 24, Color("#8cecff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	if page != "home":
		var back := _button("BACK", Vector2(92, 38))
		back.pressed.connect(func(): _show_menu_page("home"))
		heading.add_child(back)
	menu_content.add_child(_label("RACING CHAMPIONSHIP  •  3D", 11, Color("#b8c9dc")))
	match page:
		"home":
			menu_content.add_child(_label("LEVEL %d     •     %d COINS     •     %d WINS" % [game.career_level, game.garage.coins, game.wins], 14, Color("#ffd45c")))
			_add_menu_button("START RACE", "START RACE  •  %s" % game.race_mode.to_upper(), func(): game.start_race())
			_add_menu_button("CHOOSE YOUR CAR", "GARAGE  •  %s" % str(Catalog.get_car(game.garage.selected_car).name), func(): _open_garage())
			_add_menu_button("SELECT TRACK", ["NEON CITY", "DESERT RUN", "GREEN VALLEY", "MIDNIGHT CIRCUIT"][game.environment_id], func(): _show_menu_page("tracks"))
			_add_menu_button("RACE MODE", "FREE DRIVE / VS COMPUTER", func(): _show_menu_page("modes"))
			_add_menu_button("CAREER & REWARDS", "BEST DISTANCE %d M" % game.best_distance, func(): _show_menu_page("career"))
			_add_menu_button("GAME SETTINGS", "AI DIFFICULTY: %s" % ["ROOKIE", "PRO", "ELITE"][game.ai_difficulty], func(): _show_menu_page("settings"))
		"tracks":
			menu_content.add_child(_label("CHOOSE YOUR RACING ENVIRONMENT", 14, Color.WHITE))
			for i in range(4):
				var track_button := _button(["NEON CITY", "DESERT RUN", "GREEN VALLEY", "MIDNIGHT CIRCUIT"][i], Vector2(300, 48))
				track_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				track_button.pressed.connect(Callable(game, "change_environment").bind(i))
				menu_content.add_child(track_button)
		"modes":
			menu_content.add_child(_label("SELECT HOW YOU WANT TO DRIVE", 14, Color.WHITE))
			_add_menu_button("FREE DRIVE", "Explore the circuit and earn rewards", func(): game.set_race_mode("freeDrive"); _show_menu_page("home"))
			_add_menu_button("VS COMPUTER", "Race against three AI drivers", func(): game.set_race_mode("versusComputer"); _show_menu_page("home"))
			_add_menu_button("ONLINE MULTIPLAYER", "Find another driver over the internet", func(): _show_menu_page("online"))
		"online":
			menu_content.add_child(_label("ONLINE MATCHMAKING", 17, Color("#c9a3ff")))
			menu_content.add_child(_label("Enter the WebSocket URL of your deployed race server.", 11, Color.WHITE))
			online_name_input = LineEdit.new()
			online_name_input.placeholder_text = "Racer name"
			online_name_input.text = "Driver"
			menu_content.add_child(online_name_input)
			online_url_input = LineEdit.new()
			online_url_input.placeholder_text = "wss://your-game-server.onrender.com"
			menu_content.add_child(online_url_input)
			online_status_label = _label("Connect to matchmaking to find another driver.", 11, Color("#b8c9dc"))
			menu_content.add_child(online_status_label)
			_add_menu_button("FIND AN OPPONENT", "Connect and wait for matchmaking", func(): game.connect_multiplayer(online_url_input.text, online_name_input.text))
		"settings":
			menu_content.add_child(_label("AI OPPONENT DIFFICULTY", 14, Color.WHITE))
			for i in range(3):
				var difficulty := _button(["ROOKIE", "PRO", "ELITE"][i], Vector2(240, 44))
				difficulty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				difficulty.disabled = game.ai_difficulty == i
				difficulty.pressed.connect(func(): game.set_ai_difficulty(i); _show_menu_page("settings"))
				menu_content.add_child(difficulty)
		"career":
			menu_content.add_child(_label("CAREER PROGRESS & REWARDS", 17, Color("#ffd45c")))
			menu_content.add_child(_label("CAREER LEVEL       %d" % game.career_level, 16, Color.WHITE))
			menu_content.add_child(_label("RACES WON             %d" % game.wins, 16, Color.WHITE))
			menu_content.add_child(_label("COIN BALANCE       %d" % game.garage.coins, 16, Color.WHITE))
			menu_content.add_child(_label("BEST DISTANCE       %d M" % game.best_distance, 16, Color.WHITE))
			menu_content.add_child(_label("BEST LAP                 %.2F S" % game.best_lap, 16, Color.WHITE))
		"pause":
			menu_content.add_child(_label("RACE PAUSED", 18, Color("#ffd45c")))
			_add_menu_button("RESUME RACE", "Continue driving", func(): game.resume_race())
			_add_menu_button("RETURN TO MAIN MENU", "Leave this race", func(): game.return_to_menu())
		"results":
			menu_content.add_child(_label("RACE FINISHED", 20, Color("#ffd45c")))
			menu_content.add_child(_label("POSITION: %d" % game.race_position, 16, Color.WHITE))
			menu_content.add_child(_label("CAREER LEVEL: %d" % game.career_level, 16, Color.WHITE))
			_add_menu_button("CONTINUE", "Return to championship menu", func(): game.return_to_menu())
			_add_menu_button("RACE AGAIN", "Start another race", func(): game.start_race())

func _add_menu_button(caption: String, detail: String, callback: Callable) -> void:
	var button := _button(caption + "     ›", Vector2(320, 50))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(callback)
	menu_content.add_child(button)
	menu_content.add_child(_label(detail, 10, Color("#aab9ce")))

func set_online_status(message: String) -> void:
	if online_status_label and is_instance_valid(online_status_label):
		online_status_label.text = message

func show_main_menu() -> void:
	garage_panel.visible = false
	gameplay_root.visible = false
	menu_overlay.visible = true
	_show_menu_page("home")

func show_pause_menu() -> void:
	garage_panel.visible = false
	gameplay_root.visible = false
	menu_overlay.visible = true
	_show_menu_page("pause")

func show_results() -> void:
	garage_panel.visible = false
	gameplay_root.visible = false
	menu_overlay.visible = true
	_show_menu_page("results")

func show_race_hud() -> void:
	menu_overlay.visible = false
	garage_panel.visible = false
	gameplay_root.visible = true

func _process(_delta: float) -> void:
	if not game or not game.player: return
	speed_label.text = "%03d" % int(game.player.speed_kmh)
	gear_label.text = "KM/H  •  %s" % ("BOOST" if game.player.is_boosting else "DRIFT" if game.player.is_drifting else "RACE")
	nitro_bar.value = game.nitro
	meta_label.text = "LAP %d / %d     CAREER %02d     TIME %05.1f" % [game.lap_count + 1, game.total_laps, game.career_level, game.race_time]

func _label(text_value: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l

func _button(caption: String, size: Vector2) -> Button:
	var b := Button.new()
	b.text = caption
	b.custom_minimum_size = size
	b.add_theme_font_size_override("font_size", 15)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _panel_style(Color(0.025, 0.07, 0.11, 0.78)))
	b.add_theme_stylebox_override("hover", _panel_style(Color(0.0, 0.32, 0.42, 0.92)))
	b.add_theme_stylebox_override("pressed", _panel_style(Color(0.0, 0.62, 0.72, 0.95)))
	return b

func _hold_button(caption: String, action: String, size: Vector2) -> Button:
	var b := _button(caption, size)
	b.button_down.connect(func(): game.set_touch_control(action, true))
	b.button_up.connect(func(): game.set_touch_control(action, false))
	return b

func _panel_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = Color(0.0, 0.82, 0.98, 0.75)
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func _open_garage() -> void:
	menu_overlay.visible = false
	gameplay_root.visible = false
	garage_panel.visible = true
	_refresh_garage()

func _toggle_garage() -> void:
	garage_panel.visible = not garage_panel.visible
	if garage_panel.visible: _refresh_garage()

func _refresh_garage() -> void:
	for child in garage_panel.get_children():
		garage_panel.remove_child(child)
		child.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	garage_panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("CHOOSE YOUR CAR  •  %d COINS" % game.garage.coins, 18, Color("#a9efff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := _button("BACK", Vector2(72, 34))
	close.pressed.connect(func():
		garage_panel.visible = false
		if not game.race_active: show_main_menu()
		else: gameplay_root.visible = true
	)
	heading.add_child(close)
	column.add_child(_label("Select a car or unlock it with coins earned from races.", 11, Color("#c4d1df")))
	for car in Catalog.CARS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 68
		column.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_label(str(car.name), 15, car.paint))
		info.add_child(_label("%d KM/H  •  ACCEL %.2f  •  GRIP %.2f" % [int(car.top_speed), float(car.acceleration), float(car.handling)], 10, Color.WHITE))
		var owned: bool = game.garage.owned.has(car.id)
		var selected: bool = game.garage.selected_car == car.id
		var action := _button("EQUIPPED" if selected else ("SELECT" if owned else "%d COINS" % int(car.price)), Vector2(112, 42))
		action.disabled = selected
		action.pressed.connect(Callable(self, "_purchase_car").bind(str(car.id)))
		row.add_child(action)

func _purchase_car(car_id: String) -> void:
	if game.garage_buy_or_select(car_id):
		_refresh_garage()
	else:
		toast.text = "NOT ENOUGH COINS — WIN RACES TO EARN MORE"

func show_race_result(position: int, reward: int, crashed: bool = false) -> void:
	toast.text = (("RACE OVER" if crashed else "RACE COMPLETE") + "  •  POSITION %d  •  +%d COINS" % [position, reward])
	toast.add_theme_color_override("font_color", Color("#ffd45c"))
	show_results()

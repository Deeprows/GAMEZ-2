extends CanvasLayer

var game
var speed_label: Label
var gear_label: Label
var lap_label: Label
var meta_label: Label
var nitro_bar: ProgressBar
var toast: Label
var garage_panel: PanelContainer
const Catalog = preload("res://scripts/car_catalog.gd")

func setup(owner_game: Node) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game = owner_game
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var top := HBoxContainer.new()
	top.anchor_left = 0.02
	top.anchor_top = 0.025
	top.anchor_right = 0.98
	top.anchor_bottom = 0.15
	root.add_child(top)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	lap_label = _label("NEON VELOCITY  •  CAREER %02d" % game.career_level, 16, Color("#bfefff"))
	info.add_child(lap_label)
	meta_label = _label("LAP 1 / 3     DISTANCE 0.0 KM", 12, Color.WHITE)
	info.add_child(meta_label)
	var speedbox := VBoxContainer.new()
	speedbox.alignment = BoxContainer.ALIGNMENT_END
	top.add_child(speedbox)
	speed_label = _label("000", 36, Color.WHITE)
	speed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speedbox.add_child(speed_label)
	gear_label = _label("KM/H  •  GEAR 1", 11, Color("#00e5ff"))
	gear_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	speedbox.add_child(gear_label)
	var pause := _button("Ⅱ", Vector2(54, 48))
	pause.pressed.connect(game.pause_race)
	top.add_child(pause)
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 1
	bar.value = 1
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(190, 12)
	bar.anchor_left = 0.02
	bar.anchor_top = 0.17
	bar.anchor_right = 0.30
	bar.anchor_bottom = 0.20
	root.add_child(bar)
	nitro_bar = bar
	var nitro_caption := _label("NITRO", 10, Color("#00dfff"))
	nitro_caption.anchor_left = 0.02
	nitro_caption.anchor_top = 0.205
	nitro_caption.anchor_right = 0.18
	nitro_caption.anchor_bottom = 0.24
	root.add_child(nitro_caption)
	var left := HBoxContainer.new()
	left.anchor_left = 0.025
	left.anchor_top = 0.77
	left.anchor_right = 0.32
	left.anchor_bottom = 0.97
	root.add_child(left)
	left.add_child(_hold_button("◀", "left", Vector2(82, 78)))
	left.add_child(_hold_button("▶", "right", Vector2(82, 78)))
	var right := HBoxContainer.new()
	right.anchor_left = 0.64
	right.anchor_top = 0.77
	right.anchor_right = 0.98
	right.anchor_bottom = 0.97
	right.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(right)
	right.add_child(_hold_button("DRIFT", "drift", Vector2(82, 78)))
	right.add_child(_hold_button("BRAKE", "brake", Vector2(82, 78)))
	right.add_child(_hold_button("N₂O", "nitro", Vector2(82, 78)))
	var envrow := HBoxContainer.new()
	envrow.anchor_left = 0.34
	envrow.anchor_top = 0.025
	envrow.anchor_right = 0.66
	envrow.anchor_bottom = 0.10
	envrow.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(envrow)
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
	root.add_child(garage_button)
	garage_panel = PanelContainer.new()
	garage_panel.anchor_left = 0.30
	garage_panel.anchor_top = 0.22
	garage_panel.anchor_right = 0.70
	garage_panel.anchor_bottom = 0.78
	garage_panel.visible = false
	garage_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.035, 0.06, 0.96)))
	root.add_child(garage_panel)
	toast = _label("", 12, Color.WHITE)
	toast.anchor_left = 0.30
	toast.anchor_top = 0.43
	toast.anchor_right = 0.70
	toast.anchor_bottom = 0.52
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast)

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
	s.content_margin_left = 8
	s.content_margin_right = 8
	return s

func _toggle_garage() -> void:
	garage_panel.visible = not garage_panel.visible
	if garage_panel.visible: _refresh_garage()

func _refresh_garage() -> void:
	var old := garage_panel.get_child(0) if garage_panel.get_child_count() > 0 else null
	if old:
		garage_panel.remove_child(old)
		old.queue_free()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	garage_panel.add_child(column)
	var heading := HBoxContainer.new()
	column.add_child(heading)
	var title := _label("PERFORMANCE GARAGE", 17, Color("#a9efff"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	var close := _button("CLOSE", Vector2(72, 34))
	close.pressed.connect(func(): garage_panel.visible = false)
	heading.add_child(close)
	column.add_child(_label("BALANCE: %d COINS   LEVEL: %d   WINS: %d   DIST: %d M   BEST LAP: %.2FS" % [game.garage.coins, game.career_level, game.wins, game.best_distance, game.best_lap], 12, Color("#ffd45c")))
	var difficulty_row := HBoxContainer.new()
	difficulty_row.add_child(_label("AI DIFFICULTY", 10, Color.WHITE))
	for i in range(3):
		var difficulty_button := _button(["ROOKIE", "PRO", "ELITE"][i], Vector2(76, 30))
		difficulty_button.disabled = game.ai_difficulty == i
		difficulty_button.pressed.connect(Callable(game, "set_ai_difficulty").bind(i))
		difficulty_button.pressed.connect(_refresh_garage)
		difficulty_row.add_child(difficulty_button)
	column.add_child(difficulty_row)
	var mode_row := HBoxContainer.new()
	mode_row.add_child(_label("RACE MODE", 10, Color.WHITE))
	for mode_data in [{"id":"freeDrive", "label":"FREE DRIVE"}, {"id":"versusComputer", "label":"VS COMPUTER"}]:
		var mode_button := _button(str(mode_data.label), Vector2(112, 30))
		mode_button.disabled = game.race_mode == str(mode_data.id)
		mode_button.pressed.connect(Callable(game, "set_race_mode").bind(str(mode_data.id)))
		mode_button.pressed.connect(_refresh_garage)
		mode_row.add_child(mode_button)
	column.add_child(mode_row)
	for car in Catalog.CARS:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 62
		column.add_child(row)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_label(str(car.name), 13, car.paint))
		info.add_child(_label("%d KM/H  •  SPEED %.2f  •  GRIP %.2f" % [int(car.top_speed), float(car.acceleration), float(car.handling)], 9, Color.WHITE))
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

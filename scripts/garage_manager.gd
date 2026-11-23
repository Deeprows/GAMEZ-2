extends Node
class_name GarageManager

const Catalog = preload("res://scripts/car_catalog.gd")

signal garage_changed
var coins := 0
var selected_car := "street"
var owned := PackedStringArray(["street"])

func load_data() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://career.cfg") == OK:
		coins = int(cfg.get_value("career", "coins", 0))
		selected_car = str(cfg.get_value("garage", "selected", "street"))
		owned = PackedStringArray(cfg.get_value("garage", "owned", ["street"]))
	if not owned.has("street"): owned.append("street")
	if not owned.has(selected_car): selected_car = "street"

func buy_or_select(car_id: String) -> bool:
	var car := Catalog.get_car(car_id)
	if owned.has(car_id):
		selected_car = car_id
		_save()
		garage_changed.emit()
		return true
	if coins < int(car.price): return false
	coins -= int(car.price)
	owned.append(car_id)
	selected_car = car_id
	_save()
	garage_changed.emit()
	return true

func add_reward(amount: int) -> void:
	coins += amount
	_save()
	garage_changed.emit()

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://career.cfg")
	cfg.set_value("career", "coins", coins)
	cfg.set_value("garage", "selected", selected_car)
	cfg.set_value("garage", "owned", Array(owned))
	cfg.save("user://career.cfg")

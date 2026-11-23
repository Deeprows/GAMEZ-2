extends RefCounted
class_name CarCatalog

# Preserves the original Flutter garage identities, unlock prices and stat ordering.
const CARS := [
	{"id":"street", "name":"Street R", "model":"res://assets/cars/street_gt.glb", "price":0, "top_speed":250.0, "acceleration":0.72, "handling":0.76, "paint":Color("#00b8e6")},
	{"id":"blaze", "name":"Blaze GT", "model":"res://assets/cars/hyper_x.glb", "price":350, "top_speed":282.0, "acceleration":0.82, "handling":0.70, "paint":Color("#e63b34")},
	{"id":"phantom", "name":"Phantom X", "model":"res://assets/cars/muscle_v8.glb", "price":700, "top_speed":307.0, "acceleration":0.90, "handling":0.84, "paint":Color("#9b59ff")},
	{"id":"volt", "name":"Volt RS", "model":"res://assets/cars/rally_rs.glb", "price":1100, "top_speed":320.0, "acceleration":0.96, "handling":0.94, "paint":Color("#ffc21f")}
]

static func get_car(car_id: String) -> Dictionary:
	for car in CARS:
		if car.id == car_id: return car
	return CARS[0]

static func owned_default() -> PackedStringArray:
	return PackedStringArray(["street"])

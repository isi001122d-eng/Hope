extends Camera3D

# ============================================================================
# HOPE 3D RACING - MULTI-MODE CHASE CAMERA (Godot 4.7)
# Mode 0: High Chase | Mode 1: Aerial Drone | Mode 2: Hood Cockpit FPV
# ============================================================================

@export var target_path: NodePath

var target_car: Node3D
var camera_mode: int = 0
var shake_trauma: float = 0.0
var shake_time: float = 0.0

func _ready() -> void:
	if not target_path.is_empty() and has_node(target_path):
		target_car = get_node(target_path) as Node3D

func add_shake(amount: float) -> void:
	shake_trauma = clampf(shake_trauma + amount, 0.0, 1.0)

func cycle_camera_mode() -> String:
	camera_mode = (camera_mode + 1) % 3
	var names: Array[String] = ["YUKSEK ARXA KAMERA", "HELIKOPTER KAMERASI", "KAPOT (FPV) KAMERASI"]
	return names[camera_mode]

func update_camera(delta: float) -> void:
	if not target_car:
		return

	shake_time += delta * 35.0
	if shake_trauma > 0.0:
		shake_trauma = maxf(0.0, shake_trauma - delta * 2.2)

	var shake_offset := Vector3.ZERO
	if shake_trauma > 0.01:
		var power: float = shake_trauma * shake_trauma * 0.45
		shake_offset = Vector3(
			sin(shake_time * 1.7) * power,
			cos(shake_time * 2.3) * power,
			0.0
		)

	var car_pos: Vector3 = target_car.global_position
	var is_nitro: bool = bool(target_car.get("is_nitro"))
	var speed_kmh: float = float(target_car.get("speed_kmh"))
	var speed_ratio: float = clampf(speed_kmh / 350.0, 0.0, 1.0)

	if camera_mode == 0:
		# Mode 0: High Chase Cam (Elevated so player car never blocks the road ahead)
		var desired_pos := Vector3(
			car_pos.x * 0.62,
			car_pos.y + 4.8 + speed_ratio * 0.65,
			car_pos.z + 9.4 + (1.4 if is_nitro else 0.0)
		)
		global_position = global_position.lerp(desired_pos, 8.0 * delta) + shake_offset
		var look_target := Vector3(car_pos.x * 0.38, car_pos.y + 1.2, car_pos.z - 55.0)
		look_at(look_target, Vector3.UP)
	elif camera_mode == 1:
		# Mode 1: High Aerial Drone Cam (Maximum visibility of all 4 lanes)
		var desired_pos := Vector3(
			car_pos.x * 0.45,
			car_pos.y + 8.2,
			car_pos.z + 13.0
		)
		global_position = global_position.lerp(desired_pos, 7.0 * delta) + shake_offset
		var look_target := Vector3(car_pos.x * 0.25, car_pos.y + 0.8, car_pos.z - 65.0)
		look_at(look_target, Vector3.UP)
	else:
		# Mode 2: Hood / Bumper FPV Cam (100% unobstructed road ahead)
		global_position = Vector3(car_pos.x, car_pos.y + 1.32, car_pos.z - 1.65) + shake_offset * 0.4
		var look_target := Vector3(car_pos.x, car_pos.y + 1.15, car_pos.z - 90.0)
		look_at(look_target, Vector3.UP)

	var target_fov: float = 84.0 if is_nitro else (66.0 + speed_ratio * 8.0)
	fov = lerpf(fov, target_fov, 6.0 * delta)

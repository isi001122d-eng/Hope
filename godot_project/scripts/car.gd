extends Node3D

# ============================================================================
# HOPE 3D RACING - SUPERCAR CONTROLLER (Godot 4.7)
# Arcade 3D Physics + Suspension Dynamics + 6-Gear Transmission + Drift + Nitro
# ============================================================================

@export var base_cruise_speed: float = 110.0
@export var max_normal_speed: float = 240.0
@export var max_nitro_speed: float = 350.0
@export var min_brake_speed: float = 45.0
@export var acceleration_rate: float = 95.0
@export var braking_rate: float = 140.0
@export var lateral_steer_speed: float = 16.5
@export var road_half_width: float = 7.4

# Dynamic State read by HUD, Camera & World Manager
var speed_kmh: float = 110.0
var nitro_amount: float = 100.0
var armor_health: float = 100.0
var is_nitro: bool = false
var is_drifting: bool = false
var is_airborne: bool = false
var current_gear: int = 1
var engine_rpm: float = 0.3

# Internal Physics State
var steer_input: float = 0.0
var current_steer: float = 0.0
var vertical_velocity: float = 0.0
var chassis_pitch: float = 0.0
var chassis_roll: float = 0.0
var chassis_yaw: float = 0.0
var invulnerable_timer: float = 0.0
var paint_index: int = 0

const PAINT_COLORS: Array[Color] = [
	Color(0.0, 0.88, 1.0),   # Cyber Cyan
	Color(1.0, 0.12, 0.28),  # Ferrari Crimson
	Color(1.0, 0.75, 0.05),  # Lambo Gold
	Color(0.1, 0.95, 0.45),  # Venom Emerald
	Color(0.65, 0.2, 1.0),   # Midnight Violet
]

@onready var body_pivot: Node3D = $BodyPivot
@onready var chassis_mesh: MeshInstance3D = $BodyPivot/ChassisMesh
@onready var hood_mesh: MeshInstance3D = $BodyPivot/HoodMesh
@onready var spoiler_mesh: MeshInstance3D = $BodyPivot/SpoilerWing
@onready var wheel_fl: Node3D = $WheelFrontLeft
@onready var wheel_fr: Node3D = $WheelFrontRight
@onready var wheel_bl: Node3D = $WheelBackLeft
@onready var wheel_br: Node3D = $WheelBackRight
@onready var nitro_flame_l: MeshInstance3D = $BodyPivot/NitroFlameL
@onready var nitro_flame_r: MeshInstance3D = $BodyPivot/NitroFlameR
@onready var taillight_l: MeshInstance3D = $BodyPivot/TailLightL
@onready var taillight_r: MeshInstance3D = $BodyPivot/TailLightR

var paint_material: StandardMaterial3D
var flame_time: float = 0.0

func _ready() -> void:
	paint_material = StandardMaterial3D.new()
	paint_material.albedo_color = PAINT_COLORS[0]
	paint_material.metallic = 0.82
	paint_material.roughness = 0.18
	_apply_paint_material()
	if nitro_flame_l and nitro_flame_r:
		nitro_flame_l.visible = false
		nitro_flame_r.visible = false

func reset_vehicle() -> void:
	position = Vector3(0.0, 0.0, 0.0)
	rotation = Vector3.ZERO
	speed_kmh = base_cruise_speed
	nitro_amount = 100.0
	armor_health = 100.0
	is_nitro = false
	is_drifting = false
	is_airborne = false
	vertical_velocity = 0.0
	current_steer = 0.0
	chassis_pitch = 0.0
	chassis_roll = 0.0
	chassis_yaw = 0.0
	invulnerable_timer = 0.0
	if body_pivot:
		body_pivot.rotation = Vector3.ZERO
		body_pivot.visible = true

func cycle_paint_color() -> String:
	paint_index = (paint_index + 1) % PAINT_COLORS.size()
	paint_material.albedo_color = PAINT_COLORS[paint_index]
	var names: Array[String] = ["CYBER CYAN", "FERRARI RED", "LAMBO GOLD", "VENOM GREEN", "MIDNIGHT VIOLET"]
	return names[paint_index]

func _apply_paint_material() -> void:
	if chassis_mesh:
		chassis_mesh.material_override = paint_material
	if hood_mesh:
		hood_mesh.material_override = paint_material
	if spoiler_mesh:
		spoiler_mesh.material_override = paint_material

func launch_jump(upward_speed: float) -> void:
	if not is_airborne:
		vertical_velocity = upward_speed
		is_airborne = true

func update_car(delta: float, active_gameplay: bool) -> void:
	if invulnerable_timer > 0.0:
		invulnerable_timer = max(0.0, invulnerable_timer - delta)
		if body_pivot:
			body_pivot.visible = (int(invulnerable_timer * 16.0) % 2) == 0
	elif body_pivot:
		body_pivot.visible = true

	if not active_gameplay:
		if nitro_flame_l and nitro_flame_r:
			nitro_flame_l.visible = false
			nitro_flame_r.visible = false
		return

	# 1. Steering Input
	steer_input = 0.0
	if Input.is_action_pressed("steer_left"):
		steer_input -= 1.0
	if Input.is_action_pressed("steer_right"):
		steer_input += 1.0

	is_drifting = Input.is_action_pressed("handbrake") and absf(steer_input) > 0.1
	var steer_Response: float = 9.0 if is_drifting else 7.0
	current_steer = move_toward(current_steer, steer_input, steer_Response * delta)

	var drift_multiplier: float = 1.32 if is_drifting else 1.0
	var speed_steer_scale: float = clampf(speed_kmh / 120.0, 0.65, 1.35)
	position.x += current_steer * lateral_steer_speed * drift_multiplier * speed_steer_scale * delta
	position.x = clampf(position.x, -road_half_width, road_half_width)

	# 2. Throttle, Braking & Nitro
	var accelerating: bool = Input.is_action_pressed("accelerate")
	var braking: bool = Input.is_action_pressed("brake")
	is_nitro = Input.is_action_pressed("nitro") and nitro_amount > 2.0

	var target_speed: float = base_cruise_speed
	var target_pitch: float = 0.0

	if is_nitro:
		target_speed = max_nitro_speed
		nitro_amount = maxf(0.0, nitro_amount - delta * 26.0)
		speed_kmh = move_toward(speed_kmh, target_speed, acceleration_rate * 2.1 * delta)
		target_pitch = 0.045 # Nose lifts up under extreme nitro torque
	elif accelerating:
		target_speed = max_normal_speed
		speed_kmh = move_toward(speed_kmh, target_speed, acceleration_rate * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 5.5)
		target_pitch = 0.022
	elif braking:
		target_speed = min_brake_speed
		speed_kmh = move_toward(speed_kmh, target_speed, braking_rate * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 5.5)
		target_pitch = -0.04 # Nose dives forward under heavy braking
	else:
		speed_kmh = move_toward(speed_kmh, base_cruise_speed, 50.0 * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 6.5)

	# 3. Vertical Jump & Gravity Physics
	if is_airborne or position.y > 0.0:
		position.y += vertical_velocity * delta
		vertical_velocity -= 25.0 * delta
		target_pitch = clampf(vertical_velocity * 0.025, -0.18, 0.22)
		if position.y <= 0.0:
			position.y = 0.0
			vertical_velocity = 0.0
			is_airborne = false
			chassis_pitch = -0.06 # Landing suspension compression

	# 4. 3D Suspension Body Roll, Pitch & Yaw
	var target_roll: float = -current_steer * (0.14 if is_drifting else 0.085)
	var target_yaw: float = -current_steer * (0.26 if is_drifting else 0.12)

	chassis_pitch = lerpf(chassis_pitch, target_pitch, 8.0 * delta)
	chassis_roll = lerpf(chassis_roll, target_roll, 10.0 * delta)
	chassis_yaw = lerpf(chassis_yaw, target_yaw, 9.0 * delta)

	if body_pivot:
		body_pivot.rotation.x = chassis_pitch
		body_pivot.rotation.z = chassis_roll
		body_pivot.rotation.y = chassis_yaw

	# 5. Wheel Rotation & Front Wheel Steering Angle
	var wheel_spin: float = (speed_kmh / 3.6) * delta * 2.4
	var front_steer_angle: float = -current_steer * 0.38
	if wheel_fl:
		wheel_fl.rotation.x -= wheel_spin
		wheel_fl.rotation.y = front_steer_angle
	if wheel_fr:
		wheel_fr.rotation.x -= wheel_spin
		wheel_fr.rotation.y = front_steer_angle
	if wheel_bl:
		wheel_bl.rotation.x -= wheel_spin
	if wheel_br:
		wheel_br.rotation.x -= wheel_spin

	# 6. Nitro Exhaust Flames Animation
	flame_time += delta * 28.0
	if nitro_flame_l and nitro_flame_r:
		nitro_flame_l.visible = is_nitro
		nitro_flame_r.visible = is_nitro
		if is_nitro:
			var pulse: float = 0.85 + 0.35 * sin(flame_time)
			nitro_flame_l.scale = Vector3(1.0, pulse, 1.0)
			nitro_flame_r.scale = Vector3(1.0, pulse, 1.0)

	# 7. Gear & Engine RPM Calculation
	var gear_thresholds: Array[float] = [0.0, 75.0, 125.0, 175.0, 225.0, 280.0, 360.0]
	current_gear = 1
	for g in range(1, 6):
		if speed_kmh >= gear_thresholds[g]:
			current_gear = g + 1
	var g_min: float = gear_thresholds[current_gear - 1]
	var g_max: float = gear_thresholds[current_gear]
	engine_rpm = clampf((speed_kmh - g_min) / maxf(1.0, g_max - g_min), 0.22, 1.0)

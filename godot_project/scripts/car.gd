extends VehicleBody3D

# Car Physics & Tuning
@export var max_engine_force: float = 380.0
@export var max_brake_force: float = 20.0
@export var max_steer_angle: float = 0.42 # ~24 degrees
@export var steer_speed: float = 6.0
@export var nitro_boost_force: float = 550.0

# Dynamic State
var speed_kmh: float = 0.0
var nitro_amount: float = 100.0
var is_nitro: bool = false
var current_steer: float = 0.0

@onready var wheel_fl: VehicleWheel3D = $WheelFrontLeft
@onready var wheel_fr: VehicleWheel3D = $WheelFrontRight
@onready var wheel_bl: VehicleWheel3D = $WheelBackLeft
@onready var wheel_br: VehicleWheel3D = $WheelBackRight
@onready var nitro_flame_l: MeshInstance3D = $NitroFlameL
@onready var nitro_flame_r: MeshInstance3D = $NitroFlameR

func _ready() -> void:
	# Configure wheel traction & steering
	wheel_fl.use_as_steering = true
	wheel_fr.use_as_steering = true
	wheel_bl.use_as_traction = true
	wheel_br.use_as_traction = true
	
	if nitro_flame_l and nitro_flame_r:
		nitro_flame_l.visible = false
		nitro_flame_r.visible = false

func _physics_process(delta: float) -> void:
	# Calculate current linear velocity in km/h
	speed_kmh = linear_velocity.length() * 3.6
	
	# 1. Steering Input with smooth interpolation
	var steer_target := 0.0
	if Input.is_action_pressed("steer_left"):
		steer_target += max_steer_angle
	if Input.is_action_pressed("steer_right"):
		steer_target -= max_steer_angle
	
	# High speed steering damping (reduce sensitivity at high speed)
	var speed_factor = clamp(1.0 - (speed_kmh / 300.0) * 0.45, 0.4, 1.0)
	steer_target *= speed_factor
	current_steer = move_toward(current_steer, steer_target, steer_speed * delta)
	steering = current_steer

	# 2. Throttle & Nitro Boost
	var throttle := 0.0
	is_nitro = Input.is_action_pressed("nitro") and nitro_amount > 5.0
	
	if Input.is_action_pressed("accelerate"):
		throttle = 1.0
	elif Input.is_action_pressed("brake"):
		throttle = -0.6
		
	var target_force = throttle * max_engine_force
	if is_nitro and throttle > 0.0:
		target_force += nitro_boost_force
		nitro_amount = max(0.0, nitro_amount - delta * 30.0)
		if nitro_flame_l and nitro_flame_r:
			nitro_flame_l.visible = true
			nitro_flame_r.visible = true
	else:
		nitro_amount = min(100.0, nitro_amount + delta * 8.0)
		if nitro_flame_l and nitro_flame_r:
			nitro_flame_l.visible = false
			nitro_flame_r.visible = false

	engine_force = target_force

	# 3. Handbrake / Braking
	if Input.is_action_pressed("handbrake"):
		brake = max_brake_force * 2.0
	elif throttle < 0.0 and speed_kmh > 5.0 and linear_velocity.dot(-transform.basis.z) > 0.0:
		# Braking while moving forward
		brake = max_brake_force
		engine_force = 0.0
	else:
		brake = 0.0

	# 4. Flip recovery (Reset with R key)
	if Input.is_action_just_pressed("reset_car"):
		global_position.y += 2.0
		rotation = Vector3.ZERO
		linear_velocity = Vector3.ZERO
		angular_velocity = Vector3.ZERO

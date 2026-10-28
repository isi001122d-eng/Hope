extends Node3D

# ============================================================================
# HOPE 3D RACING - HYPERCAR CONTROLLER & VISUAL FX (Godot 4.7)
# Clearcoat Automotive Paint + Underglow + Particle FX + 3D Suspension
# ============================================================================

@export var base_cruise_speed: float = 120.0
@export var max_normal_speed: float = 250.0
@export var max_nitro_speed: float = 365.0
@export var min_brake_speed: float = 45.0
@export var acceleration_rate: float = 105.0
@export var braking_rate: float = 155.0
@export var lateral_steer_speed: float = 17.5
@export var road_half_width: float = 7.3

# Dynamic State read by HUD, Camera & World Manager
var speed_kmh: float = 120.0
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
var flame_time: float = 0.0

const PAINT_PALETTE: Array[Dictionary] = [
	{"name": "CYBER CYAN", "albedo": Color(0.0, 0.82, 1.0), "neon": Color(0.0, 0.95, 1.0)},
	{"name": "ROSSO CORSA", "albedo": Color(0.95, 0.06, 0.18), "neon": Color(1.0, 0.15, 0.3)},
	{"name": "SOLAR GOLD", "albedo": Color(1.0, 0.72, 0.02), "neon": Color(1.0, 0.85, 0.1)},
	{"name": "VENOM EMERALD", "albedo": Color(0.05, 0.92, 0.38), "neon": Color(0.1, 1.0, 0.45)},
	{"name": "ULTRAVIOLET", "albedo": Color(0.55, 0.12, 1.0), "neon": Color(0.75, 0.25, 1.0)},
]

@onready var body_pivot: Node3D = $BodyPivot
@onready var wheel_fl: Node3D = $WheelFrontLeft
@onready var wheel_fr: Node3D = $WheelFrontRight
@onready var wheel_bl: Node3D = $WheelBackLeft
@onready var wheel_br: Node3D = $WheelBackRight
@onready var nitro_flame_l: MeshInstance3D = $BodyPivot/NitroFlameL
@onready var nitro_flame_r: MeshInstance3D = $BodyPivot/NitroFlameR
@onready var underglow_light: OmniLight3D = $BodyPivot/UnderglowLight
@onready var brake_light_omni: OmniLight3D = $BodyPivot/BrakeOmniLight

var paint_material: StandardMaterial3D
var neon_accent_material: StandardMaterial3D
var carbon_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var chrome_material: StandardMaterial3D
var brake_glow_material: StandardMaterial3D

var nitro_particles_l: CPUParticles3D
var nitro_particles_r: CPUParticles3D
var drift_particles_l: CPUParticles3D
var drift_particles_r: CPUParticles3D

func _ready() -> void:
	_setup_automotive_materials()
	_build_hypercar_details()
	_setup_particle_emitters()
	if nitro_flame_l and nitro_flame_r:
		nitro_flame_l.visible = false
		nitro_flame_r.visible = false

func _setup_automotive_materials() -> void:
	# Triple-Coat Showroom Automotive Paint (Clearcoat + Metallic + Rim)
	paint_material = StandardMaterial3D.new()
	paint_material.albedo_color = PAINT_PALETTE[0]["albedo"]
	paint_material.metallic = 0.88
	paint_material.roughness = 0.12
	paint_material.clearcoat_enabled = true
	paint_material.clearcoat = 1.0
	paint_material.clearcoat_roughness = 0.04
	paint_material.rim_enabled = true
	paint_material.rim = 0.35
	paint_material.rim_tint = 0.5

	neon_accent_material = StandardMaterial3D.new()
	neon_accent_material.albedo_color = PAINT_PALETTE[0]["neon"]
	neon_accent_material.emission_enabled = true
	neon_accent_material.emission = PAINT_PALETTE[0]["neon"]
	neon_accent_material.emission_energy_multiplier = 3.2

	carbon_material = StandardMaterial3D.new()
	carbon_material.albedo_color = Color(0.08, 0.09, 0.11)
	carbon_material.metallic = 0.55
	carbon_material.roughness = 0.32
	carbon_material.clearcoat_enabled = true
	carbon_material.clearcoat = 0.5

	glass_material = StandardMaterial3D.new()
	glass_material.albedo_color = Color(0.03, 0.05, 0.09)
	glass_material.metallic = 0.96
	glass_material.roughness = 0.04
	glass_material.clearcoat_enabled = true
	glass_material.clearcoat = 1.0

	chrome_material = StandardMaterial3D.new()
	chrome_material.albedo_color = Color(0.9, 0.94, 1.0)
	chrome_material.metallic = 0.98
	chrome_material.roughness = 0.08

	brake_glow_material = StandardMaterial3D.new()
	brake_glow_material.albedo_color = Color(1.0, 0.05, 0.18)
	brake_glow_material.emission_enabled = true
	brake_glow_material.emission = Color(1.0, 0.05, 0.18)
	brake_glow_material.emission_energy_multiplier = 2.8

	# Apply to base meshes in car.tscn
	for node_name in ["ChassisMesh", "HoodMesh", "SpoilerWing"]:
		var m := body_pivot.get_node_or_null(node_name) as MeshInstance3D
		if m:
			m.material_override = paint_material
	var cab := body_pivot.get_node_or_null("CabinMesh") as MeshInstance3D
	if cab:
		cab.material_override = glass_material
	for tl_name in ["TailLightL", "TailLightR"]:
		var tl := body_pivot.get_node_or_null(tl_name) as MeshInstance3D
		if tl:
			tl.material_override = brake_glow_material

func _build_hypercar_details() -> void:
	if not body_pivot:
		return

	# 1. Sculpted Front Carbon Splitter & Aero Fins
	var splitter := MeshInstance3D.new()
	var sp_box := BoxMesh.new()
	sp_box.size = Vector3(2.16, 0.08, 0.85)
	sp_box.material = carbon_material
	splitter.mesh = sp_box
	splitter.position = Vector3(0.0, 0.24, -1.92)
	body_pivot.add_child(splitter)

	# Front Neon Chin Strip
	var chin_neon := MeshInstance3D.new()
	var cn_box := BoxMesh.new()
	cn_box.size = Vector3(2.18, 0.035, 0.08)
	cn_box.material = neon_accent_material
	chin_neon.mesh = cn_box
	chin_neon.position = Vector3(0.0, 0.25, -2.32)
	body_pivot.add_child(chin_neon)

	# 2. Sculpted Left & Right Front & Rear Widebody Fenders (Wheel Arches)
	for side in [-1.0, 1.0]:
		# Front Fender Arch
		var f_fender := MeshInstance3D.new()
		var ff_box := BoxMesh.new()
		ff_box.size = Vector3(0.32, 0.42, 1.25)
		ff_box.material = paint_material
		f_fender.mesh = ff_box
		f_fender.position = Vector3(side * 1.02, 0.62, -1.28)
		body_pivot.add_child(f_fender)

		# Rear Muscular Haunch / Fender
		var r_fender := MeshInstance3D.new()
		var rf_box := BoxMesh.new()
		rf_box.size = Vector3(0.36, 0.50, 1.45)
		rf_box.material = paint_material
		r_fender.mesh = rf_box
		r_fender.position = Vector3(side * 1.04, 0.68, 1.25)
		body_pivot.add_child(r_fender)

		# Carbon Side Skirt + Neon Underglow Strip
		var skirt := MeshInstance3D.new()
		var sk_box := BoxMesh.new()
		sk_box.size = Vector3(0.18, 0.12, 2.2)
		sk_box.material = carbon_material
		skirt.mesh = sk_box
		skirt.position = Vector3(side * 1.06, 0.26, 0.0)
		body_pivot.add_child(skirt)

		var side_neon := MeshInstance3D.new()
		var sn_box := BoxMesh.new()
		sn_box.size = Vector3(0.04, 0.04, 2.15)
		sn_box.material = neon_accent_material
		side_neon.mesh = sn_box
		side_neon.position = Vector3(side * 1.14, 0.23, 0.0)
		body_pivot.add_child(side_neon)

		# Swan-Neck GT Wing Pylons & Endplates
		var pylon := MeshInstance3D.new()
		var py_box := BoxMesh.new()
		py_box.size = Vector3(0.06, 0.38, 0.32)
		py_box.material = carbon_material
		pylon.mesh = py_box
		pylon.rotation.x = -0.22
		pylon.position = Vector3(side * 0.58, 0.90, 1.82)
		body_pivot.add_child(pylon)

		var endplate := MeshInstance3D.new()
		var ep_box := BoxMesh.new()
		ep_box.size = Vector3(0.05, 0.26, 0.56)
		ep_box.material = neon_accent_material
		endplate.mesh = ep_box
		endplate.position = Vector3(side * 1.02, 1.06, 1.88)
		body_pivot.add_child(endplate)

	# 3. Full-Width Cyberpunk LED Rear Light Bar + Diffuser + Quad Exhausts
	var rear_bar := MeshInstance3D.new()
	var rb_box := BoxMesh.new()
	rb_box.size = Vector3(1.96, 0.08, 0.08)
	rb_box.material = brake_glow_material
	rear_bar.mesh = rb_box
	rear_bar.position = Vector3(0.0, 0.72, 2.16)
	body_pivot.add_child(rear_bar)

	var diffuser := MeshInstance3D.new()
	var df_box := BoxMesh.new()
	df_box.size = Vector3(1.88, 0.22, 0.35)
	df_box.material = carbon_material
	diffuser.mesh = df_box
	diffuser.position = Vector3(0.0, 0.30, 2.08)
	body_pivot.add_child(diffuser)

	# Quad Chrome Exhaust Pipes
	var pipe_cyl := CylinderMesh.new()
	pipe_cyl.top_radius = 0.085
	pipe_cyl.bottom_radius = 0.085
	pipe_cyl.height = 0.25
	pipe_cyl.material = chrome_material
	for ex_x in [-0.54, -0.36, 0.36, 0.54]:
		var pipe := MeshInstance3D.new()
		pipe.mesh = pipe_cyl
		pipe.rotation.x = PI * 0.5
		pipe.position = Vector3(ex_x, 0.38, 2.18)
		body_pivot.add_child(pipe)

	# 4. Upgrade All 4 Wheels with Chrome Rims & Spokes
	for w_node in [wheel_fl, wheel_fr, wheel_bl, wheel_br]:
		if not w_node:
			continue
		var hub := MeshInstance3D.new()
		var h_cyl := CylinderMesh.new()
		h_cyl.top_radius = 0.27
		h_cyl.bottom_radius = 0.27
		h_cyl.height = 0.36
		h_cyl.material = chrome_material
		hub.mesh = h_cyl
		hub.rotation.z = PI * 0.5
		w_node.add_child(hub)

		var ring := MeshInstance3D.new()
		var r_cyl := CylinderMesh.new()
		r_cyl.top_radius = 0.14
		r_cyl.bottom_radius = 0.14
		r_cyl.height = 0.38
		r_cyl.material = neon_accent_material
		ring.mesh = r_cyl
		ring.rotation.z = PI * 0.5
		w_node.add_child(ring)

func _setup_particle_emitters() -> void:
	if not body_pivot:
		return

	# Nitro Afterburner Sparks (Left & Right)
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.albedo_color = Color(0.2, 0.95, 1.0)
	var spark_Quad := BoxMesh.new()
	spark_Quad.size = Vector3(0.12, 0.12, 0.32)
	spark_Quad.material = spark_mat

	nitro_particles_l = _create_emitter(spark_Quad, Vector3(-0.45, 0.40, 2.35), Vector3(0, 0, 1), 22.0, 32, 0.28)
	nitro_particles_r = _create_emitter(spark_Quad, Vector3(0.45, 0.40, 2.35), Vector3(0, 0, 1), 22.0, 32, 0.28)
	body_pivot.add_child(nitro_particles_l)
	body_pivot.add_child(nitro_particles_r)

	# Tire Drift Smoke / Sparks
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.albedo_color = Color(1.0, 0.55, 0.15)
	var smoke_box := BoxMesh.new()
	smoke_box.size = Vector3(0.16, 0.16, 0.16)
	smoke_box.material = smoke_mat

	drift_particles_l = _create_emitter(smoke_box, Vector3(-1.02, 0.15, 1.45), Vector3(0, 0.3, 1), 12.0, 24, 0.35)
	drift_particles_r = _create_emitter(smoke_box, Vector3(1.02, 0.15, 1.45), Vector3(0, 0.3, 1), 12.0, 24, 0.35)
	body_pivot.add_child(drift_particles_l)
	body_pivot.add_child(drift_particles_r)

func _create_emitter(mesh: Mesh, pos: Vector3, dir: Vector3, vel: float, count: int, life: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.mesh = mesh
	p.position = pos
	p.amount = count
	p.lifetime = life
	p.explosiveness = 0.0
	p.direction = dir
	p.spread = 18.0
	p.gravity = Vector3(0, -2.0, 0)
	p.initial_velocity_min = vel * 0.7
	p.initial_velocity_max = vel * 1.2
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.3
	p.emitting = false
	return p

func reset_vehicle() -> void:
	position = Vector3.ZERO
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
	paint_index = (paint_index + 1) % PAINT_PALETTE.size()
	var entry: Dictionary = PAINT_PALETTE[paint_index]
	paint_material.albedo_color = entry["albedo"]
	neon_accent_material.albedo_color = entry["neon"]
	neon_accent_material.emission = entry["neon"]
	if underglow_light:
		underglow_light.light_color = entry["neon"]
	return String(entry["name"])

func launch_jump(upward_speed: float) -> void:
	if not is_airborne:
		vertical_velocity = upward_speed
		is_airborne = true

func update_car(delta: float, active_gameplay: bool) -> void:
	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
		if body_pivot:
			body_pivot.visible = (int(invulnerable_timer * 16.0) % 2) == 0
	elif body_pivot:
		body_pivot.visible = true

	if not active_gameplay:
		if nitro_flame_l and nitro_flame_r:
			nitro_flame_l.visible = false
			nitro_flame_r.visible = false
		if nitro_particles_l and nitro_particles_r:
			nitro_particles_l.emitting = false
			nitro_particles_r.emitting = false
		if drift_particles_l and drift_particles_r:
			drift_particles_l.emitting = false
			drift_particles_r.emitting = false
		return

	# 1. Steering Input
	steer_input = 0.0
	if Input.is_action_pressed("steer_left"):
		steer_input -= 1.0
	if Input.is_action_pressed("steer_right"):
		steer_input += 1.0

	is_drifting = Input.is_action_pressed("handbrake") and absf(steer_input) > 0.1
	var steer_response: float = 9.5 if is_drifting else 7.5
	current_steer = move_toward(current_steer, steer_input, steer_response * delta)

	var drift_multiplier: float = 1.35 if is_drifting else 1.0
	var speed_steer_scale: float = clampf(speed_kmh / 120.0, 0.7, 1.38)
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
		nitro_amount = maxf(0.0, nitro_amount - delta * 25.0)
		speed_kmh = move_toward(speed_kmh, target_speed, acceleration_rate * 2.2 * delta)
		target_pitch = 0.048
	elif accelerating:
		target_speed = max_normal_speed
		speed_kmh = move_toward(speed_kmh, target_speed, acceleration_rate * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 5.8)
		target_pitch = 0.024
	elif braking:
		target_speed = min_brake_speed
		speed_kmh = move_toward(speed_kmh, target_speed, braking_rate * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 5.8)
		target_pitch = -0.045
	else:
		speed_kmh = move_toward(speed_kmh, base_cruise_speed, 50.0 * delta)
		nitro_amount = minf(100.0, nitro_amount + delta * 6.8)

	# Brake Light Intensity Boost when Braking
	if brake_glow_material:
		brake_glow_material.emission_energy_multiplier = 6.5 if braking else 2.6
	if brake_light_omni:
		brake_light_omni.light_energy = 4.2 if braking else 1.4

	# 3. Vertical Jump & Gravity Physics
	if is_airborne or position.y > 0.0:
		position.y += vertical_velocity * delta
		vertical_velocity -= 25.0 * delta
		target_pitch = clampf(vertical_velocity * 0.025, -0.18, 0.22)
		if position.y <= 0.0:
			position.y = 0.0
			vertical_velocity = 0.0
			is_airborne = false
			chassis_pitch = -0.065

	# 4. 3D Suspension Body Roll, Pitch & Yaw
	var target_roll: float = -current_steer * (0.145 if is_drifting else 0.088)
	var target_yaw: float = -current_steer * (0.28 if is_drifting else 0.125)

	chassis_pitch = lerpf(chassis_pitch, target_pitch, 8.5 * delta)
	chassis_roll = lerpf(chassis_roll, target_roll, 10.5 * delta)
	chassis_yaw = lerpf(chassis_yaw, target_yaw, 9.5 * delta)

	if body_pivot:
		body_pivot.rotation.x = chassis_pitch
		body_pivot.rotation.z = chassis_roll
		body_pivot.rotation.y = chassis_yaw

	# 5. Wheel Spin & Front Wheel Steering
	var wheel_spin: float = (speed_kmh / 3.6) * delta * 2.5
	var front_steer_angle: float = -current_steer * 0.40
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

	# 6. Nitro Flames & Particle Emitters
	flame_time += delta * 32.0
	if nitro_flame_l and nitro_flame_r:
		nitro_flame_l.visible = is_nitro
		nitro_flame_r.visible = is_nitro
		if is_nitro:
			var pulse: float = 0.9 + 0.4 * sin(flame_time)
			nitro_flame_l.scale = Vector3(1.15, pulse, 1.15)
			nitro_flame_r.scale = Vector3(1.15, pulse, 1.15)

	if nitro_particles_l and nitro_particles_r:
		nitro_particles_l.emitting = is_nitro
		nitro_particles_r.emitting = is_nitro

	if drift_particles_l and drift_particles_r:
		var emit_sparks: bool = (is_drifting or braking) and not is_airborne
		drift_particles_l.emitting = emit_sparks
		drift_particles_r.emitting = emit_sparks

	# 7. Gear & Engine RPM Calculation
	var gear_thresholds: Array[float] = [0.0, 75.0, 125.0, 175.0, 225.0, 285.0, 370.0]
	current_gear = 1
	for g in range(1, 6):
		if speed_kmh >= gear_thresholds[g]:
			current_gear = g + 1
	var g_min: float = gear_thresholds[current_gear - 1]
	var g_max: float = gear_thresholds[current_gear]
	engine_rpm = clampf((speed_kmh - g_min) / maxf(1.0, g_max - g_min), 0.22, 1.0)

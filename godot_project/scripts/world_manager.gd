extends Node3D

# ============================================================================
# HOPE 3D RACING - ENDLESS HIGHWAY WORLD & GAME MANAGER (Godot 4.7)
# ============================================================================

const LANES: Array[float] = [-5.85, -1.95, 1.95, 5.85]
const ROAD_WIDTH: float = 16.4
const SEGMENT_LENGTH: float = 54.0
const SEGMENT_COUNT: int = 9
const SAVE_PATH: String = "user://hope_3d_highscore.cfg"

@onready var player_car: Node3D = $Car
@onready var chase_cam: Camera3D = $ChaseCamera
@onready var hud: Control = $HUD
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var road_container: Node3D = $RoadContainer
@onready var entity_container: Node3D = $EntityContainer

# Game State
var is_game_over: bool = false
var score: float = 0.0
var high_score: int = 0
var coins: int = 0
var level: int = 1
var distance_km: float = 0.0
var theme_index: int = 0

# Road & Entities
var road_segments: Array[Node3D] = []
var traffic_list: Array[Dictionary] = []
var pickup_list: Array[Dictionary] = []
var spawn_timer: float = 0.0
var pickup_timer: float = 0.0

# Shared Materials for high FPS on Intel UHD / Integrated & Dedicated GPUs
var mat_asphalt: StandardMaterial3D
var mat_terrain: StandardMaterial3D
var mat_line: StandardMaterial3D
var mat_curb_cyan: StandardMaterial3D
var mat_curb_red: StandardMaterial3D
var mat_guardrail: StandardMaterial3D
var mat_tree_trunk: StandardMaterial3D
var mat_tree_leaves: StandardMaterial3D
var mat_lamp_glow: StandardMaterial3D
var mat_tail_red: StandardMaterial3D
var mat_head_white: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_tire: StandardMaterial3D
var mat_coin: StandardMaterial3D
var mat_nitro_orb: StandardMaterial3D
var mat_repair_orb: StandardMaterial3D
var mat_ramp: StandardMaterial3D
var traffic_paint_mats: Array[StandardMaterial3D] = []

# Procedural Audio
var sfx_player: AudioStreamPlayer
var tone_freq: float = 0.0
var tone_timer: float = 0.0
var tone_phase: float = 0.0
var tone_noise: bool = false

func _ready() -> void:
	_load_high_score()
	_init_shared_materials()
	_init_audio()
	_build_highway_segments()
	_spawn_initial_entities()

	if hud:
		hud.connect("restart_requested", Callable(self, "_restart_game"))
		hud.show_banner("HOPE 3D RACING — UGURLAR!", Color(0.0, 0.95, 1.0), 2.5)

func _init_shared_materials() -> void:
	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.11, 0.12, 0.16)
	mat_asphalt.roughness = 0.85

	mat_terrain = StandardMaterial3D.new()
	mat_terrain.albedo_color = Color(0.05, 0.08, 0.13)
	mat_terrain.roughness = 0.95

	mat_line = StandardMaterial3D.new()
	mat_line.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_line.albedo_color = Color(0.92, 0.95, 1.0)

	mat_curb_cyan = StandardMaterial3D.new()
	mat_curb_cyan.albedo_color = Color(0.0, 0.9, 1.0)
	mat_curb_cyan.emission_enabled = true
	mat_curb_cyan.emission = Color(0.0, 0.45, 0.6)

	mat_curb_red = StandardMaterial3D.new()
	mat_curb_red.albedo_color = Color(1.0, 0.1, 0.35)
	mat_curb_red.emission_enabled = true
	mat_curb_red.emission = Color(0.55, 0.05, 0.18)

	mat_guardrail = StandardMaterial3D.new()
	mat_guardrail.albedo_color = Color(0.55, 0.62, 0.72)
	mat_guardrail.metallic = 0.75
	mat_guardrail.roughness = 0.3

	mat_tree_trunk = StandardMaterial3D.new()
	mat_tree_trunk.albedo_color = Color(0.28, 0.18, 0.1)

	mat_tree_leaves = StandardMaterial3D.new()
	mat_tree_leaves.albedo_color = Color(0.08, 0.48, 0.28)
	mat_tree_leaves.roughness = 0.8

	mat_lamp_glow = StandardMaterial3D.new()
	mat_lamp_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_lamp_glow.albedo_color = Color(0.6, 0.95, 1.0)

	mat_tail_red = StandardMaterial3D.new()
	mat_tail_red.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_tail_red.albedo_color = Color(1.0, 0.08, 0.2)

	mat_head_white = StandardMaterial3D.new()
	mat_head_white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_head_white.albedo_color = Color(0.9, 0.98, 1.0)

	mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.06, 0.09, 0.15)
	mat_glass.metallic = 0.9
	mat_glass.roughness = 0.1

	mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.1, 0.1, 0.12)
	mat_tire.roughness = 0.85

	mat_coin = StandardMaterial3D.new()
	mat_coin.albedo_color = Color(1.0, 0.78, 0.05)
	mat_coin.metallic = 0.9
	mat_coin.roughness = 0.15
	mat_coin.emission_enabled = true
	mat_coin.emission = Color(0.45, 0.32, 0.0)

	mat_nitro_orb = StandardMaterial3D.new()
	mat_nitro_orb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_nitro_orb.albedo_color = Color(0.0, 0.95, 1.0)

	mat_repair_orb = StandardMaterial3D.new()
	mat_repair_orb.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_repair_orb.albedo_color = Color(0.15, 1.0, 0.45)

	mat_ramp = StandardMaterial3D.new()
	mat_ramp.albedo_color = Color(1.0, 0.45, 0.0)
	mat_ramp.emission_enabled = true
	mat_ramp.emission = Color(0.35, 0.12, 0.0)

	var traffic_colors: Array[Color] = [
		Color(0.95, 0.15, 0.25),
		Color(1.0, 0.55, 0.05),
		Color(0.15, 0.8, 0.45),
		Color(0.55, 0.25, 0.95),
		Color(0.9, 0.92, 0.96),
		Color(0.15, 0.45, 0.95),
	]
	for col in traffic_colors:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.metallic = 0.75
		m.roughness = 0.22
		traffic_paint_mats.append(m)

func _init_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	sfx_player = AudioStreamPlayer.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050.0
	gen.buffer_length = 0.1
	sfx_player.stream = gen
	sfx_player.volume_db = -8.0
	add_child(sfx_player)
	sfx_player.play()

func _exit_tree() -> void:
	if sfx_player:
		sfx_player.stop()
		sfx_player.stream = null

func _play_sfx(freq: float, duration: float, is_noise: bool = false) -> void:
	tone_freq = freq
	tone_timer = duration
	tone_noise = is_noise

func _fill_audio_buffer(delta: float) -> void:
	if not sfx_player or not sfx_player.playing:
		return
	var playback := sfx_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if not playback:
		return
	if tone_timer > 0.0:
		tone_timer = maxf(0.0, tone_timer - delta)
	var frames: int = playback.get_frames_available()
	for _i in range(frames):
		if tone_timer <= 0.0:
			playback.push_frame(Vector2.ZERO)
		else:
			var sample: float = 0.0
			if tone_noise:
				sample = randf_range(-0.35, 0.35)
			else:
				tone_phase = fmod(tone_phase + tone_freq / 22050.0, 1.0)
				sample = sin(tone_phase * TAU) * 0.25
			playback.push_frame(Vector2(sample, sample))

func _build_highway_segments() -> void:
	for i in range(SEGMENT_COUNT):
		var seg := _create_single_road_segment(i)
		seg.position.z = float(1 - i) * SEGMENT_LENGTH
		road_container.add_child(seg)
		road_segments.append(seg)

func _create_single_road_segment(idx: int) -> Node3D:
	var seg := Node3D.new()
	seg.name = "RoadSegment_%d" % idx

	# 1. Asphalt Surface
	var road_mesh := MeshInstance3D.new()
	var road_box := BoxMesh.new()
	road_box.size = Vector3(ROAD_WIDTH, 0.2, SEGMENT_LENGTH)
	road_box.material = mat_asphalt
	road_mesh.mesh = road_box
	road_mesh.position = Vector3(0.0, -0.1, 0.0)
	seg.add_child(road_mesh)

	# 2. Left & Right Outer Terrain
	for side in [-1.0, 1.0]:
		var terr := MeshInstance3D.new()
		var tbox := BoxMesh.new()
		tbox.size = Vector3(90.0, 0.2, SEGMENT_LENGTH)
		tbox.material = mat_terrain
		terr.mesh = tbox
		terr.position = Vector3(side * (ROAD_WIDTH * 0.5 + 45.0), -0.18, 0.0)
		seg.add_child(terr)

		# Curbs & Guardrails
		var curb := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.55, 0.32, SEGMENT_LENGTH)
		cbox.material = mat_curb_cyan if (idx % 2 == 0) else mat_curb_red
		curb.mesh = cbox
		curb.position = Vector3(side * (ROAD_WIDTH * 0.5 + 0.28), 0.1, 0.0)
		seg.add_child(curb)

		var rail := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(0.2, 0.75, SEGMENT_LENGTH)
		rbox.material = mat_guardrail
		rail.mesh = rbox
		rail.position = Vector3(side * (ROAD_WIDTH * 0.5 + 0.8), 0.45, 0.0)
		seg.add_child(rail)

	# 3. Dashed Lane Markings (3 divider lines for 4 lanes)
	var dash_box := BoxMesh.new()
	dash_box.size = Vector3(0.22, 0.04, 4.2)
	dash_box.material = mat_line
	for lane_div in [-3.9, 0.0, 3.9]:
		var z_pos: float = -SEGMENT_LENGTH * 0.5 + 4.5
		while z_pos < SEGMENT_LENGTH * 0.5:
			var dash := MeshInstance3D.new()
			dash.mesh = dash_box
			dash.position = Vector3(lane_div, 0.02, z_pos)
			seg.add_child(dash)
			z_pos += 10.5

	# 4. Streetlights & Roadside Low-Poly Trees
	for z_step in [-18.0, 18.0]:
		for side in [-1.0, 1.0]:
			# Streetlamp Pole
			var pole := MeshInstance3D.new()
			var pmesh := CylinderMesh.new()
			pmesh.top_radius = 0.1
			pmesh.bottom_radius = 0.14
			pmesh.height = 6.2
			pmesh.material = mat_guardrail
			pole.mesh = pmesh
			pole.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.8), 3.1, z_step)
			seg.add_child(pole)

			var bulb := MeshInstance3D.new()
			var bmesh := BoxMesh.new()
			bmesh.size = Vector3(0.9, 0.2, 0.4)
			bmesh.material = mat_lamp_glow
			bulb.mesh = bmesh
			bulb.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.2), 6.2, z_step)
			seg.add_child(bulb)

			# Low-Poly Stylized Pine Tree
			var tree_x: float = side * (ROAD_WIDTH * 0.5 + 7.5 + float((idx * 3) % 7))
			var trunk := MeshInstance3D.new()
			var tr_mesh := CylinderMesh.new()
			tr_mesh.top_radius = 0.22
			tr_mesh.bottom_radius = 0.3
			tr_mesh.height = 1.8
			tr_mesh.material = mat_tree_trunk
			trunk.mesh = tr_mesh
			trunk.position = Vector3(tree_x, 0.9, z_step - 6.0)
			seg.add_child(trunk)

			var crown := MeshInstance3D.new()
			var cr_mesh := CylinderMesh.new()
			cr_mesh.top_radius = 0.05
			cr_mesh.bottom_radius = 1.6
			cr_mesh.height = 4.2
			cr_mesh.material = mat_tree_leaves
			crown.mesh = cr_mesh
			crown.position = Vector3(tree_x, 3.6, z_step - 6.0)
			seg.add_child(crown)

	return seg

func _spawn_initial_entities() -> void:
	for i in range(1, 7):
		_spawn_traffic_vehicle(-55.0 - float(i) * 48.0)
		if i % 2 == 0:
			_spawn_pickup_item(-45.0 - float(i) * 42.0)

func _spawn_traffic_vehicle(z_pos: float) -> void:
	# Ensure we never block all 4 lanes near the same Z coordinate
	var occupied_lanes: Array[int] = []
	for t in traffic_list:
		var t_node: Node3D = t["node"]
		if absf(t_node.position.z - z_pos) < 28.0:
			occupied_lanes.append(int(t["lane_idx"]))

	var free_lanes: Array[int] = []
	for l_idx in range(LANES.size()):
		if not occupied_lanes.has(l_idx):
			free_lanes.append(l_idx)
	if free_lanes.size() <= 1:
		return

	var chosen_lane: int = free_lanes[randi() % free_lanes.size()]
	var is_truck: bool = (randf() < 0.25)
	var paint_mat: StandardMaterial3D = traffic_paint_mats[randi() % traffic_paint_mats.size()]

	var vehicle := Node3D.new()
	vehicle.position = Vector3(LANES[chosen_lane], 0.0, z_pos)

	var body_len: float = 6.2 if is_truck else 4.2
	var body_height: float = 1.65 if is_truck else 0.62

	# Chassis
	var chassis := MeshInstance3D.new()
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(2.0, body_height, body_len)
	c_mesh.material = paint_mat
	chassis.mesh = c_mesh
	chassis.position = Vector3(0.0, body_height * 0.5 + 0.3, 0.0)
	vehicle.add_child(chassis)

	# Cabin
	var cabin := MeshInstance3D.new()
	var cab_mesh := BoxMesh.new()
	cab_mesh.size = Vector3(1.65, 0.52, 2.0)
	cab_mesh.material = mat_glass
	cabin.mesh = cab_mesh
	cabin.position = Vector3(0.0, body_height + 0.45, -0.3 if not is_truck else -1.8)
	vehicle.add_child(cabin)

	# Bright Rear Tail Lights (High Visibility from afar!)
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.52, 0.22, 0.12)
	tail_mesh.material = mat_tail_red
	for sx in [-0.65, 0.65]:
		var tl := MeshInstance3D.new()
		tl.mesh = tail_mesh
		tl.position = Vector3(sx, 0.68, body_len * 0.5 + 0.02)
		vehicle.add_child(tl)

	entity_container.add_child(vehicle)
	traffic_list.append({
		"node": vehicle,
		"lane_idx": chosen_lane,
		"speed_kmh": randf_range(45.0, 88.0),
		"half_len": body_len * 0.5,
		"passed": false,
	})

func _spawn_pickup_item(z_pos: float) -> void:
	var lane_idx: int = randi() % LANES.size()
	var roll: float = randf()
	var item_type: String = "coin"
	var holder := Node3D.new()
	holder.position = Vector3(LANES[lane_idx], 0.0, z_pos)

	if roll < 0.55:
		item_type = "coin"
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.65
		cyl.bottom_radius = 0.65
		cyl.height = 0.2
		cyl.material = mat_coin
		m.mesh = cyl
		m.rotation.z = PI * 0.5
		m.position.y = 1.0
		holder.add_child(m)
	elif roll < 0.80:
		item_type = "nitro"
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.85, 0.85, 0.85)
		box.material = mat_nitro_orb
		m.mesh = box
		m.position.y = 1.0
		holder.add_child(m)
	elif roll < 0.92:
		item_type = "repair"
		var m := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.55
		sph.height = 1.1
		sph.material = mat_repair_orb
		m.mesh = sph
		m.position.y = 1.0
		holder.add_child(m)
	else:
		item_type = "ramp"
		var m := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(2.8, 0.45, 5.2)
		rbox.material = mat_ramp
		m.mesh = rbox
		m.rotation.x = 0.22
		m.position.y = 0.25
		holder.add_child(m)

	entity_container.add_child(holder)
	pickup_list.append({
		"node": holder,
		"type": item_type,
	})

func _physics_process(delta: float) -> void:
	_fill_audio_buffer(delta)
	_handle_shortcuts()

	if is_game_over:
		if Input.is_action_just_pressed("reset_car") or Input.is_action_just_pressed("nitro"):
			_restart_game()
		if chase_cam and chase_cam.has_method("update_camera"):
			chase_cam.call("update_camera", delta)
		return

	if player_car and player_car.has_method("update_car"):
		player_car.call("update_car", delta, true)

	var p_speed: float = float(player_car.get("speed_kmh"))
	var world_step: float = (p_speed / 3.6) * delta

	# 1. Scroll & Recycle Endless 3D Highway Segments
	for seg in road_segments:
		seg.position.z += world_step
		if seg.position.z > SEGMENT_LENGTH * 1.5:
			seg.position.z -= float(SEGMENT_COUNT) * SEGMENT_LENGTH

	# 2. Update Score, Distance & Level
	var mult: float = 3.0 if bool(player_car.get("is_nitro")) else 1.0
	score += world_step * 0.85 * mult
	distance_km += (world_step / 1000.0)
	if int(score) > high_score:
		high_score = int(score)

	var new_level: int = clampi(1 + int(score / 1500.0), 1, 12)
	if new_level > level:
		level = new_level
		player_car.set("base_cruise_speed", minf(185.0, 110.0 + float(level - 1) * 8.0))
		if hud:
			hud.show_banner("★ SEVIYYE %d! SURET ARTDI! ★" % level, Color(1.0, 0.4, 1.0), 2.2)
		_play_sfx(740.0, 0.22, false)

	# 3. Update Traffic & Check Collisions / Near-Miss
	var p_pos: Vector3 = player_car.position
	var p_airborne: bool = bool(player_car.get("is_airborne"))

	for i in range(traffic_list.size() - 1, -1, -1):
		var item: Dictionary = traffic_list[i]
		var t_node: Node3D = item["node"]
		var rel_speed: float = p_speed - float(item["speed_kmh"])
		t_node.position.z += (rel_speed / 3.6) * delta

		var dx: float = absf(t_node.position.x - p_pos.x)
		var dz: float = absf(t_node.position.z - p_pos.z)
		var hit_len: float = float(item["half_len"]) + 1.85

		# Near-miss check
		if not bool(item["passed"]) and t_node.position.z > p_pos.z + 2.5:
			item["passed"] = true
			if dx < 3.9 and p_speed >= 130.0:
				score += 60.0
				if hud:
					hud.show_banner("⚡ YAXIN KECID! (+60 XAL)", Color(1.0, 0.9, 0.1), 1.3)
				_play_sfx(880.0, 0.10, false)

		# Collision check (Ignore if jumping high over the car!)
		if dx < 1.72 and dz < hit_len and p_pos.y < 1.35:
			if float(player_car.get("invulnerable_timer")) <= 0.0:
				var cur_armor: float = float(player_car.get("armor_health")) - 35.0
				player_car.set("armor_health", maxf(0.0, cur_armor))
				player_car.set("invulnerable_timer", 1.4)
				player_car.set("speed_kmh", maxf(70.0, p_speed * 0.65))
				if chase_cam and chase_cam.has_method("add_shake"):
					chase_cam.call("add_shake", 0.75)
				_play_sfx(140.0, 0.35, true)

				if cur_armor <= 0.0:
					_trigger_game_over()
					return
				elif hud:
					hud.show_banner("💥 TOQQUSMA! ZIREH: %d%%" % int(cur_armor), Color(1.0, 0.25, 0.25), 1.8)

		if t_node.position.z > 32.0:
			t_node.queue_free()
			traffic_list.remove_at(i)

	# 4. Update Pickups & Ramps
	for i in range(pickup_list.size() - 1, -1, -1):
		var p_item: Dictionary = pickup_list[i]
		var p_node: Node3D = p_item["node"]
		var p_type: String = String(p_item["type"])
		p_node.position.z += world_step

		if p_type != "ramp":
			p_node.rotation.y += delta * 3.2

		var dx: float = absf(p_node.position.x - p_pos.x)
		var dz: float = absf(p_node.position.z - p_pos.z)

		if dx < 1.85 and dz < 2.4:
			if p_type == "coin":
				coins += 1
				score += 150.0
				if hud:
					hud.show_banner("💰 SIKKE TOPLANDI! (+150 XAL)", Color(1.0, 0.85, 0.1), 1.2)
				_play_sfx(1046.5, 0.14, false)
				p_node.queue_free()
				pickup_list.remove_at(i)
				continue
			elif p_type == "nitro":
				var cur_n: float = float(player_car.get("nitro_amount"))
				player_car.set("nitro_amount", minf(100.0, cur_n + 40.0))
				score += 75.0
				if hud:
					hud.show_banner("⚡ NITRO BALONU! (+40% NITRO)", Color(0.0, 0.95, 1.0), 1.4)
				_play_sfx(1318.5, 0.16, false)
				p_node.queue_free()
				pickup_list.remove_at(i)
				continue
			elif p_type == "repair":
				var cur_a: float = float(player_car.get("armor_health"))
				player_car.set("armor_health", minf(100.0, cur_a + 35.0))
				score += 75.0
				if hud:
					hud.show_banner("🛡️ ZIREH TEMIR OLUNDU! (+35%)", Color(0.2, 1.0, 0.45), 1.4)
				_play_sfx(659.2, 0.18, false)
				p_node.queue_free()
				pickup_list.remove_at(i)
				continue
			elif p_type == "ramp" and not p_airborne:
				player_car.call("launch_jump", 9.8)
				score += 200.0
				if hud:
					hud.show_banner("✈️ TRAMPLIN TULLANISI! (+200 XAL)", Color(1.0, 0.6, 0.1), 1.8)
				_play_sfx(523.2, 0.22, false)

		if p_node.position.z > 30.0:
			p_node.queue_free()
			pickup_list.remove_at(i)

	# 5. Spawning Timers
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_traffic_vehicle(-320.0 - randf_range(0.0, 45.0))
		spawn_timer = maxf(0.42, 1.15 - float(level) * 0.06)

	pickup_timer -= delta
	if pickup_timer <= 0.0:
		_spawn_pickup_item(-310.0 - randf_range(0.0, 40.0))
		pickup_timer = randf_range(1.1, 2.0)

	# 6. Update Camera & HUD
	if chase_cam and chase_cam.has_method("update_camera"):
		chase_cam.call("update_camera", delta)

	if hud:
		hud.call(
			"update_dashboard",
			p_speed,
			int(player_car.get("current_gear")),
			float(player_car.get("nitro_amount")),
			float(player_car.get("armor_health")),
			int(score),
			high_score,
			level,
			coins,
			distance_km
		)

func _handle_shortcuts() -> void:
	if Input.is_action_just_pressed("camera_mode") and chase_cam:
		var mode_name: String = String(chase_cam.call("cycle_camera_mode"))
		if hud:
			hud.show_banner("📷 " + mode_name, Color(0.5, 0.9, 1.0), 1.5)

	if Input.is_action_just_pressed("paint_color") and player_car:
		var color_name: String = String(player_car.call("cycle_paint_color"))
		if hud:
			hud.show_banner("🎨 MASIN RENGI: " + color_name, Color(1.0, 0.85, 0.2), 1.5)

	if Input.is_action_just_pressed("toggle_theme"):
		theme_index = (theme_index + 1) % 3
		_apply_lighting_theme()

func _apply_lighting_theme() -> void:
	if not world_env or not world_env.environment:
		return
	var env: Environment = world_env.environment
	var sky_mat := env.sky.sky_material as ProceduralSkyMaterial
	if not sky_mat:
		return

	if theme_index == 0:
		# Neon Night
		sky_mat.sky_top_color = Color(0.04, 0.07, 0.16)
		sky_mat.sky_horizon_color = Color(0.12, 0.18, 0.34)
		sun_light.light_energy = 0.85
		if hud:
			hud.show_banner("🌙 REJIM: NEON GECE", Color(0.3, 0.85, 1.0), 1.5)
	elif theme_index == 1:
		# Sunset Horizon
		sky_mat.sky_top_color = Color(0.18, 0.08, 0.28)
		sky_mat.sky_horizon_color = Color(0.95, 0.42, 0.18)
		sun_light.light_energy = 1.25
		if hud:
			hud.show_banner("🌇 REJIM: QURUB UFUGU (SUNSET)", Color(1.0, 0.6, 0.2), 1.5)
	else:
		# Bright Day
		sky_mat.sky_top_color = Color(0.18, 0.48, 0.88)
		sky_mat.sky_horizon_color = Color(0.65, 0.82, 0.98)
		sun_light.light_energy = 1.6
		if hud:
			hud.show_banner("☀️ REJIM: GUNDUZ SURUSU", Color(1.0, 0.95, 0.4), 1.5)

func _trigger_game_over() -> void:
	is_game_over = true
	_save_high_score()
	if hud:
		hud.call("show_game_over", int(score), high_score, coins, distance_km)

func _restart_game() -> void:
	is_game_over = false
	score = 0.0
	coins = 0
	level = 1
	distance_km = 0.0

	for item in traffic_list:
		var n: Node3D = item["node"]
		if is_instance_valid(n):
			n.queue_free()
	traffic_list.clear()

	for p_item in pickup_list:
		var n: Node3D = p_item["node"]
		if is_instance_valid(n):
			n.queue_free()
	pickup_list.clear()

	if player_car and player_car.has_method("reset_vehicle"):
		player_car.call("reset_vehicle")

	_spawn_initial_entities()

	if hud:
		hud.call("hide_game_over")
		hud.show_banner("YENIDEN BASLANDI! UGURLAR!", Color(0.2, 1.0, 0.5), 2.0)

func _load_high_score() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		high_score = int(cfg.get_value("stats", "high_score", 0))

func _save_high_score() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("stats", "high_score", high_score)
	cfg.save(SAVE_PATH)

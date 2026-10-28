extends Node3D

# ============================================================================
# HOPE 3D RACING - NEXT-GEN PBR WORLD & CYBERPUNK HIGHWAY (Godot 4.7)
# Wet-Look Reflective Asphalt + Neon Arches + City Skyline + Detailed Traffic
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
var police_flash_time: float = 0.0

# Road & Entities
var road_segments: Array[Node3D] = []
var traffic_list: Array[Dictionary] = []
var pickup_list: Array[Dictionary] = []
var spawn_timer: float = 0.0
var pickup_timer: float = 0.0
var horizon_sun: Node3D

# Shared PBR & HDR Emissive Materials
var mat_asphalt: StandardMaterial3D
var mat_shoulder: StandardMaterial3D
var mat_terrain: StandardMaterial3D
var mat_line: StandardMaterial3D
var mat_reflector_amber: StandardMaterial3D
var mat_curb_cyan: StandardMaterial3D
var mat_curb_magenta: StandardMaterial3D
var mat_guardrail: StandardMaterial3D
var mat_arch_steel: StandardMaterial3D
var mat_building_dark: StandardMaterial3D
var mat_window_cyan: StandardMaterial3D
var mat_window_magenta: StandardMaterial3D
var mat_window_gold: StandardMaterial3D
var mat_tree_trunk: StandardMaterial3D
var mat_tree_leaves: StandardMaterial3D
var mat_lamp_glow: StandardMaterial3D
var mat_tail_red: StandardMaterial3D
var mat_head_white: StandardMaterial3D
var mat_police_blue: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_tire: StandardMaterial3D
var mat_rim: StandardMaterial3D
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
	_create_horizon_monument()
	_build_highway_segments()
	_spawn_initial_entities()

	if hud:
		hud.connect("restart_requested", Callable(self, "_restart_game"))
		hud.show_banner("⚡ HOPE 3D ULTRA — NEXT-GEN EDITION ⚡", Color(0.0, 0.96, 1.0), 2.6)

func _init_shared_materials() -> void:
	# Procedural Micro-Grain Normal Map for Wet Reflective Asphalt
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.14
	var normal_tex := NoiseTexture2D.new()
	normal_tex.width = 256
	normal_tex.height = 256
	normal_tex.seamless = true
	normal_tex.as_normal_map = true
	normal_tex.bump_strength = 3.5
	normal_tex.noise = noise

	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.07, 0.08, 0.11)
	mat_asphalt.metallic = 0.42
	mat_asphalt.roughness = 0.22
	mat_asphalt.clearcoat_enabled = true
	mat_asphalt.clearcoat = 0.75
	mat_asphalt.clearcoat_roughness = 0.14
	mat_asphalt.normal_enabled = true
	mat_asphalt.normal_scale = 0.35
	mat_asphalt.normal_texture = normal_tex
	mat_asphalt.uv1_scale = Vector3(8.0, 24.0, 1.0)

	mat_shoulder = StandardMaterial3D.new()
	mat_shoulder.albedo_color = Color(0.11, 0.13, 0.18)
	mat_shoulder.metallic = 0.3
	mat_shoulder.roughness = 0.45

	mat_terrain = StandardMaterial3D.new()
	mat_terrain.albedo_color = Color(0.03, 0.05, 0.09)
	mat_terrain.roughness = 0.88

	mat_line = StandardMaterial3D.new()
	mat_line.albedo_color = Color(0.95, 0.98, 1.0)
	mat_line.emission_enabled = true
	mat_line.emission = Color(0.6, 0.8, 1.0)
	mat_line.emission_energy_multiplier = 1.4

	mat_reflector_amber = StandardMaterial3D.new()
	mat_reflector_amber.albedo_color = Color(1.0, 0.75, 0.1)
	mat_reflector_amber.emission_enabled = true
	mat_reflector_amber.emission = Color(1.0, 0.65, 0.0)
	mat_reflector_amber.emission_energy_multiplier = 4.0

	mat_curb_cyan = StandardMaterial3D.new()
	mat_curb_cyan.albedo_color = Color(0.0, 0.92, 1.0)
	mat_curb_cyan.emission_enabled = true
	mat_curb_cyan.emission = Color(0.0, 0.85, 1.0)
	mat_curb_cyan.emission_energy_multiplier = 2.8

	mat_curb_magenta = StandardMaterial3D.new()
	mat_curb_magenta.albedo_color = Color(1.0, 0.08, 0.45)
	mat_curb_magenta.emission_enabled = true
	mat_curb_magenta.emission = Color(1.0, 0.06, 0.4)
	mat_curb_magenta.emission_energy_multiplier = 2.8

	mat_guardrail = StandardMaterial3D.new()
	mat_guardrail.albedo_color = Color(0.62, 0.70, 0.82)
	mat_guardrail.metallic = 0.88
	mat_guardrail.roughness = 0.2

	mat_arch_steel = StandardMaterial3D.new()
	mat_arch_steel.albedo_color = Color(0.12, 0.15, 0.22)
	mat_arch_steel.metallic = 0.82
	mat_arch_steel.roughness = 0.25

	mat_building_dark = StandardMaterial3D.new()
	mat_building_dark.albedo_color = Color(0.05, 0.07, 0.12)
	mat_building_dark.metallic = 0.65
	mat_building_dark.roughness = 0.3

	mat_window_cyan = StandardMaterial3D.new()
	mat_window_cyan.albedo_color = Color(0.0, 0.92, 1.0)
	mat_window_cyan.emission_enabled = true
	mat_window_cyan.emission = Color(0.0, 0.85, 1.0)
	mat_window_cyan.emission_energy_multiplier = 3.2

	mat_window_magenta = StandardMaterial3D.new()
	mat_window_magenta.albedo_color = Color(1.0, 0.15, 0.55)
	mat_window_magenta.emission_enabled = true
	mat_window_magenta.emission = Color(1.0, 0.12, 0.5)
	mat_window_magenta.emission_energy_multiplier = 3.2

	mat_window_gold = StandardMaterial3D.new()
	mat_window_gold.albedo_color = Color(1.0, 0.78, 0.2)
	mat_window_gold.emission_enabled = true
	mat_window_gold.emission = Color(1.0, 0.7, 0.1)
	mat_window_gold.emission_energy_multiplier = 2.8

	mat_tree_trunk = StandardMaterial3D.new()
	mat_tree_trunk.albedo_color = Color(0.22, 0.14, 0.08)

	mat_tree_leaves = StandardMaterial3D.new()
	mat_tree_leaves.albedo_color = Color(0.06, 0.42, 0.32)
	mat_tree_leaves.roughness = 0.65

	mat_lamp_glow = StandardMaterial3D.new()
	mat_lamp_glow.albedo_color = Color(0.75, 0.98, 1.0)
	mat_lamp_glow.emission_enabled = true
	mat_lamp_glow.emission = Color(0.45, 0.92, 1.0)
	mat_lamp_glow.emission_energy_multiplier = 4.5

	mat_tail_red = StandardMaterial3D.new()
	mat_tail_red.albedo_color = Color(1.0, 0.05, 0.18)
	mat_tail_red.emission_enabled = true
	mat_tail_red.emission = Color(1.0, 0.04, 0.15)
	mat_tail_red.emission_energy_multiplier = 4.2

	mat_head_white = StandardMaterial3D.new()
	mat_head_white.albedo_color = Color(0.95, 0.98, 1.0)
	mat_head_white.emission_enabled = true
	mat_head_white.emission = Color(0.8, 0.95, 1.0)
	mat_head_white.emission_energy_multiplier = 3.8

	mat_police_blue = StandardMaterial3D.new()
	mat_police_blue.albedo_color = Color(0.05, 0.45, 1.0)
	mat_police_blue.emission_enabled = true
	mat_police_blue.emission = Color(0.05, 0.5, 1.0)
	mat_police_blue.emission_energy_multiplier = 5.0

	mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.04, 0.06, 0.11)
	mat_glass.metallic = 0.95
	mat_glass.roughness = 0.05
	mat_glass.clearcoat_enabled = true

	mat_tire = StandardMaterial3D.new()
	mat_tire.albedo_color = Color(0.08, 0.08, 0.1)
	mat_tire.roughness = 0.82

	mat_rim = StandardMaterial3D.new()
	mat_rim.albedo_color = Color(0.88, 0.92, 0.98)
	mat_rim.metallic = 0.95
	mat_rim.roughness = 0.12

	mat_coin = StandardMaterial3D.new()
	mat_coin.albedo_color = Color(1.0, 0.8, 0.05)
	mat_coin.metallic = 0.92
	mat_coin.roughness = 0.1
	mat_coin.emission_enabled = true
	mat_coin.emission = Color(1.0, 0.72, 0.0)
	mat_coin.emission_energy_multiplier = 2.6

	mat_nitro_orb = StandardMaterial3D.new()
	mat_nitro_orb.albedo_color = Color(0.0, 0.96, 1.0)
	mat_nitro_orb.emission_enabled = true
	mat_nitro_orb.emission = Color(0.0, 0.9, 1.0)
	mat_nitro_orb.emission_energy_multiplier = 4.2

	mat_repair_orb = StandardMaterial3D.new()
	mat_repair_orb.albedo_color = Color(0.15, 1.0, 0.45)
	mat_repair_orb.emission_enabled = true
	mat_repair_orb.emission = Color(0.1, 0.95, 0.4)
	mat_repair_orb.emission_energy_multiplier = 3.8

	mat_ramp = StandardMaterial3D.new()
	mat_ramp.albedo_color = Color(1.0, 0.45, 0.0)
	mat_ramp.emission_enabled = true
	mat_ramp.emission = Color(1.0, 0.38, 0.0)
	mat_ramp.emission_energy_multiplier = 2.2

	var traffic_colors: Array[Color] = [
		Color(0.95, 0.08, 0.22),
		Color(1.0, 0.52, 0.02),
		Color(0.06, 0.85, 0.42),
		Color(0.55, 0.18, 0.98),
		Color(0.92, 0.95, 1.0),
		Color(0.08, 0.48, 0.98),
	]
	for col in traffic_colors:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.metallic = 0.85
		m.roughness = 0.14
		m.clearcoat_enabled = true
		m.clearcoat = 1.0
		m.clearcoat_roughness = 0.05
		traffic_paint_mats.append(m)

func _create_horizon_monument() -> void:
	# Giant Synthwave Glowing Sun Disc & City Horizon Silhouette
	horizon_sun = Node3D.new()
	horizon_sun.name = "HorizonMonument"
	horizon_sun.position = Vector3(0.0, 42.0, -440.0)

	var sun_mat := StandardMaterial3D.new()
	sun_mat.albedo_color = Color(1.0, 0.28, 0.55)
	sun_mat.emission_enabled = true
	sun_mat.emission = Color(1.0, 0.22, 0.48)
	sun_mat.emission_energy_multiplier = 3.2

	var sun_disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 46.0
	cyl.bottom_radius = 46.0
	cyl.height = 1.0
	cyl.radial_segments = 48
	cyl.material = sun_mat
	sun_disc.mesh = cyl
	sun_disc.rotation.x = PI * 0.5
	horizon_sun.add_child(sun_disc)

	# Glowing Outer Halo Ring
	var ring_disc := MeshInstance3D.new()
	var r_cyl := CylinderMesh.new()
	r_cyl.top_radius = 54.0
	r_cyl.bottom_radius = 54.0
	r_cyl.height = 0.4
	r_cyl.radial_segments = 48
	r_cyl.material = mat_curb_cyan
	ring_disc.mesh = r_cyl
	ring_disc.rotation.x = PI * 0.5
	ring_disc.position.z = -1.5
	horizon_sun.add_child(ring_disc)

	add_child(horizon_sun)

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

	# 1. Wet Reflective PBR Asphalt Surface
	var road_mesh := MeshInstance3D.new()
	var road_box := BoxMesh.new()
	road_box.size = Vector3(ROAD_WIDTH, 0.2, SEGMENT_LENGTH)
	road_box.material = mat_asphalt
	road_mesh.mesh = road_box
	road_mesh.position = Vector3(0.0, -0.1, 0.0)
	seg.add_child(road_mesh)

	# 2. Left & Right Shoulders, Guardrails & Terrain
	for side in [-1.0, 1.0]:
		var shoulder := MeshInstance3D.new()
		var sbox := BoxMesh.new()
		sbox.size = Vector3(2.2, 0.21, SEGMENT_LENGTH)
		sbox.material = mat_shoulder
		shoulder.mesh = sbox
		shoulder.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.1), -0.11, 0.0)
		seg.add_child(shoulder)

		var terr := MeshInstance3D.new()
		var tbox := BoxMesh.new()
		tbox.size = Vector3(110.0, 0.2, SEGMENT_LENGTH)
		tbox.material = mat_terrain
		terr.mesh = tbox
		terr.position = Vector3(side * (ROAD_WIDTH * 0.5 + 57.0), -0.18, 0.0)
		seg.add_child(terr)

		# Neon Racing Curbs
		var curb := MeshInstance3D.new()
		var cbox := BoxMesh.new()
		cbox.size = Vector3(0.55, 0.34, SEGMENT_LENGTH)
		cbox.material = mat_curb_cyan if (idx % 2 == 0) else mat_curb_magenta
		curb.mesh = cbox
		curb.position = Vector3(side * (ROAD_WIDTH * 0.5 + 0.28), 0.11, 0.0)
		seg.add_child(curb)

		# Double Corrugated Metallic Guardrails
		for rail_y in [0.42, 0.78]:
			var rail := MeshInstance3D.new()
			var rbox := BoxMesh.new()
			rbox.size = Vector3(0.18, 0.22, SEGMENT_LENGTH)
			rbox.material = mat_guardrail
			rail.mesh = rbox
			rail.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.05), rail_y, 0.0)
			seg.add_child(rail)

	# 3. Dashed Lane Markings + Cat's-Eye Glowing Reflector Studs
	var dash_box := BoxMesh.new()
	dash_box.size = Vector3(0.22, 0.04, 4.4)
	dash_box.material = mat_line

	var stud_box := BoxMesh.new()
	stud_box.size = Vector3(0.16, 0.08, 0.26)
	stud_box.material = mat_reflector_amber

	for lane_div in [-3.9, 0.0, 3.9]:
		var z_pos: float = -SEGMENT_LENGTH * 0.5 + 4.5
		while z_pos < SEGMENT_LENGTH * 0.5:
			var dash := MeshInstance3D.new()
			dash.mesh = dash_box
			dash.position = Vector3(lane_div, 0.02, z_pos)
			seg.add_child(dash)

			var stud := MeshInstance3D.new()
			stud.mesh = stud_box
			stud.position = Vector3(lane_div, 0.04, z_pos + 4.8)
			seg.add_child(stud)
			z_pos += 10.5

	# 4. Futuristic Overhead Neon Highway Gantry Arch (Every 2nd segment)
	if idx % 2 == 0:
		var arch_root := Node3D.new()
		for side in [-1.0, 1.0]:
			var pillar := MeshInstance3D.new()
			var p_box := BoxMesh.new()
			p_box.size = Vector3(0.65, 9.2, 0.85)
			p_box.material = mat_arch_steel
			pillar.mesh = p_box
			pillar.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.6), 4.6, 0.0)
			arch_root.add_child(pillar)

		var crossbeam := MeshInstance3D.new()
		var cb_box := BoxMesh.new()
		cb_box.size = Vector3(ROAD_WIDTH + 4.0, 0.75, 0.9)
		cb_box.material = mat_arch_steel
		crossbeam.mesh = cb_box
		crossbeam.position = Vector3(0.0, 9.0, 0.0)
		arch_root.add_child(crossbeam)

		var neon_beam := MeshInstance3D.new()
		var nb_box := BoxMesh.new()
		nb_box.size = Vector3(ROAD_WIDTH + 2.8, 0.22, 0.98)
		nb_box.material = mat_curb_cyan if (idx % 4 == 0) else mat_curb_magenta
		neon_beam.mesh = nb_box
		neon_beam.position = Vector3(0.0, 8.55, 0.0)
		arch_root.add_child(neon_beam)
		seg.add_child(arch_root)

	# 5. Streetlights, Trees & Illuminated Cyberpunk City Skyscrapers
	var win_mats: Array[StandardMaterial3D] = [mat_window_cyan, mat_window_magenta, mat_window_gold]
	for z_step in [-18.0, 18.0]:
		for side in [-1.0, 1.0]:
			# Curved Streetlamp
			var pole := MeshInstance3D.new()
			var pmesh := CylinderMesh.new()
			pmesh.top_radius = 0.09
			pmesh.bottom_radius = 0.14
			pmesh.height = 6.8
			pmesh.material = mat_guardrail
			pole.mesh = pmesh
			pole.position = Vector3(side * (ROAD_WIDTH * 0.5 + 2.2), 3.4, z_step)
			seg.add_child(pole)

			var arm := MeshInstance3D.new()
			var amesh := BoxMesh.new()
			amesh.size = Vector3(1.8, 0.12, 0.18)
			amesh.material = mat_guardrail
			arm.mesh = amesh
			arm.position = Vector3(side * (ROAD_WIDTH * 0.5 + 1.4), 6.75, z_step)
			seg.add_child(arm)

			var bulb := MeshInstance3D.new()
			var bmesh := BoxMesh.new()
			bmesh.size = Vector3(1.1, 0.18, 0.42)
			bmesh.material = mat_lamp_glow
			bulb.mesh = bmesh
			bulb.position = Vector3(side * (ROAD_WIDTH * 0.5 + 0.95), 6.62, z_step)
			seg.add_child(bulb)

			# Cyberpunk Skyscraper Tower in the Midground
			var b_height: float = 18.0 + float(((idx * 7 + int(absf(z_step))) % 5) * 8)
			var b_width: float = 6.5 + float((idx % 3) * 2)
			var b_x: float = side * (ROAD_WIDTH * 0.5 + 19.0 + float((idx * 5) % 14))

			var tower := MeshInstance3D.new()
			var tw_box := BoxMesh.new()
			tw_box.size = Vector3(b_width, b_height, b_width)
			tw_box.material = mat_building_dark
			tower.mesh = tw_box
			tower.position = Vector3(b_x, b_height * 0.5, z_step)
			seg.add_child(tower)

			# Glowing Neon Window Strips & Roof Crown on Skyscraper
			var win_mat: StandardMaterial3D = win_mats[(idx + int(side > 0.0)) % win_mats.size()]
			var crown := MeshInstance3D.new()
			var cr_box := BoxMesh.new()
			cr_box.size = Vector3(b_width + 0.25, 0.45, b_width + 0.25)
			cr_box.material = win_mat
			crown.mesh = cr_box
			crown.position = Vector3(b_x, b_height - 0.5, z_step)
			seg.add_child(crown)

			for w_y in [0.35, 0.62, 0.82]:
				var band := MeshInstance3D.new()
				var bd_box := BoxMesh.new()
				bd_box.size = Vector3(b_width + 0.12, 0.28, b_width * 0.75)
				bd_box.material = win_mat
				band.mesh = bd_box
				band.position = Vector3(b_x, b_height * w_y, z_step)
				seg.add_child(band)

	return seg

func _spawn_initial_entities() -> void:
	for i in range(1, 7):
		_spawn_traffic_vehicle(-65.0 - float(i) * 50.0)
		if i % 2 == 0:
			_spawn_pickup_item(-50.0 - float(i) * 44.0)

func _spawn_traffic_vehicle(z_pos: float) -> void:
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
	var roll_type: float = randf()
	var is_truck: bool = (roll_type < 0.22)
	var is_police: bool = (not is_truck and roll_type < 0.40)
	var paint_mat: StandardMaterial3D = (
		mat_building_dark if is_police else traffic_paint_mats[randi() % traffic_paint_mats.size()]
	)

	var vehicle := Node3D.new()
	vehicle.position = Vector3(LANES[chosen_lane], 0.0, z_pos)

	var body_len: float = 6.4 if is_truck else 4.25
	var body_height: float = 1.68 if is_truck else 0.52

	# 1. Sculpted Lower Body
	var chassis := MeshInstance3D.new()
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(2.02, body_height, body_len)
	c_mesh.material = paint_mat
	chassis.mesh = c_mesh
	chassis.position = Vector3(0.0, body_height * 0.5 + 0.34, 0.0)
	vehicle.add_child(chassis)

	# 2. Cabin / Cockpit
	var cabin := MeshInstance3D.new()
	var cab_mesh := BoxMesh.new()
	cab_mesh.size = Vector3(1.62, 0.46, 2.05)
	cab_mesh.material = mat_glass
	cabin.mesh = cab_mesh
	cabin.position = Vector3(0.0, body_height + 0.44, -0.25 if not is_truck else -1.85)
	vehicle.add_child(cabin)

	# 3. Police Lightbar (Red & Blue HDR sirens)
	if is_police:
		var siren_l := MeshInstance3D.new()
		var s_box_l := BoxMesh.new()
		s_box_l.size = Vector3(0.55, 0.14, 0.24)
		s_box_l.material = mat_tail_red
		siren_l.mesh = s_box_l
		siren_l.position = Vector3(-0.32, body_height + 0.72, -0.2)
		vehicle.add_child(siren_l)

		var siren_r := MeshInstance3D.new()
		var s_box_r := BoxMesh.new()
		s_box_r.size = Vector3(0.55, 0.14, 0.24)
		s_box_r.material = mat_police_blue
		siren_r.mesh = s_box_r
		siren_r.position = Vector3(0.32, body_height + 0.72, -0.2)
		vehicle.add_child(siren_r)

	# 4. Four 3D Wheels with Chrome Rims
	var w_cyl := CylinderMesh.new()
	w_cyl.top_radius = 0.38
	w_cyl.bottom_radius = 0.38
	w_cyl.height = 0.32
	w_cyl.material = mat_tire
	var z_wheel_offset: float = body_len * 0.32
	for wx in [-1.02, 1.02]:
		for wz in [-z_wheel_offset, z_wheel_offset]:
			var w_mesh := MeshInstance3D.new()
			w_mesh.mesh = w_cyl
			w_mesh.rotation.z = PI * 0.5
			w_mesh.position = Vector3(wx, 0.38, wz)
			vehicle.add_child(w_mesh)

	# 5. Full-Width Glowing LED Tail Light Bar & Front Headlights
	var tail_bar := MeshInstance3D.new()
	var tb_mesh := BoxMesh.new()
	tb_mesh.size = Vector3(1.88, 0.18, 0.12)
	tb_mesh.material = mat_tail_red
	tail_bar.mesh = tb_mesh
	tail_bar.position = Vector3(0.0, 0.68, body_len * 0.5 + 0.02)
	vehicle.add_child(tail_bar)

	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.42, 0.14, 0.1)
	head_mesh.material = mat_head_white
	for hx in [-0.66, 0.66]:
		var hl := MeshInstance3D.new()
		hl.mesh = head_mesh
		hl.position = Vector3(hx, 0.62, -body_len * 0.5 - 0.02)
		vehicle.add_child(hl)

	entity_container.add_child(vehicle)
	traffic_list.append({
		"node": vehicle,
		"lane_idx": chosen_lane,
		"speed_kmh": randf_range(48.0, 92.0),
		"half_len": body_len * 0.5,
		"passed": false,
	})

func _spawn_pickup_item(z_pos: float) -> void:
	var lane_idx: int = randi() % LANES.size()
	var roll: float = randf()
	var item_type: String = "coin"
	var holder := Node3D.new()
	holder.position = Vector3(LANES[lane_idx], 0.0, z_pos)

	if roll < 0.52:
		item_type = "coin"
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.68
		cyl.bottom_radius = 0.68
		cyl.height = 0.22
		cyl.material = mat_coin
		m.mesh = cyl
		m.rotation.z = PI * 0.5
		m.position.y = 1.05
		holder.add_child(m)
	elif roll < 0.78:
		item_type = "nitro"
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.88, 0.88, 0.88)
		box.material = mat_nitro_orb
		m.mesh = box
		m.position.y = 1.05
		holder.add_child(m)
	elif roll < 0.91:
		item_type = "repair"
		var m := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.58
		sph.height = 1.16
		sph.material = mat_repair_orb
		m.mesh = sph
		m.position.y = 1.05
		holder.add_child(m)
	else:
		item_type = "ramp"
		var m := MeshInstance3D.new()
		var rbox := BoxMesh.new()
		rbox.size = Vector3(2.9, 0.48, 5.4)
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

	# Animate Police Siren & Neon Pulse
	police_flash_time += delta * 14.0
	if mat_police_blue:
		mat_police_blue.emission_energy_multiplier = 3.0 + 3.5 * absf(sin(police_flash_time))

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
		player_car.set("base_cruise_speed", minf(190.0, 120.0 + float(level - 1) * 8.0))
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
					chase_cam.call("add_shake", 0.78)
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
			p_node.rotation.y += delta * 3.4

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
		sky_mat.sky_top_color = Color(0.02, 0.04, 0.11)
		sky_mat.sky_horizon_color = Color(0.14, 0.08, 0.28)
		sun_light.light_energy = 0.95
		if hud:
			hud.show_banner("🌙 REJIM: CYBERPUNK GECE", Color(0.3, 0.85, 1.0), 1.5)
	elif theme_index == 1:
		sky_mat.sky_top_color = Color(0.16, 0.06, 0.26)
		sky_mat.sky_horizon_color = Color(0.98, 0.36, 0.18)
		sun_light.light_energy = 1.35
		if hud:
			hud.show_banner("🌇 REJIM: SYNTHWAVE SUNSET", Color(1.0, 0.6, 0.2), 1.5)
	else:
		sky_mat.sky_top_color = Color(0.14, 0.45, 0.88)
		sky_mat.sky_horizon_color = Color(0.62, 0.82, 0.98)
		sun_light.light_energy = 1.65
		if hud:
			hud.show_banner("☀️ REJIM: PARLAQ GUNDUZ", Color(1.0, 0.95, 0.4), 1.5)

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

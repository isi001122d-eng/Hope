extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 6.8
@export var follow_height: float = 2.8
@export var look_ahead_distance: float = 6.0
@export var position_damp: float = 8.0
@export var rotation_damp: float = 5.0

var target: VehicleBody3D

func _ready() -> void:
	if has_node(target_path):
		target = get_node(target_path) as VehicleBody3D

func _physics_process(delta: float) -> void:
	if not target:
		return
		
	# Ideal camera position behind the car
	var target_transform = target.global_transform
	var forward = -target_transform.basis.z
	var up = target_transform.basis.y
	
	var desired_pos = target_transform.origin - forward * follow_distance + Vector3.UP * follow_height
	global_position = global_position.lerp(desired_pos, position_damp * delta)
	
	# Look ahead of the car
	var look_target = target_transform.origin + forward * look_ahead_distance + Vector3.UP * 1.0
	look_at(look_target, Vector3.UP)
	
	# Nitro FOV dynamic expansion
	var target_fov = 85.0 if target.is_nitro else 70.0
	fov = lerp(fov, target_fov, 4.0 * delta)

extends Control

@export var car_path: NodePath
var car: VehicleBody3D

@onready var speed_label: Label = $SpeedLabel
@onready var nitro_bar: ProgressBar = $NitroBar

func _ready() -> void:
	if has_node(car_path):
		car = get_node(car_path) as VehicleBody3D

func _process(_delta: float) -> void:
	if not car:
		return
	
	if speed_label:
		speed_label.text = "%d KM/H" % int(car.speed_kmh)
	if nitro_bar:
		nitro_bar.value = car.nitro_amount

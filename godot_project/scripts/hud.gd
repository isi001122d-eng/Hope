extends Control

# ============================================================================
# HOPE 3D RACING - HUD & OVERLAY CONTROLLER (Godot 4.7)
# ============================================================================

signal restart_requested

@onready var score_label: Label = $TopLeftPanel/VBox/ScoreLabel
@onready var high_score_label: Label = $TopLeftPanel/VBox/HighScoreLabel
@onready var meta_label: Label = $TopLeftPanel/VBox/MetaLabel
@onready var status_banner: Label = $StatusBanner
@onready var speed_label: Label = $BottomRightPanel/SpeedLabel
@onready var gear_label: Label = $BottomRightPanel/GearLabel
@onready var nitro_bar: ProgressBar = $BottomRightPanel/NitroBar
@onready var armor_bar: ProgressBar = $BottomRightPanel/ArmorBar
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_stats_label: Label = $GameOverPanel/VBox/FinalStatsLabel
@onready var restart_btn: Button = $GameOverPanel/VBox/RestartButton

var banner_timer: float = 0.0

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)

func _process(delta: float) -> void:
	if banner_timer > 0.0:
		banner_timer = maxf(0.0, banner_timer - delta)
		if status_banner:
			status_banner.visible = true
	elif status_banner:
		status_banner.visible = false

func show_banner(msg: String, color: Color = Color(1.0, 0.9, 0.2), duration: float = 2.0) -> void:
	if status_banner:
		status_banner.text = msg
		status_banner.modulate = color
		status_banner.visible = true
		banner_timer = duration

func update_dashboard(
	speed_kmh: float,
	gear: int,
	nitro: float,
	armor: float,
	score: int,
	high_score: int,
	level: int,
	coins: int,
	distance_km: float
) -> void:
	if speed_label:
		speed_label.text = "%03d KM/H" % int(speed_kmh)
	if gear_label:
		gear_label.text = "OTURME: G%d" % gear
	if nitro_bar:
		nitro_bar.value = nitro
	if armor_bar:
		armor_bar.value = armor
	if score_label:
		score_label.text = "XAL (SCORE): %d" % score
	if high_score_label:
		high_score_label.text = "REKORD (BEST): %d" % high_score
	if meta_label:
		meta_label.text = "LVL: %d  |  SIKKE: %d  |  %.2f km" % [level, coins, distance_km]

func show_game_over(score: int, high_score: int, coins: int, distance_km: float) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if final_stats_label:
		final_stats_label.text = (
			"Yekun Xal: %d\nRekord Xal: %d\nToplanan Sikke: %d  |  Mesafe: %.2f km\n\nYeniden baslamaq ucun [R] ve ya [SPACE] basin"
			% [score, high_score, coins, distance_km]
		)

func hide_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = false

func _on_restart_pressed() -> void:
	emit_signal("restart_requested")

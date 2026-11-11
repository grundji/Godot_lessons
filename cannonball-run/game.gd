extends Node3D

const CannonScene = preload("res://scenes/Cannon.tscn")
const SAVE_PATH = "user://cannonball_highscore.save"

const MIN_POWER: float = 12.0
const MAX_POWER: float = 30.0
const CHARGE_RATE: float = 15.0 # Power units per second while holding
const BASE_DISTANCE: float = 12.0 # Starting cannon-to-cannon distance
const DISTANCE_SCALE: float = 0.8 # Extra distance per successful catch

var score: int = 0
var combo: int = 0
var high_score: int = 0
var charge_power: float = 0.0
var is_charging: bool = false
var is_flying: bool = false
var current_cannon: Node3D = null # The cannon the ball is loaded in
var next_cannon: Node3D = null # The target cannon

@onready var cannonball = $Cannonball
@onready var start_cannon = $StartCannon
@onready var arc_preview = $ArcPreview
@onready var score_label = $UI/ScoreLabel
@onready var combo_label = $UI/ComboLabel
@onready var power_bar = $UI/PowerBar
@onready var game_over_panel = $UI/GameOverPanel

func _ready() -> void:
	_load_high_score()
	cannonball.add_to_group("cannonball")
	cannonball.caught_by_cannon.connect(_on_ball_caught)
	cannonball.fell_out.connect(_on_ball_fell)
	current_cannon = $StartCannon
	next_cannon = $NextCannon
	_place_next_cannon()
	current_cannon.aim_at(next_cannon.global_position)
	cannonball.global_position = current_cannon.get_muzzle_position()

func _process(delta: float) -> void:
	if is_flying:
		return
	if Input.is_action_pressed("charge_fire") and not is_flying:
		is_charging = true
		charge_power = min(charge_power + CHARGE_RATE * delta, MAX_POWER)
		_update_power_bar()
		# Update arc preview
		var vel = current_cannon.calc_launch_velocity(next_cannon.global_position, charge_power)
		arc_preview.update_arc(current_cannon.get_muzzle_position(), vel)
	if Input.is_action_just_released("charge_fire") and is_charging:
		_fire()

func _fire() -> void:
	is_charging = false
	is_flying = true
	arc_preview.hide_arc()
	charge_power = max(charge_power, MIN_POWER)
	var vel = current_cannon.calc_launch_velocity(next_cannon.global_position, charge_power)
	cannonball.launch(vel)
	charge_power = 0.0
	_update_power_bar()

func _on_ball_caught() -> void:
	is_flying = false
	score += 1 + combo
	combo += 1
	score_label.text = str(score)
	combo_label.text = "x%d COMBO" % combo if combo > 1 else ""
	# Spawn a new next cannon further away
	current_cannon = next_cannon
	next_cannon = CannonScene.instantiate()
	add_child(next_cannon)
	next_cannon.ball_caught.connect(_on_ball_caught_ignore)
	_place_next_cannon()
	current_cannon.aim_at(next_cannon.global_position)

func _on_ball_caught_ignore() -> void:
	pass # Handled by cannonball's caught_by_cannon signal

func _place_next_cannon() -> void:
	var dist = BASE_DISTANCE + score * DISTANCE_SCALE
	var angle = randf_range(-0.6, 0.6) # Radians of horizontal spread
	var height = randf_range(-3.0, 4.0) # Vertical offset
	var offset = Vector3(sin(angle) * dist, height, -cos(angle) * dist)
	next_cannon.global_position = current_cannon.global_position + offset

func _on_ball_fell() -> void:
	combo = 0
	if score > high_score:
		high_score = score
		_save_high_score()
	game_over_panel.visible = true
	# Update game over labels
	$UI/GameOverPanel/ScoreVal.text = str(score)
	$UI/GameOverPanel/BestVal.text = str(high_score)

func _update_power_bar() -> void:
	var pct = (charge_power - MIN_POWER) / (MAX_POWER - MIN_POWER)
	power_bar.size.x = clamp(pct, 0.0, 1.0) * 200.0

func _input(event: InputEvent) -> void:
	if game_over_panel.visible and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func _save_high_score() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(str(high_score))
		f.close()

func _load_high_score() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		high_score = int(f.get_as_text())
		f.close()

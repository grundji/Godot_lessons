extends Node3D

const CloudSheepScene = preload("res://scenes/CloudSheep.tscn")
const SHEEP_COUNT: int = 8
const TIME_LIMIT: float = 180.0 # 3 minutes
const SPAWN_RADIUS: float = 10.0

var time_remaining: float = TIME_LIMIT
var sheep_penned: int = 0
var game_active: bool = true

@onready var sun: DirectionalLight3D = $Sun
@onready var pen: Node3D = $Pen
@onready var sheep_label: Label = $UI/SheepLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var win_panel: Panel = $UI/WinPanel
@onready var lose_panel: Panel = $UI/LosePanel

func _ready() -> void:
	pen.sheep_penned.connect(_on_sheep_penned)
	_spawn_sheep()

func _spawn_sheep() -> void:
	for i in SHEEP_COUNT:
		var s = CloudSheepScene.instantiate()
		add_child(s)
		# Scatter sheep randomly in a sphere around centre
		var rnd = Vector3(
			randf_range(-SPAWN_RADIUS, SPAWN_RADIUS),
			randf_range(-4.0, 4.0),
			randf_range(-SPAWN_RADIUS, SPAWN_RADIUS)
		)
		s.global_position = rnd

func _process(delta: float) -> void:
	if not game_active:
		return
	# Count down
	time_remaining -= delta
	_update_timer_label()
	# Rotate sun to simulate day progressing toward night
	sun.rotation_degrees.x = lerp(-45.0, -160.0, 1.0 - (time_remaining / TIME_LIMIT))
	# Lose condition
	if time_remaining <= 0:
		_trigger_lose()

func _on_sheep_penned(count: int) -> void:
	sheep_penned = count
	sheep_label.text = "Sheep: %d / %d" % [sheep_penned, SHEEP_COUNT]
	if sheep_penned >= SHEEP_COUNT:
		_trigger_win()

func _trigger_win() -> void:
	game_active = false
	win_panel.visible = true
	$UI/WinPanel/TimeVal.text = _format_time(time_remaining)

func _trigger_lose() -> void:
	game_active = false
	lose_panel.visible = true

func _update_timer_label() -> void:
	timer_label.text = _format_time(time_remaining)
	# Turn red when under 30 seconds
	timer_label.modulate = Color.RED if time_remaining < 30.0 else Color.WHITE

func _format_time(t: float) -> String:
	var mins = int(t) / 60
	var secs = int(t) % 60
	return "%d:%02d" % [mins, secs]

func _input(event: InputEvent) -> void:
	if not game_active and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

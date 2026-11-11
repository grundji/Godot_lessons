extends Node2D

const BugScene = preload("res://scenes/Bug.tscn")

# Wave definitions: each entry is { count, speed_mult }
const WAVES: Array[Dictionary] = [
	{ count = 3, speed = 0.8 },
	{ count = 5, speed = 0.9 },
	{ count = 7, speed = 1.0 },
	{ count = 9, speed = 1.1 },
	{ count = 12, speed = 1.2 },
	{ count = 15, speed = 1.35 },
	{ count = 20, speed = 1.5 },
]

var current_wave: int = 0
var bugs_alive: int = 0
var score: int = 0
var game_active: bool = true

@onready var player = $Player
@onready var wave_label = $UI/WaveLabel
@onready var bugs_label = $UI/BugsLabel
@onready var score_label = $UI/ScoreLabel
@onready var countdown_label = $UI/CountdownLabel
@onready var game_over_panel = $UI/GameOverPanel

func _ready() -> void:
	player.died.connect(_on_player_died)
	_start_wave_countdown()

func _start_wave_countdown() -> void:
	var wave_num = current_wave + 1
	wave_label.text = "Wave %d" % wave_num
	var tw = create_tween()
	tw.tween_callback(func(): countdown_label.text = "Wave %d" % wave_num)
	tw.tween_interval(0.8)
	tw.tween_callback(func(): countdown_label.text = "Ready...")
	tw.tween_interval(0.8)
	tw.tween_callback(func(): countdown_label.text = "GO!")
	tw.tween_interval(0.5)
	tw.tween_callback(func(): countdown_label.text = ""; _spawn_wave())

func _spawn_wave() -> void:
	var wave_data = WAVES[min(current_wave, WAVES.size() - 1)]
	bugs_alive = wave_data.count
	bugs_label.text = "Bugs: %d" % bugs_alive
	for i in wave_data.count:
		var bug = BugScene.instantiate()
		add_child(bug)
		bug.speed_mult = wave_data.speed
		# Spawn on a random edge
		bug.global_position = _random_edge_position()
		bug.killed.connect(_on_bug_killed)

func _random_edge_position() -> Vector2:
	var edge = randi() % 4
	match edge:
		0: return Vector2(randf_range(8, 312), 4) # Top
		1: return Vector2(randf_range(8, 312), 236) # Bottom
		2: return Vector2(4, randf_range(8, 232)) # Left
		_: return Vector2(316, randf_range(8, 232)) # Right

func _on_bug_killed() -> void:
	bugs_alive -= 1
	score += 10 * (current_wave + 1) # More points in later waves
	score_label.text = "Score: %d" % score
	bugs_label.text = "Bugs: %d" % bugs_alive
	if bugs_alive <= 0:
		_wave_clear()

func _wave_clear() -> void:
	current_wave += 1
	# Brief celebration then next wave
	countdown_label.text = "Wave Clear!"
	await get_tree().create_timer(1.2).timeout
	countdown_label.text = ""
	_start_wave_countdown()

func _on_player_died() -> void:
	game_active = false
	game_over_panel.visible = true
	$UI/GameOverPanel/ScoreVal.text = str(score)
	$UI/GameOverPanel/WaveVal.text = str(current_wave + 1)

func _input(event: InputEvent) -> void:
	if not game_active and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

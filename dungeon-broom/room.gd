extends Node2D

# ── State ──────────────────────────────────────────────────────────
var total_mess: int = 0      # Set in _ready() by counting Mess nodes
var cleaned_count: int = 0   # Increments each time a Mess emits cleaned
var game_active: bool = true

# ── Node references ─────────────────────────────────────────────────
@onready var player = $Player
@onready var clean_label: Label = $UI/CleanLabel
@onready var tool_label: Label = $UI/ToolLabel
@onready var flash_overlay: ColorRect = $UI/FlashOverlay
@onready var win_label: Label = $UI/WinLabel
@onready var caught_label: Label = $UI/CaughtLabel
@onready var clean_timer: Timer = $CleanTimer
@onready var timer_label: Label = $UI/TimerLabel

func _ready() -> void:
	# Register the player in the 'player' group
	player.add_to_group("player")
	# Connect the player's caught signal
	player.caught.connect(_on_player_caught)
	# Find every Mess node in the scene, count them, connect signals
	var mess_nodes = get_tree().get_nodes_in_group("messes")
	total_mess = mess_nodes.size()
	for mess in mess_nodes:
		mess.cleaned.connect(_on_mess_cleaned)
	# Timer: start the countdown
	clean_timer.timeout.connect(_on_time_up)
	clean_timer.start()
	_update_hud()

func _process(_delta: float) -> void:
	if not game_active:
		return
	# Mirror the player's active tool in the HUD
	tool_label.text = "BROOM" if player.get_tool() == 0 else "MOP"
	# Show remaining time, rounded to whole seconds
	var remaining = int(ceil(clean_timer.time_left))
	timer_label.text = str(remaining)
	# Turn the timer red when fewer than 10 seconds remain
	timer_label.modulate = Color.RED if remaining <= 10 else Color.WHITE

# ── Called each time a Mess node is cleaned ─────────────────────────
func _on_mess_cleaned() -> void:
	cleaned_count += 1
	_update_hud()
	if cleaned_count >= total_mess:
		_trigger_win()

# ── Called when a monster catches the player ────────────────────────
func _on_player_caught() -> void:
	game_active = false
	caught_label.visible = true
	# Red flash
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.65, 0.1)
	tween.tween_interval(0.3)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.4)

func _on_time_up() -> void:
	if not game_active:
		return
	game_active = false
	caught_label.text = "TIME'S UP!  Space to retry"
	caught_label.visible = true
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.5, 0.2)
	tween.tween_interval(0.3)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.5)

func _trigger_win() -> void:
	game_active = false
	win_label.visible = true
	# Golden flash
	flash_overlay.color = Color(1.0, 0.85, 0.0, 0.0)
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.5, 0.3)
	tween.tween_interval(0.5)
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.5)

func _update_hud() -> void:
	var pct = int(float(cleaned_count) / float(maxi(total_mess, 1)) * 100.0)
	clean_label.text = "Clean: %d%%" % pct

func _input(event: InputEvent) -> void:
	if not game_active and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

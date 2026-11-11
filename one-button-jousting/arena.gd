extends Node2D

# ── Match settings ──────────────────────────────────────────────────
const WINS_NEEDED: int = 3        # First to three hits wins the match
const TIE_THRESHOLD: float = 0.12  # Lance angles within this count as a tie
const ROUND_PAUSE: float = 1.8     # Seconds between rounds
const COUNTDOWN_TIME: float = 0.6  # Seconds per countdown number
# ── State ───────────────────────────────────────────────────────────
enum MatchState { COUNTDOWN, CHARGING, RESOLVING, PAUSING, MATCH_OVER }
var match_state: MatchState = MatchState.COUNTDOWN
var p1_score: int = 0
var p2_score: int = 0
var _collision_resolved: bool = false  # Prevent double-resolution
# ── Node references ─────────────────────────────────────────────────
# (knight1/knight2 are left untyped: the arena connects their custom
# collided_with signal and calls react_win/react_lose/react_tie,
# begin_charge, reset_for_round and get_lance_angle, which Godot 4
# rejects through a base-class type)
@onready var knight1 = $Knight1
@onready var knight2 = $Knight2
@onready var p1_score_label: Label = $UI/P1ScoreLabel
@onready var p2_score_label: Label = $UI/P2ScoreLabel
@onready var countdown_label: Label = $UI/CountdownLabel
@onready var result_label: Label = $UI/ResultLabel
@onready var win_label: Label = $UI/WinLabel
@onready var flash_overlay: ColorRect = $UI/FlashOverlay
@onready var camera: Camera2D = $MainCamera

func _ready() -> void:
	# Add knights to the 'knight' group so lance tips can find them
	knight1.add_to_group("knight")
	knight2.add_to_group("knight")
	# Connect collision signals from both knights
	knight1.collided_with.connect(_on_collision)
	knight2.collided_with.connect(_on_collision)
	# Start the first round
	_start_countdown()

func _start_countdown() -> void:
	match_state = MatchState.COUNTDOWN
	_collision_resolved = false
	result_label.text = ""
	countdown_label.visible = true
	# Tween through 3, 2, 1, CHARGE! using tween_callback steps
	var tween = create_tween()
	for n in ["3", "2", "1", "CHARGE!"]:
		tween.tween_callback(func(): countdown_label.text = n)
		tween.tween_interval(COUNTDOWN_TIME if n != "CHARGE!" else COUNTDOWN_TIME * 0.6)
	tween.tween_callback(func():
		countdown_label.text = ""
		countdown_label.visible = false
		_begin_charge()
	)

func _begin_charge() -> void:
	match_state = MatchState.CHARGING
	knight1.begin_charge()
	knight2.begin_charge()

# ── Called when either knight's lance tip hits the other ────────────
func _on_collision(other_knight: Node) -> void:
	# Guard: only resolve once per round
	if _collision_resolved:
		return
	_collision_resolved = true
	match_state = MatchState.RESOLVING
	var a1 = knight1.get_lance_angle()
	var a2 = knight2.get_lance_angle()
	# Flash the screen white on impact
	_screen_flash(Color.WHITE, 0.12)
	# Shake the camera
	_screenshake(6.0, 0.25)
	if abs(a1 - a2) <= TIE_THRESHOLD:
		# ── Tie: both knocked back, no score ─────────────────
		result_label.text = "TIE!"
		knight1.react_tie()
		knight2.react_tie()
		await get_tree().create_timer(ROUND_PAUSE).timeout
		_next_round()
	elif a1 > a2:
		# ── Player 1 wins this hit (lower lance = higher angle value)
		result_label.text = "P1 SCORES!"
		p1_score += 1
		knight1.react_win()
		knight2.react_lose()
		_update_score_labels()
		await get_tree().create_timer(ROUND_PAUSE).timeout
		_check_match_over()
	else:
		# ── Player 2 wins this hit
		result_label.text = "P2 SCORES!"
		p2_score += 1
		knight2.react_win()
		knight1.react_lose()
		_update_score_labels()
		await get_tree().create_timer(ROUND_PAUSE).timeout
		_check_match_over()

func _check_match_over() -> void:
	if p1_score >= WINS_NEEDED:
		_show_match_winner(1)
	elif p2_score >= WINS_NEEDED:
		_show_match_winner(2)
	else:
		_next_round()

func _next_round() -> void:
	match_state = MatchState.PAUSING
	# Reset both knights to starting positions
	knight1.reset_for_round()
	knight2.reset_for_round()
	# Brief pause then start the countdown again
	await get_tree().create_timer(0.3).timeout
	_start_countdown()

func _show_match_winner(winner_id: int) -> void:
	match_state = MatchState.MATCH_OVER
	win_label.text = "PLAYER %d WINS THE MATCH!" % winner_id
	result_label.text = "Press Space to play again"
	# Big gold flash for the winner
	_screen_flash(Color(1.0, 0.85, 0.0), 0.5)

func _update_score_labels() -> void:
	p1_score_label.text = str(p1_score)
	p2_score_label.text = str(p2_score)

func _input(event: InputEvent) -> void:
	if match_state == MatchState.MATCH_OVER and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func _screenshake(strength: float, duration: float) -> void:
	var tween = create_tween()
	# Each step shakes to a random nearby offset
	for i in int(duration / 0.04):
		var offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		tween.tween_property(camera, "offset", offset, 0.04)
	# Always snap back to centre at the end
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

func _screen_flash(col: Color, dur: float) -> void:
	col.a = 0.6
	flash_overlay.color = col
	create_tween().tween_property(flash_overlay, "color:a", 0.0, dur)

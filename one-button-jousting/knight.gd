extends CharacterBody2D

# ── Exported --- Arena sets these after instancing ───────────────────
@export var player_id: int = 1   # 1 = left side, 2 = right side
@export var lance_key: String = "p1_lance"
# ── Match state machine ─────────────────────────────────────────────
enum State { IDLE, CHARGING, HIT_WIN, HIT_LOSE, WAITING }
var state: State = State.IDLE
# ── Lance angle: 0.0 = raised high, 1.0 = fully lowered ────────────
# This is what gets compared at collision time.
var lance_angle: float = 0.0
const LOWER_SPEED: float = 3.5    # How fast the lance lowers
const RAISE_SPEED: float = 5.0    # How fast the lance raises when released
const MAX_ANGLE_DEG: float = 40.0  # Maximum downward rotation in degrees
# ── Charge movement ─────────────────────────────────────────────────
const CHARGE_SPEED: float = 90.0  # (units/sec)
var charge_dir: float = 1.0       # +1 = moving right, -1 = moving left
# ── Starting position --- stored so we can reset each round ───────────
var start_position: Vector2 = Vector2.ZERO
# ── Signals ─────────────────────────────────────────────────────────
signal collided_with(other_knight)  # Fired when LanceTip hits the other knight

@onready var lance_pivot: Node2D = $LancePivot
@onready var lance_tip: Area2D = $LancePivot/LanceTip
@onready var horse_body: ColorRect = $HorseBody
@onready var rider_body: ColorRect = $RiderBody

func _ready() -> void:
	# Store starting position for round resets
	start_position = global_position
	# Flip everything horizontally for Player 2
	if player_id == 2:
		scale.x = -1.0   # Mirror the whole scene
		charge_dir = -1.0  # Player 2 moves left toward Player 1
	# Connect LanceTip overlap
	lance_tip.body_entered.connect(_on_lance_tip_body_entered)

func _physics_process(delta: float) -> void:
	match state:
		State.CHARGING:
			_update_lance(delta)
			_charge_forward(delta)
		State.IDLE, State.WAITING:
			pass   # Do nothing --- Arena controls these transitions
		State.HIT_WIN, State.HIT_LOSE:
			pass   # Tween handles the reaction animation

func _update_lance(delta: float) -> void:
	# Hold button = lower lance toward opponent
	if Input.is_action_pressed(lance_key):
		lance_angle = min(lance_angle + LOWER_SPEED * delta, 1.0)
	else:
		# Release = raise lance back up
		lance_angle = max(lance_angle - RAISE_SPEED * delta, 0.0)
	# Apply the angle to the pivot using lerp for smooth rotation
	# lerp smooths between current rotation and target each frame
	var target_deg = lance_angle * MAX_ANGLE_DEG
	lance_pivot.rotation_degrees = lerp(
		lance_pivot.rotation_degrees,
		target_deg,
		delta * 12.0
	)

func _charge_forward(delta: float) -> void:
	velocity = Vector2(CHARGE_SPEED * charge_dir, 0)
	move_and_slide()

func _on_lance_tip_body_entered(body: Node) -> void:
	# Only care about hitting the other knight, and only while charging
	if state != State.CHARGING:
		return
	if not body.is_in_group("knight"):
		return
	# Emit signal --- the Arena script resolves who won
	collided_with.emit(body)

# ── Called by Arena after it resolves the collision ─────────────────
func react_win() -> void:
	state = State.HIT_WIN
	_play_win_reaction()

func react_lose() -> void:
	state = State.HIT_LOSE
	_play_lose_reaction()

func react_tie() -> void:
	state = State.HIT_LOSE   # Both get knocked back on a tie
	_play_lose_reaction()

func _play_win_reaction() -> void:
	# Flash gold and bounce forward slightly
	var tween = create_tween()
	tween.tween_property(rider_body, "modulate",
		Color(1.0, 0.85, 0.0), 0.08)
	tween.tween_property(rider_body, "modulate",
		Color.WHITE, 0.08)
	tween.tween_property(rider_body, "modulate",
		Color(1.0, 0.85, 0.0), 0.08)
	tween.tween_property(rider_body, "modulate",
		Color.WHITE, 0.08)

func _play_lose_reaction() -> void:
	# Fly backward with a decelerating slide
	var knockback_dir = -charge_dir  # Opposite of travel direction
	var tween = create_tween()
	tween.tween_method(
		func(spd): velocity = Vector2(spd * knockback_dir, 0); move_and_slide(),
		180.0,  # Starting knockback speed
		0.0,    # Slows to zero
		0.45    # Over 0.45 seconds
	)

# ── Called by Arena to reset knight for the next round ──────────────
func reset_for_round() -> void:
	state = State.IDLE
	lance_angle = 0.0
	lance_pivot.rotation_degrees = 0.0
	global_position = start_position
	velocity = Vector2.ZERO
	rider_body.modulate = Color.WHITE
	horse_body.modulate = Color.WHITE

# ── Called by Arena when the countdown finishes and the charge begins ─
func begin_charge() -> void:
	state = State.CHARGING

# ── Public getter for the Arena's collision resolver ────────────────
func get_lance_angle() -> float:
	return lance_angle

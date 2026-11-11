extends CharacterBody2D

enum State { WANDER, STUNNED, DEAD }

const WANDER_SPEED: float = 28.0
const STUNNED_SPEED: float = 6.0
const WANDER_JITTER: float = 0.5 # Radians of random steering per jitter step

@export var speed_mult: float = 1.0 # Set per wave by kitchen.gd

signal killed # Listened to by kitchen.gd

var state: State = State.WANDER
var is_stunned: bool = false
var _move_dir: Vector2 = Vector2.RIGHT
var _jitter_t: float = 0.0

@onready var body: ColorRect = $Body
@onready var hit_zone: Area2D = $HitZone

func _ready() -> void:
	add_to_group("bugs")
	var angle = randf_range(0.0, TAU)
	_move_dir = Vector2(cos(angle), sin(angle))
	hit_zone.body_entered.connect(_on_hit_zone_body_entered)

func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	var players = get_tree().get_nodes_in_group("player")
	# Ask the player if this bug is inside the flashlight
	var in_light = false
	if not players.is_empty():
		in_light = players[0].is_in_light(global_position)
	# Update stun state
	if in_light and state == State.WANDER:
		_set_stunned(true)
	elif not in_light and state == State.STUNNED:
		_set_stunned(false)
	# Steer toward the player with jitter
	if not players.is_empty():
		var to_player = global_position.direction_to(players[0].global_position)
		_jitter_t += delta
		if _jitter_t > 0.3:
			_jitter_t = 0.0
			_move_dir = _move_dir.lerp(to_player, 0.6).normalized()
			_move_dir = _move_dir.rotated(randf_range(-WANDER_JITTER, WANDER_JITTER))
	var spd = (STUNNED_SPEED if is_stunned else WANDER_SPEED) * speed_mult
	velocity = _move_dir * spd
	move_and_slide()

func _set_stunned(value: bool) -> void:
	is_stunned = value
	state = State.STUNNED if value else State.WANDER
	# Tint white when stunned, normal colour when not
	var target = Color.WHITE if value else Color(0.20, 0.60, 0.15)
	create_tween().tween_property(body, "color", target, 0.1)

func swat() -> void:
	if state == State.DEAD:
		return
	state = State.DEAD
	is_stunned = false
	killed.emit()
	# Squish and fade out
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(2.0, 0.1), 0.12)
	tw.tween_property(body, "modulate:a", 0.0, 0.15)
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

func _on_hit_zone_body_entered(b: Node2D) -> void:
	if b.is_in_group("player"):
		b.catch_bug()

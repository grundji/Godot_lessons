extends CharacterBody2D

# Speed is set randomly per monster in the Room scene
@export var speed: float = 45.0
# Starting direction --- randomised in _ready()
var _dir: Vector2 = Vector2.RIGHT

@onready var hit_zone: Area2D = $HitZone

func _ready() -> void:
	# Pick a random starting direction (any angle)
	var angle = randf_range(0.0, TAU)
	_dir = Vector2(cos(angle), sin(angle))
	# Connect the HitZone signal
	hit_zone.body_entered.connect(_on_hit_zone_body_entered)

func _physics_process(delta: float) -> void:
	velocity = _dir * speed
	move_and_slide()
	# ── Wall bounce ───────────────────────────────────────────
	# get_slide_collision_count() returns how many surfaces we hit
	# this frame. For each one we reflect the direction off the wall.
	for i in get_slide_collision_count():
		_dir = _dir.reflect(get_slide_collision(i).get_normal())

# (body is left untyped: the handler calls the player's custom
# catch(), which Godot 4 rejects through a base-class type)
func _on_hit_zone_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.catch()

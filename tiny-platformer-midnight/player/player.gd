extends CharacterBody2D
### Midnight, the player cat.

const SPEED := 220.0
const JUMP_VELOCITY := -420.0
const GRAVITY := 1200.0
const COYOTE_TIME := 0.15
const JUMP_BUFFER_TIME := 0.12

var coyote_timer := 0.0
var jump_buffer_timer := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_apply_gravity(delta)
	_handle_jump()
	_handle_move()
	_update_animation()
	move_and_slide()
	_after_move()

func _update_timers(delta: float) -> void:
	coyote_timer -= delta
	jump_buffer_timer -= delta

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	if jump_buffer_timer <= 0.0:
		return
	if coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

func _handle_move() -> void:
	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED
	if dir != 0.0:
		sprite.flip_h = dir < 0.0

func _update_animation() -> void:
	if not is_on_floor():
		anim.play("jump")
	elif velocity.x != 0.0:
		anim.play("run")
	else:
		anim.play("idle")

func _after_move() -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME

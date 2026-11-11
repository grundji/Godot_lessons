extends CharacterBody3D
### The rescue helicopter. Velocity flight, no physics tricks.

const LIFT_SPEED := 10.0
const FLY_SPEED := 14.0
const YAW_SPEED := 1.6
const GRAVITY := 6.0
const HOVER_HEIGHT := 8.0

const WINCH_SPEED := 6.0
const WINCH_MAX := 12.0

var winch_length := 0.0
var carried_person: Node3D = null

@onready var winch_rope: MeshInstance3D = $WinchRope
@onready var winch_hook: Area3D = $WinchHook

var rotor_speed := 0.0

@onready var main_rotor: MeshInstance3D = $MainRotor
@onready var tail_rotor: MeshInstance3D = $TailRotor

func _physics_process(delta: float) -> void:
	_handle_yaw(delta)
	_handle_fly(delta)
	_handle_lift(delta)
	_handle_winch(delta)
	_update_carried_person()
	_spin_rotors(delta)
	move_and_slide()
func _handle_yaw(delta: float) -> void:
	var yaw := Input.get_axis("yaw_left", "yaw_right")
	rotate_y(-yaw * YAW_SPEED * delta)

func _handle_fly(delta: float) -> void:
	var forward := Input.get_axis("move_back", "move_forward")
	var strafe := Input.get_axis("move_left", "move_right")
	var dir := Vector3(strafe, 0.0, -forward)
	dir = dir.rotated(Vector3.UP, rotation.y)
	velocity.x = dir.x * FLY_SPEED
	velocity.z = dir.z * FLY_SPEED

func _handle_lift(delta: float) -> void:
	if Input.is_action_pressed("lift_up"):
		velocity.y = LIFT_SPEED
	elif Input.is_action_pressed("lift_down"):
		velocity.y = -LIFT_SPEED
	else:
		velocity.y = -GRAVITY

func _spin_rotors(delta: float) -> void:
	rotor_speed = lerpf(rotor_speed, 12.0, delta)
	main_rotor.rotate_y(rotor_speed * delta)
	tail_rotor.rotate_x(rotor_speed * delta)

func _handle_winch(delta: float) -> void:
	if Input.is_action_pressed("winch_down"):
		winch_length += WINCH_SPEED * delta
	if Input.is_action_pressed("winch_up"):
		winch_length -= WINCH_SPEED * delta
	winch_length = clampf(winch_length, 0.0, WINCH_MAX)
	_update_winch_visual()

func _update_winch_visual() -> void:
	winch_rope.position.y = -winch_length / 2.0
	winch_rope.scale.y = maxf(winch_length, 0.1)
	winch_hook.position.y = -winch_length

func _on_hook_body_entered(body: Node3D) -> void:
	if carried_person != null:
		return
	if body.is_in_group("rescue_people"):
		carried_person = body
		body.is_being_lifted = true

func _update_carried_person() -> void:
	if carried_person == null:
		return
	carried_person.global_position = winch_hook.global_position
	if winch_length <= 0.5:
		_deliver_person()

func _deliver_person() -> void:
	carried_person.is_rescued = true
	carried_person.is_being_lifted = false
	carried_person.queue_free()
	carried_person = null
	winch_length = 0.0

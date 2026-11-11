extends CharacterBody3D

# Movement
const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = -9.8
# Collection
const COLLECT_RANGE: float = 2.5  # How close the player must be to a slime
const MAX_HELD: int = 5
# State
var held_slimes: Array = []       # Array of collected Slime nodes
var near_pen: Node = null         # Set by a Pen when the player enters its zone
# Mouse capture state
var _mouse_captured: bool = false

@onready var camera_pivot: Node3D = $CameraPivot

func _ready() -> void:
	# Lock the mouse to the window centre for first-person look
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_mouse_captured = true
	# Register this node in the 'player' group so pens can find it
	add_to_group("player")

func _input(event: InputEvent) -> void:
	# ── Mouse look ─────────────────────────────────────────────
	if event is InputEventMouseMotion and _mouse_captured:
		# Horizontal mouse movement rotates the whole player body (yaw)
		rotate_y(-event.relative.x * 0.003)
		# Vertical mouse movement only tilts the camera pivot (pitch)
		camera_pivot.rotate_x(-event.relative.y * 0.003)
		# Clamp pitch so the player cannot look fully upside down
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x, -1.2, 0.4
		)
	# ── Escape = release the mouse (useful during development) ──
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_mouse_captured = false
	# ── Click to re-capture the mouse ──────────────────────────
	if event is InputEventMouseButton and event.pressed and not _mouse_captured:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		_mouse_captured = true
	# ── E = collect a nearby slime ─────────────────────────────
	if event.is_action_pressed("collect"):
		_try_collect()
	# ── F = deposit a slime into a nearby pen ──────────────────
	if event.is_action_pressed("deposit"):
		_try_deposit()

func _try_collect() -> void:
	if held_slimes.size() >= MAX_HELD:
		return  # Pockets are full
	# Search all nodes in the 'slimes' group
	var slimes: Array = get_tree().get_nodes_in_group("slimes")
	var nearest = null
	var nearest_dist = COLLECT_RANGE
	for slime in slimes:
		if slime.is_collected:
			continue  # Skip already-collected slimes
		var dist = global_position.distance_to(slime.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = slime
	if nearest != null:
		nearest.collect()
		held_slimes.append(nearest)

func _try_deposit() -> void:
	# near_pen is set by the Pen scene when the player enters its Area3D
	if near_pen == null:
		return  # Not standing in any pen
	if held_slimes.is_empty():
		return  # Nothing to deposit
	# Take the last slime from the held list and give it to the pen
	var slime = held_slimes.pop_back()
	near_pen.receive_slime(slime)

func _physics_process(delta: float) -> void:
	# ── Gravity ────────────────────────────────────────────────
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	# ── Jump ───────────────────────────────────────────────────
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# ── WASD movement ──────────────────────────────────────────
	# get_vector returns a normalised 2D direction from four actions
	var input_dir = Input.get_vector(
		"ui_left", "ui_right", "ui_up", "ui_down"
	)
	# Transform from local space (relative to which way we face)
	# to world space using the player's current rotation
	var direction = (transform.basis * Vector3(
		input_dir.x, 0.0, input_dir.y
	)).normalized()
	if direction.length() > 0.0:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Gradually stop when no key is held
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)
	move_and_slide()

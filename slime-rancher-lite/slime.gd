extends CharacterBody3D

# Slime data --- set by main.gd after instantiating
var slime_color: Color = Color.GREEN
var slime_type: String = "green"
var is_collected: bool = false
# Movement constants
const SPEED: float = 2.0
const GRAVITY: float = -9.8
const JUMP_VEL: float = 4.5
# Timers for random behaviour
var _move_timer: float = 0.0   # Countdown until next direction change
var _jump_timer: float = 0.0   # Countdown until next jump
var _move_dir: Vector2 = Vector2.ZERO  # Current horizontal wander direction

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# ── Called by main.gd right after add_child() ──────────────────
func setup(col: Color, type: String) -> void:
	slime_color = col
	slime_type = type
	# Build a sphere mesh
	var sphere = SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	mesh_instance.mesh = sphere
	# Colour the sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.3   # Slight shine for a jelly look
	mesh_instance.material_override = mat
	# Randomise the starting timers so not all slimes move in sync
	_move_timer = randf_range(0.5, 2.0)
	_jump_timer = randf_range(0.5, 2.0)

# ── Called by player.gd when the player presses E nearby ────────
func collect() -> void:
	is_collected = true
	visible = false           # Hide the slime from the world

# ── Called if we ever need to release a slime back to the world ─
func release_at(pos: Vector3) -> void:
	is_collected = false
	global_position = pos
	visible = true

# ── Runs every physics frame ─────────────────────────────────────
func _physics_process(delta: float) -> void:
	# Do nothing while in the player's pocket
	if is_collected:
		return
	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	# Randomly change the horizontal wander direction
	_move_timer -= delta
	if _move_timer <= 0.0:
		var angle = randf_range(0.0, TAU)
		_move_dir = Vector2(cos(angle), sin(angle))
		_move_timer = randf_range(1.5, 3.5)
	# Randomly jump when on the floor
	_jump_timer -= delta
	if _jump_timer <= 0.0 and is_on_floor():
		_jump_timer = randf_range(1.0, 2.5)
		velocity.y = JUMP_VEL
	# Apply horizontal movement
	velocity.x = _move_dir.x * SPEED
	velocity.z = _move_dir.y * SPEED
	move_and_slide()

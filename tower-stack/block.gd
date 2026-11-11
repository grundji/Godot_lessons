extends Node3D

# These are set by main.gd when the block is spawned
var block_size: Vector3 = Vector3(3.0, 0.4, 3.0)
var move_axis: String = "x"
var move_speed: float = 0.0
var move_range: float = 4.0
var _dir: int = 1
var _active: bool = true

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# ── Called by Main right after add_child() ──────────────────────
func setup(size: Vector3, axis: String, speed: float, color: Color) -> void:
	block_size = size
	move_axis = axis
	move_speed = speed
	# Create the cube mesh
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	# Apply the colour
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat

# ── Called by main.gd when the player taps ──────────────────────
func stop() -> void:
	_active = false

# ── Move the block every frame ──────────────────────────────────
func _process(delta: float) -> void:
	if not _active:
		return
	if move_axis == "x":
		position.x += move_speed * _dir * delta
		if position.x > move_range or position.x < -move_range:
			_dir *= -1
	else:
		position.z += move_speed * _dir * delta
		if position.z > move_range or position.z < -move_range:
			_dir *= -1

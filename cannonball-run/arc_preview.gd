extends Node3D

const DOT_COUNT: int = 20 # How many preview dots to show
const SIM_STEP: float = 0.08 # Time between each simulated step
const GRAVITY: float = -9.8
const DOT_RADIUS: float = 0.12

var _dots: Array = []

func _ready() -> void:
	# Pre-create all dot meshes and hide them
	for i in DOT_COUNT:
		var mi = MeshInstance3D.new()
		var sph = SphereMesh.new()
		sph.radius = DOT_RADIUS
		sph.height = DOT_RADIUS * 2
		mi.mesh = sph
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.0, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mi.material_override = mat
		add_child(mi)
		mi.visible = false
		_dots.append(mi)

# Call every frame while charging to update the arc
func update_arc(start_pos: Vector3, start_vel: Vector3) -> void:
	var pos = start_pos
	var vel = start_vel
	for i in DOT_COUNT:
		# Simulate one time step of physics
		vel.y += GRAVITY * SIM_STEP
		pos += vel * SIM_STEP
		_dots[i].global_position = pos
		_dots[i].visible = true

func hide_arc() -> void:
	for dot in _dots:
		dot.visible = false

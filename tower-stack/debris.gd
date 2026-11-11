extends RigidBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func setup(size: Vector3, color: Color) -> void:
	# ── Mesh ───────────────────────────────────────────────────
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat
	# ── Collider (must match the mesh size) ────────────────────
	var shape = BoxShape3D.new()
	shape.size = size
	collision_shape.shape = shape
	# ── Random spin for visual flair ───────────────────────────
	apply_torque(Vector3(
		randf_range(-3, 3),
		randf_range(-3, 3),
		randf_range(-3, 3)
	))
	# ── Auto-delete after 2 seconds ────────────────────────────
	await get_tree().create_timer(2.0).timeout
	queue_free()

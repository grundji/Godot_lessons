extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

# Called by main.gd after add_child()
func setup(size: Vector3, color: Color) -> void:
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_instance.material_override = mat

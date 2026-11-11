extends Area3D

const EXPAND_TIME: float = 0.4 # How long the blast takes to reach full size
const MAX_RADIUS: float = 6.0 # Maximum blast radius
const WIND_STRENGTH: float = 12.0 # Force applied to each sheep

@onready var shape: CollisionShape3D = $CollisionShape3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Expand radius and fade out using Tween
	var tw = create_tween().set_parallel(true)
	tw.tween_method(
		func(r): (shape.shape as SphereShape3D).radius = r,
		0.5, MAX_RADIUS, EXPAND_TIME
	)
	tw.tween_property(mesh, "scale", Vector3.ONE * (MAX_RADIUS / 0.7), EXPAND_TIME)
	tw.tween_property(mesh, "material_override:albedo_color:a", 0.0, EXPAND_TIME)
	# Delete when done
	tw.set_parallel(false)
	tw.tween_callback(queue_free)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("sheep"):
		return
	# Push the sheep away from the blast origin
	var dir = global_position.direction_to(body.global_position)
	var force = dir * WIND_STRENGTH
	body.apply_wind(force)

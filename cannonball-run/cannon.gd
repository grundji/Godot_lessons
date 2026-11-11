extends Node3D

signal ball_caught # Tells Game.gd the ball landed here

@export var is_start_cannon: bool = false

@onready var barrel_pivot: Node3D = $BarrelPivot
@onready var muzzle_point: Node3D = $BarrelPivot/MuzzlePoint
@onready var catch_zone: Area3D = $CatchZone
@onready var ring_mesh: MeshInstance3D = $CatchZone/RingMesh

func _ready() -> void:
	catch_zone.body_entered.connect(_on_catch_zone_body_entered)
	# Pulse the ring using a Tween
	var tw = create_tween().set_loops()
	tw.tween_property(ring_mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
	tw.tween_property(ring_mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.5)

# Aim the barrel toward a world-space target position
func aim_at(target_pos: Vector3) -> void:
	barrel_pivot.look_at(target_pos, Vector3.UP)

# Returns the world position of the cannon mouth
func get_muzzle_position() -> Vector3:
	return muzzle_point.global_position

# Returns a launch velocity toward target with given speed
func calc_launch_velocity(target_pos: Vector3, launch_speed: float) -> Vector3:
	var dir = (target_pos - get_muzzle_position()).normalized()
	return dir * launch_speed

func _on_catch_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("cannonball"):
		body.catch_in_cannon(get_muzzle_position())
		ball_caught.emit()

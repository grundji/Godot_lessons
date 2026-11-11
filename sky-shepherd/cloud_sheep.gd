extends CharacterBody3D

# Flock behaviour settings
const MAX_SPEED: float = 4.0 # Maximum drift speed
const NEIGHBOR_RADIUS: float = 5.0 # How far a sheep looks for neighbours
const SEPARATION_RADIUS: float = 1.8 # Distance at which separation kicks in
const FORCE_SEPARATION: float = 2.2 # Weight of separation rule
const FORCE_ALIGNMENT: float = 1.0 # Weight of alignment rule
const FORCE_COHESION: float = 0.8 # Weight of cohesion rule

# Wind blast accumulator
var wind_force: Vector3 = Vector3.ZERO
var is_penned: bool = false

func _ready() -> void:
	add_to_group("sheep")
	# Randomise starting velocity so sheep drift apart
	velocity = Vector3(randf_range(-2, 2), randf_range(-1, 1), randf_range(-2, 2))

func _physics_process(delta: float) -> void:
	if is_penned:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var neighbors = _get_neighbors()
	var steer = Vector3.ZERO
	steer += _separation(neighbors) * FORCE_SEPARATION
	steer += _alignment(neighbors) * FORCE_ALIGNMENT
	steer += _cohesion(neighbors) * FORCE_COHESION
	steer += wind_force
	# Bleed off wind force each frame
	wind_force = wind_force.lerp(Vector3.ZERO, delta * 3.0)
	# Apply steering to velocity
	velocity += steer * delta
	# Clamp to max speed
	if velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED
	# Keep sheep within a bounding sphere so they don't drift forever
	_apply_boundary()
	move_and_slide()

# Return all sheep within NEIGHBOR_RADIUS
func _get_neighbors() -> Array:
	var all = get_tree().get_nodes_in_group("sheep")
	var nearby = []
	for s in all:
		if s == self:
			continue
		if global_position.distance_to(s.global_position) < NEIGHBOR_RADIUS:
			nearby.append(s)
	return nearby

# Rule 1: Separation — steer away from very close neighbours
func _separation(neighbors: Array) -> Vector3:
	var force = Vector3.ZERO
	for n in neighbors:
		var diff = global_position - n.global_position
		if diff.length() < SEPARATION_RADIUS:
			# Stronger force the closer the neighbour is
			force += diff.normalized() / max(diff.length(), 0.01)
	return force

# Rule 2: Alignment — match the average velocity of neighbours
func _alignment(neighbors: Array) -> Vector3:
	if neighbors.is_empty():
		return Vector3.ZERO
	var avg_vel = Vector3.ZERO
	for n in neighbors:
		avg_vel += n.velocity
	avg_vel /= neighbors.size()
	return (avg_vel - velocity).normalized()

# Rule 3: Cohesion — steer toward centre of neighbours
func _cohesion(neighbors: Array) -> Vector3:
	if neighbors.is_empty():
		return Vector3.ZERO
	var centre = Vector3.ZERO
	for n in neighbors:
		centre += n.global_position
	centre /= neighbors.size()
	return global_position.direction_to(centre)

# Keep sheep inside a soft bounding sphere
func _apply_boundary() -> void:
	var origin = Vector3.ZERO # Centre of the play area
	var max_r = 25.0
	var dist = global_position.distance_to(origin)
	if dist > max_r:
		# Apply a gentle inward force proportional to how far outside
		var inward = global_position.direction_to(origin)
		velocity += inward * (dist - max_r) * 0.5

# Called by WindBlast when it overlaps this sheep
func apply_wind(force: Vector3) -> void:
	wind_force += force

# Called by Pen when the sheep enters
func enter_pen() -> void:
	is_penned = true

extends RigidBody3D

signal caught_by_cannon # Fired when an Area3D catch zone overlaps us
signal fell_out # Fired when Y drops below the fall threshold

const FALL_THRESHOLD: float = -30.0
# Y below this = fell off

var is_loaded: bool = true # True while sitting inside a cannon
var is_flying: bool = false

@onready var trail: GPUParticles3D = $Trail
@onready var cam: Camera3D = $Cam

func _ready() -> void:
	freeze = true # Start frozen inside the first cannon
	trail.emitting = false

# Called by Game when the player releases the fire button
func launch(velocity: Vector3) -> void:
	is_loaded = false
	is_flying = true
	freeze = false
	linear_velocity = velocity
	trail.emitting = true

# Called by Cannon when its catch zone overlaps the ball
func catch_in_cannon(cannon_pos: Vector3) -> void:
	if not is_flying:
		return
	is_flying = false
	is_loaded = true
	freeze = true
	linear_velocity = Vector3.ZERO
	global_position = cannon_pos
	trail.emitting = false
	caught_by_cannon.emit()

func _physics_process(_delta: float) -> void:
	if is_flying and global_position.y < FALL_THRESHOLD:
		is_flying = false
		fell_out.emit()

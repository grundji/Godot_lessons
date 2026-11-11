extends CharacterBody2D

const SPEED: float = 60.0
const SWAT_RANGE: float = 32.0 # Max distance to swat a stunned bug
const LIGHT_RANGE: float = 60.0 # How far the flashlight reaches

signal died

var is_dead: bool = false

@onready var light_pivot: Node2D = $LightPivot
@onready var flashlight: PointLight2D = $LightPivot/Flashlight

func _ready() -> void:
	add_to_group("player")
	flashlight.texture_scale = 1.8

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down") * SPEED
	move_and_slide()
	_aim_flashlight()

func _aim_flashlight() -> void:
	# Get mouse position in world (global) space
	var mouse_world = get_global_mouse_position()
	# Rotate the pivot so the light points toward the mouse
	light_pivot.look_at(mouse_world)

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event.is_action_just_pressed("swat"):
		_try_swat()

func _try_swat() -> void:
	var bugs = get_tree().get_nodes_in_group("bugs")
	var nearest = null
	var nearest_dist = SWAT_RANGE
	for bug in bugs:
		if not bug.is_stunned:
			continue
		var dist = global_position.distance_to(bug.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = bug
	if nearest:
		nearest.swat()

# Returns whether a given world position is inside the flashlight cone
func is_in_light(world_pos: Vector2) -> bool:
	var to_pos = world_pos - global_position
	if to_pos.length() > LIGHT_RANGE:
		return false
	var light_dir = Vector2.RIGHT.rotated(light_pivot.rotation)
	# Angle between the light direction and the vector to the position
	var angle_diff = abs(light_dir.angle_to(to_pos.normalized()))
	return angle_diff < 0.55 # ~31 degrees half-angle

func catch_bug() -> void:
	if is_dead:
		return
	is_dead = true
	died.emit()

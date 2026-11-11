extends CharacterBody2D

const SPEED: float = 55.0
const MAGNET_RANGE: float = 80.0
# Magnet mode: true = attract (pull), false = repel (push)
var attract_mode: bool = true

@onready var mode_label: Label = $ModeLabel
@onready var magnet_indicator: ColorRect = $MagnetIndicator
@onready var magnet_beam: Line2D = $MagnetBeam

func _ready() -> void:
	add_to_group("player")
	_configure_beam()
	_update_mode_visuals()

# Line2D settings for the magnet beam
func _configure_beam() -> void:
	magnet_beam.width = 1.5
	magnet_beam.default_color = Color(0.30, 0.85, 1.00, 0.70)
	magnet_beam.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("toggle_magnet"):
		attract_mode = not attract_mode
		_update_mode_visuals()

func _update_mode_visuals() -> void:
	if attract_mode:
		magnet_indicator.color = Color(0.20, 0.80, 1.00) # Cyan = attract
		mode_label.text = "ATTRACT"
		magnet_beam.default_color = Color(0.30, 0.85, 1.00, 0.70)
	else:
		magnet_indicator.color = Color(1.00, 0.45, 0.20) # Orange = repel
		mode_label.text = "REPEL"
		magnet_beam.default_color = Color(1.00, 0.55, 0.20, 0.70)

func _physics_process(delta: float) -> void:
	# 8-directional movement
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = dir * SPEED
	move_and_slide()
	# Apply magnet force to all nearby blocks
	_apply_magnet_to_blocks()

func _apply_magnet_to_blocks() -> void:
	var blocks = get_tree().get_nodes_in_group("metal_blocks")
	var beam_points: Array[Vector2] = []
	for block in blocks:
		var dist = global_position.distance_to(block.global_position)
		var in_range = dist <= MAGNET_RANGE
		# Tell the block to tint itself based on range and mode
		block.set_in_range(in_range, attract_mode)
		if in_range:
			# Apply the actual force — block does the physics calculation
			block.apply_magnet_force(global_position, attract_mode)
			# Record this block position for the beam Line2D
			beam_points.append(block.global_position)
	# Draw magnet beam lines
	if beam_points.is_empty():
		magnet_beam.visible = false
	else:
		magnet_beam.visible = true
		# Line2D uses local-space points, so convert from global
		magnet_beam.clear_points()
		# Add the player's own position as the beam origin
		magnet_beam.add_point(Vector2.ZERO) # Player centre
		for pt in beam_points:
			magnet_beam.add_point(to_local(pt)) # Block position in local space

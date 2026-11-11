extends RigidBody2D

const MAX_FORCE: float = 220.0
# Maximum force the magnet can apply to this block
const MAGNET_RANGE: float = 80.0
# Magnet only works within this pixel radius
var is_on_plate: bool = false
# Whether this block is currently on a pressure plate
# Set externally by PressurePlate.tscn

@onready var body_rect: ColorRect = $ColorRect

func _ready() -> void:
	add_to_group("metal_blocks")

# Called every physics frame by the Player script
# attract_mode: true = pull toward player, false = push away
func apply_magnet_force(player_pos: Vector2, attract_mode: bool) -> void:
	var dist = global_position.distance_to(player_pos)
	if dist > MAGNET_RANGE or dist < 1.0:
		return
	# Direction from this block toward the player
	var dir_to_player = global_position.direction_to(player_pos)
	# Force falls off with distance: close = stronger, far = weaker
	# We divide by distance and clamp so it does not become infinite
	var strength = clamp(MAX_FORCE / dist * 16.0, 0.0, MAX_FORCE)
	# Flip direction based on attract / repel mode
	var force_dir = dir_to_player if attract_mode else -dir_to_player
	apply_central_force(force_dir * strength)

# Visual feedback: tint the block when in magnet range
func set_in_range(in_range: bool, attract: bool) -> void:
	if in_range:
		body_rect.color = Color(0.50, 0.75, 0.90) if attract else Color(0.90, 0.55, 0.35)
	else:
		body_rect.color = Color(0.35, 0.38, 0.42) # Reset to iron grey

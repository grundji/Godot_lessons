extends StaticBody2D

# How far the door slides when it opens (in pixels)
@export var slide_distance: float = 36.0
# Direction the door slides: Vector2.UP, DOWN, LEFT, or RIGHT
@export var slide_direction: Vector2 = Vector2.UP

var is_open: bool = false
var closed_pos: Vector2
var open_pos: Vector2

@onready var door_rect: ColorRect = $DoorRect

func _ready() -> void:
	closed_pos = global_position
	open_pos = closed_pos + slide_direction * slide_distance

# Called when the linked pressure plate emits 'activated'
func open() -> void:
	if is_open:
		return
	is_open = true
	_animate_to(open_pos, Color(0.20, 0.55, 0.20))

# Called when the pressure plate emits 'deactivated'
func close() -> void:
	if not is_open:
		return
	is_open = false
	_animate_to(closed_pos, Color(0.60, 0.18, 0.12))

func _animate_to(target_pos: Vector2, target_color: Color) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "global_position", target_pos, 0.35)
	tween.tween_property(door_rect, "color", target_color, 0.35)

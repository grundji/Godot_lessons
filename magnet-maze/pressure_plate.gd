extends Node2D

# Emitted when a block enters — listened to by Door and Level
signal activated
signal deactivated

var is_active: bool = false
var blocks_on_plate: int = 0 # Count of overlapping blocks

@onready var pad_rect: ColorRect = $PadRect
@onready var active_glow: ColorRect = $ActiveGlow
@onready var sensor_zone: Area2D = $SensorZone

func _ready() -> void:
	sensor_zone.body_entered.connect(_on_body_entered)
	sensor_zone.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Only respond to metal blocks
	if not body.is_in_group("metal_blocks"):
		return
	blocks_on_plate += 1
	body.is_on_plate = true
	if blocks_on_plate == 1 and not is_active:
		_set_active(true)

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("metal_blocks"):
		return
	blocks_on_plate = max(blocks_on_plate - 1, 0)
	body.is_on_plate = false
	if blocks_on_plate == 0 and is_active:
		_set_active(false)

func _set_active(value: bool) -> void:
	is_active = value
	active_glow.visible = value
	# Animate the pad colour
	var target_color = Color(0.20, 0.55, 0.25) if value else Color(0.25, 0.28, 0.32)
	var tween = create_tween()
	tween.tween_property(pad_rect, "color", target_color, 0.2)
	if value:
		activated.emit()
	else:
		deactivated.emit()

func get_is_active() -> bool:
	return is_active

extends Area2D

signal level_complete

var is_unlocked: bool = false

@onready var exit_rect: ColorRect = $ExitRect
@onready var lock_overlay: ColorRect = $LockOverlay

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Start locked — the level script calls unlock() when all plates active
	lock_overlay.visible = true

func unlock() -> void:
	is_unlocked = true
	lock_overlay.visible = false
	# Pulse the exit brightly to show it is active
	var tween = create_tween().set_loops()
	tween.tween_property(exit_rect, "color", Color(0.20, 0.90, 0.85), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(exit_rect, "color", Color(0.10, 0.45, 0.50), 0.5).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if is_unlocked and body.is_in_group("player"):
		level_complete.emit()

extends Area2D

@onready var rect: ColorRect = $ColorRect
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_pulse()

# (body is left untyped: the handler calls the player's custom
# win(), which Godot 4 rejects through a base-class type)
func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.win()

# ── Creates a looping scale pulse using Tween ─────────────────
func _start_pulse() -> void:
	var tween = create_tween().set_loops()
	# Grow the portal slightly
	tween.tween_property(self, "scale",
		Vector2(1.15, 1.15), 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Shrink back
	tween.tween_property(self, "scale",
		Vector2(1.0, 1.0), 0.6
	).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Also pulse the light energy
	var tween2 = create_tween().set_loops()
	tween2.tween_property(light, "energy", 2.5, 0.6)
	tween2.tween_property(light, "energy", 1.0, 0.6)

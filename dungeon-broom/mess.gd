extends Area2D

# ── Exported so the Room scene can set this per instance ──────────
@export var mess_type: String = "slime"  # "slime" or "blood"
# Colours for each mess type
const MESS_COLORS = {
	"slime": Color(0.25, 0.85, 0.20, 0.85),
	"blood": Color(0.75, 0.05, 0.05, 0.85),
}
# Which tool cleans which mess
const REQUIRED_TOOL = {
	"slime": 0,   # Tool.BROOM = 0
	"blood": 1,   # Tool.MOP   = 1
}

var is_cleaned: bool = false

# ── Signal emitted when this mess is successfully cleaned ──────────
signal cleaned

@onready var splat: ColorRect = $Splat

func _ready() -> void:
	add_to_group("messes")
	# Apply colour based on type
	splat.color = MESS_COLORS.get(mess_type, Color.WHITE)
	# Listen for the player entering our overlap zone
	body_entered.connect(_on_body_entered)

# (body is left untyped: the handler calls the player's custom
# get_tool(), which Godot 4 rejects through a base-class type)
func _on_body_entered(body) -> void:
	if is_cleaned:
		return
	if not body.is_in_group("player"):
		return
	# Check that the player is holding the right tool
	if body.get_tool() != REQUIRED_TOOL[mess_type]:
		# Wrong tool --- flash red briefly to give feedback
		_flash_wrong_tool()
		return
	# Correct tool --- clean the mess
	_clean()

func _clean() -> void:
	is_cleaned = true
	cleaned.emit()   # Room script listens to this
	# Shrink and fade out using Tween
	var tween = create_tween()
	tween.set_parallel(true)   # Run all tweens at the same time
	tween.tween_property(splat, "scale", Vector2(0.0, 0.0), 0.25)
	tween.tween_property(splat, "modulate:a", 0.0, 0.25)
	# After animation finishes, delete this node
	tween.set_parallel(false)
	tween.tween_callback(queue_free)

func _flash_wrong_tool() -> void:
	# Flash white quickly to indicate wrong tool was used
	var tween = create_tween()
	tween.tween_property(splat, "modulate",
		Color.WHITE, 0.07)
	tween.tween_property(splat, "modulate",
		MESS_COLORS[mess_type], 0.07)

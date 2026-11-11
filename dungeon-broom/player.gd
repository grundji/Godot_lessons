extends CharacterBody2D

# ── Enum for the player's active tool ─────────────────────────────
# Enums give meaningful names to integer states.
# BROOM = 0, MOP = 1 --- but we never need to remember the numbers.
enum Tool { BROOM, MOP }
# ── Constants ──────────────────────────────────────────────────────
const SPEED: float = 60.0   # Pixels per second, top-down so no gravity
# ── State ──────────────────────────────────────────────────────────
var active_tool: Tool = Tool.BROOM
var is_dead: bool = false
# ── Signals ────────────────────────────────────────────────────────
signal caught   # Emitted when a monster touches the player
# ── Colours for each tool (used to update the indicator) ───────────
const TOOL_COLORS = {
	Tool.BROOM: Color(0.30, 0.80, 0.30),   # Green  = broom
	Tool.MOP:   Color(0.30, 0.50, 1.00),   # Blue   = mop
}
const TOOL_NAMES = {
	Tool.BROOM: "BROOM",
	Tool.MOP:   "MOP",
}

@onready var body: ColorRect = $Body
@onready var tool_indicator: ColorRect = $ToolIndicator
@onready var tool_label: Label = $ToolLabel

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# ── 8-directional movement ────────────────────────────────
	# get_vector returns a normalised Vector2 from four input actions.
	# It handles diagonals automatically --- no extra maths needed.
	var dir = Input.get_vector(
		"ui_left", "ui_right", "ui_up", "ui_down"
	)
	velocity = dir * SPEED
	move_and_slide()

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	# ── Tab = swap between broom and mop ─────────────────────
	if event.is_action_pressed("swap_tool"):
		_swap_tool()

func _swap_tool() -> void:
	# Toggle between the two Tool enum values
	active_tool = Tool.MOP if active_tool == Tool.BROOM else Tool.BROOM
	# Update the visual indicator and label
	tool_indicator.color = TOOL_COLORS[active_tool]
	tool_label.text = TOOL_NAMES[active_tool]

# ── Called by Monster.tscn when contact is made ───────────────
func catch() -> void:
	if is_dead:
		return
	is_dead = true
	caught.emit()

# ── Returns the currently held tool --- used by Mess.tscn ───────
func get_tool() -> Tool:
	return active_tool

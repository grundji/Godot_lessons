extends Node3D

var slime_count: int = 0   # How many slimes are in this pen
var goal_count: int = 5    # How many slimes to fill this pen
var accepted_type: String = ""  # Empty string accepts all types
var is_full: bool = false

@onready var pad_mesh: MeshInstance3D = $PadMesh
@onready var detect_zone: Area3D = $DetectionZone
@onready var count_label: Label3D = $CountLabel

# ── Called by main.gd after add_child() ─────────────────────────
func setup(type: String, col: Color, goal: int = 5) -> void:
	accepted_type = type
	goal_count = goal
	# Build the visible floor pad
	var box = BoxMesh.new()
	box.size = Vector3(4.0, 0.1, 4.0)
	pad_mesh.mesh = box
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.6    # Slightly transparent
	pad_mesh.material_override = mat
	# Position the label above the pad
	count_label.position = Vector3(0.0, 1.5, 0.0)
	count_label.font_size = 64
	_update_label()

# ── Connect signals in _ready() ──────────────────────────────────
func _ready() -> void:
	detect_zone.body_entered.connect(_on_body_entered)
	detect_zone.body_exited.connect(_on_body_exited)

# ── Signal callbacks ─────────────────────────────────────────────
# (body is left untyped: the callbacks set the player's custom
# near_pen property, which Godot 4 rejects through a base-class type)
func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		body.near_pen = self   # Tell the player which pen they are near

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		if body.near_pen == self:
			body.near_pen = null  # Clear the reference when they leave

# ── Called by player.gd when depositing ─────────────────────────
func receive_slime(slime: Node) -> void:
	if is_full:
		return
	slime_count += 1
	_update_label()
	slime.queue_free()   # The slime is now in the pen --- remove from scene
	if slime_count >= goal_count:
		is_full = true
		_on_pen_full()

# ── Private helpers ──────────────────────────────────────────────
func _update_label() -> void:
	if is_full:
		count_label.text = "FULL!"
	else:
		count_label.text = "%d / %d" % [slime_count, goal_count]

func _on_pen_full() -> void:
	# Brighten the pad to celebrate
	var mat = pad_mesh.material_override as StandardMaterial3D
	mat.albedo_color.a = 0.9

# ── Public helper for main.gd to check win condition ─────────────
func get_is_full() -> bool:
	return is_full

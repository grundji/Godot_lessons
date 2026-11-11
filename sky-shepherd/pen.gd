extends Node3D

signal sheep_penned(count: int) # Emits current total whenever a sheep enters

var penned_count: int = 0

@onready var entry_zone: Area3D = $EntryZone
@onready var ring: MeshInstance3D = $Ring

func _ready() -> void:
	entry_zone.body_entered.connect(_on_body_entered)
	# Gently rotate the ring
	var tw = create_tween().set_loops()
	tw.tween_property(self, "rotation:y", TAU, 8.0)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("sheep"):
		return
	if body.is_penned:
		return
	body.enter_pen()
	penned_count += 1
	sheep_penned.emit(penned_count)
	# Flash ring gold
	var mat = ring.material_override as StandardMaterial3D
	var tw = create_tween()
	tw.tween_property(mat, "albedo_color", Color(1.0, 0.9, 0.2), 0.15)
	tw.tween_property(mat, "albedo_color", Color(0.0, 0.9, 1.0), 0.3)

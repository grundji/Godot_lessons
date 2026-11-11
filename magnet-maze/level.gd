extends Node2D

@export var next_level: String = "res://scenes/Level2.tscn"
# The level script finds all plates and the exit automatically.
# Doors must be manually linked to their plate via the Inspector —
# see the 'plate_door_links' exported array below.
# Each entry is a Dictionary: { plate: PressurePlate, door: Door }
# Set up in _ready() from the exported node paths.
@export var plate_paths: Array[NodePath] = []
@export var door_paths: Array[NodePath] = []

var plates: Array = []
var doors: Array = []
var active_count: int = 0
var total_plates: int = 0
var _won: bool = false

@onready var player: CharacterBody2D = $Player
@onready var exit_node: Area2D = $Exit
@onready var hud_label: Label = $UI/HUDLabel

func _ready() -> void:
	player.add_to_group("player")
	# Resolve exported NodePaths into actual node references
	for path in plate_paths:
		plates.append(get_node(path))
	for path in door_paths:
		doors.append(get_node(path))
	total_plates = plates.size()
	# Connect each plate to the matching door (by index) and to our tracker
	for i in plates.size():
		var plate = plates[i]
		plate.activated.connect(_on_plate_activated)
		plate.deactivated.connect(_on_plate_deactivated)
		# Also connect plate directly to its door if one exists
		if i < doors.size():
			plate.activated.connect(doors[i].open)
			plate.deactivated.connect(doors[i].close)
	# Connect the exit signal
	exit_node.level_complete.connect(_on_level_complete)
	_update_hud()

func _on_plate_activated() -> void:
	active_count += 1
	_update_hud()
	if active_count >= total_plates:
		exit_node.unlock()

func _on_plate_deactivated() -> void:
	active_count = max(active_count - 1, 0)
	_update_hud()

func _update_hud() -> void:
	hud_label.text = "Plates: %d / %d" % [active_count, total_plates]

func _on_level_complete() -> void:
	if next_level != "" and ResourceLoader.exists(next_level):
		get_tree().change_scene_to_file(next_level)
	else:
		_show_win()

func _show_win() -> void:
	_won = true
	var label = Label.new()
	add_child(label)
	label.text = "YOU ESCAPED!\nPress Space to play again"
	label.position = Vector2(80, 100)
	label.add_theme_font_size_override("font_size", 14)

func _input(event: InputEvent) -> void:
	if _won and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

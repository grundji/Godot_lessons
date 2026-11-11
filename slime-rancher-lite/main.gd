extends Node3D

const SlimeScene = preload("res://scenes/Slime.tscn")

# Slime type definitions --- type name and colour
const SLIME_TYPES: Array[Dictionary] = [
	{ type = "pink",   color = Color(1.00, 0.55, 0.75) },
	{ type = "green",  color = Color(0.30, 0.90, 0.40) },
	{ type = "blue",   color = Color(0.25, 0.60, 1.00) },
	{ type = "yellow", color = Color(1.00, 0.88, 0.20) },
]
const FIELD_SIZE: float = 18.0  # Slimes spawn within this radius
const SLIME_COUNT: int = 20     # How many slimes spawn at start

# (player is left untyped: main.gd reads the player's custom
# held_slimes and near_pen, which Godot 4 rejects through a
# base-class type)
@onready var player = $Player
@onready var held_label: Label = $UI/HeldLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var win_label: Label = $UI/WinLabel
# Collect references to all pens so we can check the win condition
@onready var pens: Array = [
	$PenPink,
	$PenGreen,
	$PenBlue,
]

func _ready() -> void:
	# Set up each pen with its colour and type
	$PenPink.setup("pink",  Color(1.00, 0.55, 0.75))
	$PenGreen.setup("green", Color(0.30, 0.90, 0.40))
	$PenBlue.setup("blue",  Color(0.25, 0.60, 1.00))
	_spawn_slimes()

func _spawn_slimes() -> void:
	for i in SLIME_COUNT:
		# Pick a random slime type
		var data = SLIME_TYPES[randi() % SLIME_TYPES.size()]
		var slime = SlimeScene.instantiate()
		add_child(slime)
		# Place randomly across the field, at a safe height
		slime.global_position = Vector3(
			randf_range(-FIELD_SIZE, FIELD_SIZE),
			1.0,
			randf_range(-FIELD_SIZE, FIELD_SIZE)
		)
		slime.setup(data.color, data.type)
		# Add to the 'slimes' group so player.gd can find them all
		slime.add_to_group("slimes")

func _process(_delta: float) -> void:
	_update_hud()
	_check_win()

func _update_hud() -> void:
	var held = player.held_slimes.size()
	held_label.text = "Held: %d / %d" % [held, 5]
	if player.near_pen != null:
		hint_label.text = "[F] Deposit slime"
	elif held < 5:
		hint_label.text = "[E] Collect nearby slime"
	else:
		hint_label.text = "Pockets full! Find a pen."

func _check_win() -> void:
	for pen in pens:
		if not pen.get_is_full():
			return  # At least one pen is not full yet
	# All pens are full!
	win_label.visible = true
	hint_label.text = ""

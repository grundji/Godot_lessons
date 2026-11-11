extends Node3D

# Preload all three scenes so we can spawn them at any time
const BlockScene = preload("res://scenes/Block.tscn")
const StackedBlockScene = preload("res://scenes/StackedBlock.tscn")
const DebrisScene = preload("res://scenes/Debris.tscn")

# The height of every block --- same for all blocks in this game
const BLOCK_HEIGHT: float = 0.4
# The starting size for the first block (x width, y height, z depth)
const INITIAL_SIZE: Vector3 = Vector3(3.0, 0.4, 3.0)
# How far off-screen the block spawns before sliding in
const SPAWN_OFFSET: float = 5.5
# Colour palette --- we cycle through these as the tower grows
const COLORS: Array[Color] = [
	Color(1.00, 0.35, 0.35),  # red
	Color(1.00, 0.60, 0.20),  # orange
	Color(1.00, 0.95, 0.30),  # yellow
	Color(0.35, 0.90, 0.40),  # green
	Color(0.30, 0.75, 1.00),  # sky blue
	Color(0.65, 0.35, 1.00),  # purple
]

# The stack stores data about every placed block
# Each entry is a Dictionary: { pos: Vector3, size: Vector3 }
var stack: Array = []
# Reference to the block that is currently moving
# (left untyped: main.gd calls the block's custom stop(), block_size and
# move_axis, which Godot 4 rejects through a base-class type)
var current_block = null
# Player's score --- increases by 1 each successful placement
var score: int = 0
# Becomes true when the player misses --- stops all updates
var game_over: bool = false

# References to UI nodes --- set with @onready
@onready var camera: Camera3D = $Camera3D
@onready var score_label: Label = $UI/ScoreLabel
@onready var game_over_panel: Panel = $UI/GameOverPanel

func _ready() -> void:
	# Create the first entry in the stack --- the base platform
	var base_entry = { pos = Vector3.ZERO, size = INITIAL_SIZE }
	stack.append(base_entry)
	# Spawn a visible StackedBlock at the origin
	_spawn_stacked_block(Vector3.ZERO, INITIAL_SIZE, Color(0.45, 0.45, 0.45))
	# Spawn the first moving block above the base
	_spawn_next_block()

func _input(event: InputEvent) -> void:
	# If the game is over, only listen for restart
	if game_over:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	# Detect a left mouse button press
	var clicked = event is InputEventMouseButton \
		and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	# Detect Space or Enter (ui_accept)
	var spaced = event is InputEventKey \
		and event.pressed \
		and not event.echo \
		and event.keycode == KEY_SPACE
	if clicked or spaced:
		_drop_block()

func _drop_block() -> void:
	if current_block == null or game_over:
		return
	# Tell the block to stop moving
	current_block.stop()
	# Calculate the cut
	_process_cut()

func _process_cut() -> void:
	var top = stack.back()
	var cur_pos = current_block.position
	var cur_size = current_block.block_size
	var new_pos = cur_pos
	var new_size = cur_size
	if current_block.move_axis == "x":
		var result = _calc_overlap_1d(
			cur_pos.x, cur_size.x,  # Moving block centre and width
			top.pos.x, top.size.x   # Tower top centre and width
		)
		if result.overlap <= 0.001:
			_trigger_game_over()
			return
		new_pos.x = result.center
		new_size.x = result.overlap
		# Spawn debris for the cut-off part
		if result.debris_size > 0.01:
			var d_pos = cur_pos
			d_pos.x = result.debris_center
			_spawn_debris(d_pos,
				Vector3(result.debris_size, cur_size.y, cur_size.z),
				COLORS[score % COLORS.size()])
	else:
		var result = _calc_overlap_1d(
			cur_pos.z, cur_size.z,
			top.pos.z, top.size.z
		)
		if result.overlap <= 0.001:
			_trigger_game_over()
			return
		new_pos.z = result.center
		new_size.z = result.overlap
		# Spawn debris for the cut-off part
		if result.debris_size > 0.01:
			var d_pos = cur_pos
			d_pos.z = result.debris_center
			_spawn_debris(d_pos,
				Vector3(cur_size.x, cur_size.y, result.debris_size),
				COLORS[score % COLORS.size()])
	# Remove the moving block
	current_block.queue_free()
	current_block = null
	# Place the trimmed block on the stack
	new_pos.y = top.pos.y + BLOCK_HEIGHT
	stack.append({ pos = new_pos, size = new_size })
	_spawn_stacked_block(new_pos, new_size, COLORS[score % COLORS.size()])
	score += 1
	score_label.text = "Score: %d" % score
	_spawn_next_block()

# Compares two blocks on a single axis and returns overlap data
func _calc_overlap_1d(
	cur_center: float, cur_len: float,
	top_center: float, top_len: float) -> Dictionary:
	# Calculate min and max edges of each block
	var ol_min = max(cur_center - cur_len * 0.5, top_center - top_len * 0.5)
	var ol_max = min(cur_center + cur_len * 0.5, top_center + top_len * 0.5)
	# The overlap is between the inner edges
	var overlap = max(ol_max - ol_min, 0.0)
	var center = (ol_min + ol_max) * 0.5
	# Debris = the bit that did NOT land on the tower
	var debris_size = max(cur_len - overlap, 0.0)
	var debris_center = cur_center + sign(cur_center - top_center) * (overlap * 0.5 + debris_size * 0.5)
	return {
		overlap = overlap,
		center = center,
		debris_size = debris_size,
		debris_center = debris_center,
	}

func _spawn_next_block() -> void:
	var top = stack.back()
	# Alternate between X and Z each level
	var axis = "z" if stack.size() % 2 == 0 else "x"
	# Speed increases by 0.12 units/sec each block
	var speed = 3.0 + score * 0.12
	var color = COLORS[score % COLORS.size()]
	var block = BlockScene.instantiate()
	add_child(block)
	# Start at tower height, offset to the side
	var spawn_y = top.pos.y + BLOCK_HEIGHT
	block.position = Vector3(0, spawn_y, 0)
	if axis == "x":
		block.position.x = -SPAWN_OFFSET
	else:
		block.position.z = -SPAWN_OFFSET
	block.setup(top.size, axis, speed, color)
	current_block = block

func _spawn_stacked_block(pos: Vector3, size: Vector3, color: Color) -> void:
	var block = StackedBlockScene.instantiate()
	add_child(block)
	block.position = pos
	block.setup(size, color)

func _spawn_debris(pos: Vector3, size: Vector3, color: Color) -> void:
	var debris = DebrisScene.instantiate()
	add_child(debris)
	debris.position = pos
	debris.setup(size, color)

func _trigger_game_over() -> void:
	game_over = true
	if current_block:
		current_block.queue_free()
		current_block = null
	game_over_panel.visible = true

# _process runs every frame
func _process(delta: float) -> void:
	# Smoothly move the camera up as the tower grows
	var target_y = stack.back().pos.y + 10.0
	camera.position.y = lerp(camera.position.y, target_y, delta * 4.0)

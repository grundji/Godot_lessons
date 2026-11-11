extends Control
### Operation-style mini-game. Guide the tool, don't touch the edges.

const TOOL_SPEED := 220.0

var lives := 3
var is_playing := false
var start_pos := Vector2.ZERO

@onready var tool: ColorRect = $Tool
@onready var path: ColorRect = $Path
@onready var win_zone: ColorRect = $WinZone
@onready var lives_label: Label = $LivesLabel
@onready var message_label: Label = $MessageLabel

func _ready() -> void:
	start_pos = tool.position
	message_label.visible = false
	_update_lives()

func start_game() -> void:
	is_playing = true
	lives = 3
	tool.position = start_pos
	message_label.visible = false
	_update_lives()

func _process(delta: float) -> void:
	if not is_playing:
		return
	_move_tool(delta)
	_check_edges()

func _move_tool(delta: float) -> void:
	var dir := Vector2.ZERO
	dir.x = Input.get_axis("move_left", "move_right")
	dir.y = Input.get_axis("move_forward", "move_back")
	tool.position += dir * TOOL_SPEED * delta

func _check_edges() -> void:
	var tool_rect := Rect2(tool.position, tool.size)
	var path_rect := Rect2(path.position, path.size)
	var win_rect := Rect2(win_zone.position, win_zone.size)
	if win_rect.encloses(tool_rect):
		_on_win_zone_entered()
		return
	if not path_rect.encloses(tool_rect):
		_lose_life()

func _lose_life() -> void:
	lives -= 1
	_update_lives()
	tool.position = start_pos
	if lives <= 0:
		_game_over()

func _update_lives() -> void:
	lives_label.text = "Lives: %d" % lives

func _game_over() -> void:
	is_playing = false
	message_label.text = "Out of lives! Try again."
	message_label.visible = true

func _on_win_zone_entered() -> void:
	is_playing = false
	message_label.text = "Stable! You did it!"
	message_label.visible = true

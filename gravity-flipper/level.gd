extends Node2D

# Path to the next level --- change this per level scene
@export var next_level: String = "res://scenes/Level2.tscn"

# (player is left untyped: the level connects the player's custom
# died and level_won signals, which Godot 4 rejects through a
# base-class type)
@onready var player = $Player
@onready var death_overlay: ColorRect = $DeathOverlay

func _ready() -> void:
	# Make sure the player is in the 'player' group
	player.add_to_group("player")
	# Connect the player's custom signals
	player.died.connect(_on_player_died)
	player.level_won.connect(_on_level_won)
	# Hide the death overlay (we will fade it in on death)
	death_overlay.color = Color(0.8, 0.1, 0.1, 0.0)   # Red, invisible
	death_overlay.visible = true

func _on_player_died() -> void:
	# Flash the screen red, then reload
	var tween = create_tween()
	tween.tween_property(death_overlay, "color:a", 0.7, 0.1)  # Fade in
	tween.tween_interval(0.2)                                   # Hold
	tween.tween_callback(func():
		get_tree().reload_current_scene()                        # Restart
	)

func _on_level_won() -> void:
	# Flash the screen white, then load next level
	var tween = create_tween()
	death_overlay.color = Color(1, 1, 1, 0.0)    # White flash
	tween.tween_property(death_overlay, "color:a", 1.0, 0.3)
	tween.tween_interval(0.1)
	tween.tween_callback(func():
		if ResourceLoader.exists(next_level):
			get_tree().change_scene_to_file(next_level)
		else:
			_show_win_screen()
	)

# No more levels --- show a simple win message
func _show_win_screen() -> void:
	death_overlay.color = Color(0.1, 0.0, 0.2, 0.9)
	var label = Label.new()
	add_child(label)
	label.text = "YOU WIN!\nPress R to play again"
	label.position = Vector2(160, 100)
	label.add_theme_font_size_override("font_size", 24)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

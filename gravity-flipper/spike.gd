extends Area2D

func _ready() -> void:
	# Connect the body_entered signal to our handler
	body_entered.connect(_on_body_entered)

# (body is left untyped: the handler calls the player's custom
# kill(), which Godot 4 rejects through a base-class type)
func _on_body_entered(body) -> void:
	# Only kill CharacterBody2D nodes in the 'player' group
	if body.is_in_group("player"):
		body.kill()

extends CharacterBody3D

const SPEED: float = 8.0
const VERT_SPEED: float = 6.0
const BLAST_COOLDOWN: float = 1.0

const WindBlastScene = preload("res://scenes/WindBlast.tscn")

var _blast_timer: float = 0.0

# Player movement section — attach to the Player CharacterBody3D
func _physics_process(delta: float) -> void:
	if _blast_timer > 0:
		_blast_timer -= delta
	var dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity.x = dir.x * SPEED
	velocity.z = dir.y * SPEED
	# Q = rise, E = descend
	if Input.is_action_pressed("move_up"):
		velocity.y = VERT_SPEED
	elif Input.is_action_pressed("move_down"):
		velocity.y = -VERT_SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, VERT_SPEED)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("wind_blast") and _blast_timer <= 0:
		_blast_timer = BLAST_COOLDOWN
		var blast = WindBlastScene.instantiate()
		get_parent().add_child(blast)
		blast.global_position = global_position

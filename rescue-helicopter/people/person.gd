extends CharacterBody3D
### A stranded person. Waits on a rooftop, then rides the winch.

var is_rescued := false
var is_being_lifted := false

func _physics_process(_delta: float) -> void:
	if is_being_lifted:
		return
	if not is_on_floor():
		velocity.y -= 9.8 * _delta
	else:
		velocity.y = 0.0
	move_and_slide()

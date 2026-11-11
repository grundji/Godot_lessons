extends Node2D

enum BobberState { IDLE, WAITING, BITE }

signal bite_ready # Emitted when the bobber dips — player can reel
signal bite_missed # Emitted if the player does not reel in time

# How long the player has to press Reel after a bite
const BITE_WINDOW: float = 1.8

var state: BobberState = BobberState.IDLE
var _bite_timer: float = 0.0

@onready var anim: AnimationPlayer = $Anim
@onready var splash_particles: GPUParticles2D = $SplashParticles
@onready var float_body: ColorRect = $FloatBody
@onready var float_bottom: ColorRect = $FloatBottom

func _process(delta: float) -> void:
	if state == BobberState.BITE:
		_bite_timer -= delta
		if _bite_timer <= 0.0:
			# Player missed the window
			state = BobberState.IDLE
			anim.stop()
			visible = false
			bite_missed.emit()

# Called by game.gd when the player casts
func cast(water_pos: Vector2) -> void:
	global_position = water_pos
	visible = true
	state = BobberState.WAITING
	anim.play("bob")
	# Colour the bobber normally
	float_body.color = Color(0.85, 0.15, 0.15)

# Called by game.gd when a fish bites
func trigger_bite() -> void:
	state = BobberState.BITE
	_bite_timer = BITE_WINDOW
	anim.play("bite")
	# Flash the bobber bright yellow to alert the player
	var tween = create_tween().set_loops(3)
	tween.tween_property(float_body, "color", Color.YELLOW, 0.12)
	tween.tween_property(float_body, "color", Color(0.85, 0.15, 0.15), 0.12)
	splash_particles.restart()
	splash_particles.emitting = true
	bite_ready.emit()

# Called by game.gd when the player successfully reels
func reel_in() -> void:
	state = BobberState.IDLE
	visible = false
	anim.stop()

# Called when the player reels at the wrong time
func reel_miss() -> void:
	state = BobberState.IDLE
	visible = false
	anim.stop()

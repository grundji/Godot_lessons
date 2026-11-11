extends CharacterBody2D

# ── Constants ─────────────────────────────────────────────────────
const RUN_SPEED: float = 120.0   # Pixels per second (auto-run to the right)
const GRAVITY: float = 600.0     # Pixels per second squared
const FLIP_COOLDOWN: float = 0.15  # Seconds before the player can flip again
# ── State ──────────────────────────────────────────────────────────
var gravity_direction: int = 1   # 1 = normal down, -1 = flipped up
var is_dead: bool = false
var _flip_timer: float = 0.0     # Counts down between flips
# ── Signals ────────────────────────────────────────────────────────
signal died          # Emitted when the player hits a spike or falls out
signal level_won     # Emitted when the player touches the portal
# ── References ─────────────────────────────────────────────────────
@onready var body: ColorRect = $Body
@onready var flip_particles: GPUParticles2D = $FlipParticles
@onready var camera: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	# ── Flip cooldown timer ────────────────────────────────────
	if _flip_timer > 0.0:
		_flip_timer -= delta
	# ── Gravity flip input ────────────────────────────────────
	if Input.is_action_just_pressed("flip") and _flip_timer <= 0.0:
		_flip_gravity()
	# ── Restart input ─────────────────────────────────────────
	if Input.is_action_just_pressed("restart"):
		died.emit()
	# ── Apply gravity in the current direction ─────────────────
	# gravity_direction is 1 (fall down) or -1 (fall up)
	velocity.y += GRAVITY * gravity_direction * delta
	# ── Auto-run to the right, always ─────────────────────────
	velocity.x = RUN_SPEED
	# ── Move and detect collisions ────────────────────────────
	move_and_slide()
	# ── Fell off the screen --- treat as death ──────────────────
	if position.y > 400 or position.y < -200:
		_die()

func _flip_gravity() -> void:
	gravity_direction *= -1    # Toggle between 1 and -1
	_flip_timer = FLIP_COOLDOWN
	# Burst particles at the flip point
	flip_particles.restart()
	flip_particles.emitting = true
	# Visually flip the player sprite upside down
	body.scale.y = gravity_direction  # 1 = normal, -1 = upside down
	# Give a small velocity kick in the new gravity direction
	# so the flip feels responsive, not floaty
	velocity.y = -200.0 * gravity_direction

func _die() -> void:
	if is_dead:
		return
	is_dead = true
	visible = false
	died.emit()           # Level script listens to this signal

# ── Called by Spike.tscn when the player overlaps it ─────────
func kill() -> void:
	_die()

# ── Called by Portal.tscn when the player touches it ─────────
func win() -> void:
	if is_dead:
		return
	is_dead = true        # Prevent double-triggering
	level_won.emit()      # Level script loads the next level

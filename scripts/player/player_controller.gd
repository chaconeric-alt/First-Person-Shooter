class_name PlayerController
extends CharacterBody3D

# Movement settings (tunable for Quake-like feel)
@export var move_speed: float = 10.0
@export var sprint_multiplier: float = 1.5
@export var jump_velocity: float = 8.0
@export var air_control: float = 0.3
@export var friction_ground: float = 10.0
@export var friction_air: float = 0.5
@export var gravity: float = 25.0
@export var max_health: float = 100.0
@export var max_armor: float = 100.0
@export var mouse_sensitivity: float = 0.002

var health: float = 100.0
var armor: float = 0.0
var current_weapon_index: int = 0
var weapons: Array = []  # Equipped weapon instances

signal health_changed(new_health: float, max_health_val: float)
signal armor_changed(new_armor: float, max_armor_val: float)
signal weapon_changed(weapon_data: Dictionary)
signal player_died()

func _ready() -> void:
	"""Initialize player, load starting weapons."""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	health = max_health
	print("Player controller ready - mouse captured")

func _physics_process(delta: float) -> void:
	"""
	Handle movement with:
	- Quake-style physics
	- Air strafing
	- Ground friction
	"""
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Get input direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		# Ground movement
		if direction:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, friction_ground * delta * move_speed)
			velocity.z = move_toward(velocity.z, 0, friction_ground * delta * move_speed)
		
		# Jump
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
	else:
		# Air control
		if direction:
			velocity.x += direction.x * move_speed * air_control * delta * 10
			velocity.z += direction.z * move_speed * air_control * delta * 10
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	"""Handle weapon switching, firing, interaction."""
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Rotate player body (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate camera (pitch)
		var camera = $Camera3D
		if camera:
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func take_damage(amount: float, source: Node3D = null) -> void:
	"""Apply damage with armor calculation. Armor absorbs 66% of damage."""
	var armor_absorb = min(armor, amount * 0.66)
	armor -= armor_absorb
	var health_damage = amount - armor_absorb
	health -= health_damage
	
	health_changed.emit(health, max_health)
	armor_changed.emit(armor, max_armor)
	
	if health <= 0:
		player_died.emit()
		print("Player died!")

func heal(amount: float) -> void:
	"""Restore health up to max_health."""
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func add_armor(amount: float) -> void:
	"""Add armor up to max_armor."""
	armor = min(armor + amount, max_armor)
	armor_changed.emit(armor, max_armor)

extends Node3D

func _ready() -> void:
	"""Initialize test scene with procedural level."""
	print("Main scene ready - creating test level")
	
	# Create test environment
	var sky = ProceduralAssets.create_procedural_sky("day")
	add_child(sky)
	
	# Create simple test room
	_create_test_room()
	
	# Create player
	_create_player()
	
	# Add some test enemies
	_spawn_test_enemies()

func _create_test_room() -> void:
	"""Create a simple room for testing."""
	# Floor
	for x in range(-5, 6):
		for z in range(-5, 6):
			var floor = ProceduralAssets.create_floor_tile()
			floor.position = Vector3(x * 4, 0, z * 4)
			add_child(floor)
	
	# Walls (simple perimeter)
	for x in range(-5, 6):
		# Front and back walls
		var wall_front = ProceduralAssets.create_wall_segment()
		wall_front.position = Vector3(x * 4, 2, -20)
		add_child(wall_front)
		
		var wall_back = ProceduralAssets.create_wall_segment()
		wall_back.position = Vector3(x * 4, 2, 20)
		add_child(wall_back)
	
	for z in range(-4, 5):
		# Left and right walls
		var wall_left = ProceduralAssets.create_wall_segment()
		wall_left.position = Vector3(-20, 2, z * 4)
		wall_left.rotation_degrees.y = 90
		add_child(wall_left)
		
		var wall_right = ProceduralAssets.create_wall_segment()
		wall_right.position = Vector3(20, 2, z * 4)
		wall_right.rotation_degrees.y = 90
		add_child(wall_right)
	
	print("Test room created with floor and walls")

func _create_player() -> void:
	"""Create and position player."""
	var player = CharacterBody3D.new()
	player.name = "Player"
	
	# Add collision shape
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)
	
	# Add camera
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.6
	camera.current = true
	player.add_child(camera)
	
	# Add player script
	var script = load("res://scripts/player/player_controller.gd")
	if script:
		player.set_script(script)
	
	# Position player
	player.position = Vector3(0, 2, 0)
	player.add_to_group("player")
	
	add_child(player)
	GameManager.player = player
	
	print("Player created at position ", player.position)

func _spawn_test_enemies() -> void:
	"""Spawn some test enemies in the room."""
	# Spawn a grunt
	var grunt_visual = ProceduralAssets.create_enemy_by_type("grunt")
	grunt_visual.position = Vector3(8, 0, 8)
	add_child(grunt_visual)
	
	# Spawn a sniper
	var sniper_visual = ProceduralAssets.create_enemy_by_type("sniper")
	sniper_visual.position = Vector3(-8, 0, 8)
	add_child(sniper_visual)
	
	# Spawn a brute
	var brute_visual = ProceduralAssets.create_enemy_by_type("brute")
	brute_visual.position = Vector3(8, 0, -8)
	add_child(brute_visual)
	
	# Spawn a swarm
	var swarm_visual = ProceduralAssets.create_enemy_by_type("swarm")
	swarm_visual.position = Vector3(-8, 0, -8)
	add_child(swarm_visual)
	
	# Add some items
	var health = ProceduralAssets.create_item_health_small()
	health.position = Vector3(0, 0.5, -10)
	add_child(health)
	
	var armor = ProceduralAssets.create_item_armor_shard()
	armor.position = Vector3(-10, 0.5, 0)
	add_child(armor)
	
	var ammo = ProceduralAssets.create_item_ammo("shells")
	ammo.position = Vector3(10, 0.5, 0)
	add_child(ammo)
	
	print("Test enemies and items spawned")

func _input(event: InputEvent) -> void:
	"""Handle global input."""
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			GameManager.resume_game()
		else:
			GameManager.pause_game()

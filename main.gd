extends Node3D

## Path checked first.  If a CSV exists here it is loaded directly.
## The Python level_generator writes to this same directory:
##   python -m level_generator generate -o levels/map.csv
const LEVEL_CSV_PATH := "res://levels/map.csv"

func _ready() -> void:
	"""Load a level CSV if one exists, otherwise generate a maze at runtime."""
	print("Main scene ready")

	# 1. Try to load a pre-generated level CSV
	var level: LevelData = LevelData.load_csv(LEVEL_CSV_PATH)

	if level:
		print("Loaded level from CSV: ", LEVEL_CSV_PATH)
	else:
		# 2. No CSV found — generate a maze in GDScript
		print("No level CSV found at %s — generating maze" % LEVEL_CSV_PATH)
		var gen := MazeGen.new()
		gen.rooms_x = 5
		gen.rooms_y = 5
		gen.room_width = 3
		gen.room_height = 3
		gen.extra_doors = 0.15
		gen.num_exits = 1
		gen.theme_name = "default"
		gen.maze_seed = -1  # random
		level = gen.generate()

		# Save so subsequent runs reuse the same map
		level.save_csv(LEVEL_CSV_PATH)
		print("Generated %dx%d maze, saved to %s" % [level.width, level.height, LEVEL_CSV_PATH])

	# 3. Build 3D geometry from the grid
	var result: Dictionary = LevelBuilder.build(level, self)

	# 4. Create the player at the entry tile
	_create_player(result.spawn_point)

	# 5. Scatter enemies across rooms (skip the entry room)
	_spawn_enemies_in_level(level)

	print("Level ready — %dx%d tiles, theme=%s" % [level.width, level.height, level.theme_name])


func _create_player(spawn: Vector3) -> void:
	"""Create the FPS player at the given spawn point."""
	var player := CharacterBody3D.new()
	player.name = "Player"

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.5
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	player.add_child(collision)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = 1.6
	camera.current = true
	player.add_child(camera)

	var script = load("res://scripts/player/player_controller.gd")
	if script:
		player.set_script(script)

	player.position = spawn
	player.add_to_group("player")
	add_child(player)
	GameManager.player = player
	print("Player spawned at ", spawn)


func _spawn_enemies_in_level(level: LevelData) -> void:
	"""Place enemies at floor tiles spread across the level."""
	# Collect all plain FLOOR positions
	var floor_positions: Array[Vector2i] = []
	for r in range(level.height):
		for c in range(level.width):
			if level.grid[r][c] == LevelData.TileType.FLOOR:
				floor_positions.append(Vector2i(r, c))

	if floor_positions.is_empty():
		return

	# Shuffle and pick a subset
	floor_positions.shuffle()
	var enemy_types := ["grunt", "sniper", "brute", "swarm"]
	var count := mini(floor_positions.size(), 8)

	for i in range(count):
		var pos := floor_positions[i]
		var world := Vector3(
			pos.y * LevelBuilder.TILE_SIZE,
			0.0,
			pos.x * LevelBuilder.TILE_SIZE
		)
		var etype: String = enemy_types[i % enemy_types.size()]
		var enemy := ProceduralAssets.create_enemy_by_type(etype)
		enemy.position = world
		add_child(enemy)

	# Drop a few pickups near the middle of the map
	var mid_idx := floor_positions.size() / 2
	for offset in range(3):
		if mid_idx + offset >= floor_positions.size():
			break
		var p := floor_positions[mid_idx + offset]
		var wpos := Vector3(
			p.y * LevelBuilder.TILE_SIZE,
			0.5,
			p.x * LevelBuilder.TILE_SIZE
		)
		var items := ["health", "armor", "ammo_shells"]
		var item := ProceduralAssets.create_item_by_type(items[offset % items.size()])
		item.position = wpos
		add_child(item)

	print("Spawned %d enemies and pickups" % count)


func _input(event: InputEvent) -> void:
	"""Handle global input."""
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			GameManager.resume_game()
		else:
			GameManager.pause_game()

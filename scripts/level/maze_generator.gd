class_name MazeGen
extends RefCounted

## GDScript port of the Python level_generator maze algorithm.
## Generates a maze of interconnected rooms using recursive backtracking.

## Number of rooms on each axis.
var rooms_x: int = 5
var rooms_y: int = 5
## Interior tile dimensions of each room.
var room_width: int = 3
var room_height: int = 3
## Width of doorways in tiles.
var door_width: int = 1
## Probability (0.0–1.0) of punching extra doors to create loops.
var extra_doors: float = 0.1
## Minimum number of exit tiles.
var num_exits: int = 1
## Theme tag written into the level metadata.
var theme_name: String = "default"
## RNG seed.  -1 means use a random seed.
var maze_seed: int = -1

const _DIRS: Array[Vector2i] = [
	Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)
]


func generate() -> LevelData:
	if maze_seed >= 0:
		seed(maze_seed)
	else:
		randomize()

	var grid_w: int = rooms_x * (room_width + 1) + 1
	var grid_h: int = rooms_y * (room_height + 1) + 1
	var level := LevelData.new(grid_w, grid_h, theme_name)

	# Fill with walls
	for r in range(grid_h):
		for c in range(grid_w):
			level.set_tile(r, c, LevelData.TileType.WALL)

	# Carve room interiors
	for ry in range(rooms_y):
		for rx in range(rooms_x):
			_carve_room(level, rx, ry)

	# Pillars at wall intersections
	_place_pillars(level)

	# Recursive backtracking to connect rooms
	var visited: Array = []
	for ry in range(rooms_y):
		var row: Array[bool] = []
		row.resize(rooms_x)
		row.fill(false)
		visited.append(row)
	_carve_maze(level, visited, 0, 0)

	# Random extra doors for loops
	_add_extra_doors(level)

	# Place entry and exits
	_place_entry_and_exits(level)

	return level


# --- internals ---------------------------------------------------------------

func _room_top_left(rx: int, ry: int) -> Vector2i:
	return Vector2i(ry * (room_height + 1) + 1, rx * (room_width + 1) + 1)


func _carve_room(level: LevelData, rx: int, ry: int) -> void:
	var tl := _room_top_left(rx, ry)
	for dr in range(room_height):
		for dc in range(room_width):
			level.set_tile(tl.x + dr, tl.y + dc, LevelData.TileType.FLOOR)


func _place_pillars(level: LevelData) -> void:
	for ry in range(rooms_y + 1):
		for rx in range(rooms_x + 1):
			var r: int = ry * (room_height + 1)
			var c: int = rx * (room_width + 1)
			level.set_tile(r, c, LevelData.TileType.PILLAR)


func _carve_maze(level: LevelData, visited: Array, rx: int, ry: int) -> void:
	visited[ry][rx] = true
	var dirs := _DIRS.duplicate()
	# Shuffle directions
	for i in range(dirs.size() - 1, 0, -1):
		var j: int = randi() % (i + 1)
		var tmp := dirs[i]
		dirs[i] = dirs[j]
		dirs[j] = tmp

	for d in dirs:
		var nx: int = rx + d.y   # d.y = delta column  -> maps to room x
		var ny: int = ry + d.x   # d.x = delta row     -> maps to room y
		if nx >= 0 and nx < rooms_x and ny >= 0 and ny < rooms_y and not visited[ny][nx]:
			_carve_door(level, rx, ry, d.y, d.x)
			_carve_maze(level, visited, nx, ny)


func _carve_door(level: LevelData, rx: int, ry: int, drx: int, dry: int) -> void:
	var tl := _room_top_left(rx, ry)
	if drx == 1:
		var wall_col: int = tl.y + room_width
		var center_row: int = tl.x + room_height / 2
		for d in range(door_width):
			level.set_tile(center_row + d, wall_col, LevelData.TileType.DOOR)
	elif drx == -1:
		var wall_col: int = tl.y - 1
		var center_row: int = tl.x + room_height / 2
		for d in range(door_width):
			level.set_tile(center_row + d, wall_col, LevelData.TileType.DOOR)
	elif dry == 1:
		var wall_row: int = tl.x + room_height
		var center_col: int = tl.y + room_width / 2
		for d in range(door_width):
			level.set_tile(wall_row, center_col + d, LevelData.TileType.DOOR)
	elif dry == -1:
		var wall_row: int = tl.x - 1
		var center_col: int = tl.y + room_width / 2
		for d in range(door_width):
			level.set_tile(wall_row, center_col + d, LevelData.TileType.DOOR)


func _add_extra_doors(level: LevelData) -> void:
	if extra_doors <= 0.0:
		return
	for ry in range(rooms_y):
		for rx in range(rooms_x):
			if rx + 1 < rooms_x and randf() < extra_doors:
				var tl := _room_top_left(rx, ry)
				var wall_col: int = tl.y + room_width
				var center_row: int = tl.x + room_height / 2
				if level.get_tile(center_row, wall_col) == LevelData.TileType.WALL:
					level.set_tile(center_row, wall_col, LevelData.TileType.DOOR)
			if ry + 1 < rooms_y and randf() < extra_doors:
				var tl := _room_top_left(rx, ry)
				var wall_row: int = tl.x + room_height
				var center_col: int = tl.y + room_width / 2
				if level.get_tile(wall_row, center_col) == LevelData.TileType.WALL:
					level.set_tile(wall_row, center_col, LevelData.TileType.DOOR)


func _place_entry_and_exits(level: LevelData) -> void:
	# Entry in centre of room (0, 0)
	var entry_tl := _room_top_left(0, 0)
	level.set_entry(entry_tl.x + room_height / 2, entry_tl.y + room_width / 2)

	# BFS over room graph to find farthest rooms for exits
	var dist: Array = []
	for ry in range(rooms_y):
		var row: Array[int] = []
		row.resize(rooms_x)
		row.fill(-1)
		dist.append(row)
	dist[0][0] = 0

	var queue: Array[Vector2i] = [Vector2i(0, 0)]
	var head: int = 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for d in _DIRS:
			var nx: int = cur.x + d.y
			var ny: int = cur.y + d.x
			if nx >= 0 and nx < rooms_x and ny >= 0 and ny < rooms_y \
					and dist[ny][nx] == -1 \
					and _has_door_between(level, cur.x, cur.y, d.y, d.x):
				dist[ny][nx] = dist[cur.y][cur.x] + 1
				queue.append(Vector2i(nx, ny))

	# Collect rooms sorted by distance descending
	var room_list: Array = []
	for ry in range(rooms_y):
		for rx in range(rooms_x):
			if dist[ry][rx] >= 0 and not (rx == 0 and ry == 0):
				room_list.append({"dist": dist[ry][rx], "rx": rx, "ry": ry})
	room_list.sort_custom(func(a, b): return a.dist > b.dist)

	var placed: int = 0
	for room in room_list:
		if placed >= num_exits:
			break
		var tl := _room_top_left(room.rx, room.ry)
		level.add_exit(tl.x + room_height / 2, tl.y + room_width / 2)
		placed += 1

	# Safety fallback
	if level.exits.is_empty():
		var last_tl := _room_top_left(rooms_x - 1, rooms_y - 1)
		level.add_exit(last_tl.x + room_height / 2, last_tl.y + room_width / 2)


func _has_door_between(level: LevelData, rx: int, ry: int, drx: int, dry: int) -> bool:
	var tl := _room_top_left(rx, ry)
	var walkable := [LevelData.TileType.DOOR, LevelData.TileType.FLOOR]
	if drx == 1:
		return level.get_tile(tl.x + room_height / 2, tl.y + room_width) in walkable
	if drx == -1:
		return level.get_tile(tl.x + room_height / 2, tl.y - 1) in walkable
	if dry == 1:
		return level.get_tile(tl.x + room_height, tl.y + room_width / 2) in walkable
	if dry == -1:
		return level.get_tile(tl.x - 1, tl.y + room_width / 2) in walkable
	return false


## Return the world-space centres of each room, useful for placing enemies.
func get_room_centres() -> Array[Vector2i]:
	var centres: Array[Vector2i] = []
	for ry in range(rooms_y):
		for rx in range(rooms_x):
			var tl := _room_top_left(rx, ry)
			centres.append(Vector2i(tl.x + room_height / 2, tl.y + room_width / 2))
	return centres

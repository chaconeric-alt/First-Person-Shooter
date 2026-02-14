class_name LevelData
extends RefCounted

## Tile types matching the Python level_generator.level.TileType values.
enum TileType {
	VOID = 0,
	WALL = 1,
	FLOOR = 2,
	ENTRY = 3,
	EXIT = 4,
	DOOR = 5,
	PILLAR = 6,
}

var width: int
var height: int
var theme_name: String = "default"
var grid: Array = []          # Array[Array[int]]
var entry: Vector2i = Vector2i(-1, -1)
var exits: Array[Vector2i] = []


func _init(w: int = 0, h: int = 0, theme: String = "default") -> void:
	width = w
	height = h
	theme_name = theme
	grid = []
	for r in range(h):
		var row: Array[int] = []
		row.resize(w)
		row.fill(TileType.VOID)
		grid.append(row)


func get_tile(row: int, col: int) -> int:
	if row >= 0 and row < height and col >= 0 and col < width:
		return grid[row][col]
	return TileType.VOID


func set_tile(row: int, col: int, tile: int) -> void:
	if row >= 0 and row < height and col >= 0 and col < width:
		grid[row][col] = tile


func set_entry(row: int, col: int) -> void:
	entry = Vector2i(row, col)
	set_tile(row, col, TileType.ENTRY)


func add_exit(row: int, col: int) -> void:
	exits.append(Vector2i(row, col))
	set_tile(row, col, TileType.EXIT)


## Load a level from the CSV format produced by the Python level_generator.
## Returns null if the file cannot be read.
static func load_csv(path: String) -> LevelData:
	if not FileAccess.file_exists(path):
		return null

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var theme := "default"
	var rows: Array = []

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line == "":
			continue
		if line.begins_with("#"):
			if line.begins_with("# theme:"):
				theme = line.split(":", true, 1)[1].strip_edges()
			continue
		var cells := line.split(",")
		var row: Array[int] = []
		for c in cells:
			row.append(int(c.strip_edges()))
		rows.append(row)

	file.close()

	if rows.is_empty():
		return null

	var h := rows.size()
	var w: int = rows[0].size()
	var level := LevelData.new(w, h, theme)
	level.grid = rows

	# Reconstruct entry / exit positions from tile values
	for r in range(h):
		for c_idx in range(w):
			if rows[r][c_idx] == TileType.ENTRY:
				level.entry = Vector2i(r, c_idx)
			elif rows[r][c_idx] == TileType.EXIT:
				level.exits.append(Vector2i(r, c_idx))

	return level


## Save level to CSV in the same format the Python generator uses.
func save_csv(path: String) -> void:
	var dir_path := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_warning("LevelData: could not write to %s" % path)
		return

	file.store_line("# theme:%s" % theme_name)
	for row in grid:
		var parts: PackedStringArray = []
		for cell in row:
			parts.append(str(cell))
		file.store_line(",".join(parts))
	file.close()

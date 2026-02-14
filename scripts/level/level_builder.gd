class_name LevelBuilder
extends RefCounted

## Converts a LevelData grid into 3D geometry using ProceduralAssets.
##
## Each grid cell maps to a TILE_SIZE x TILE_SIZE area in world space.
## Returns a dictionary with spawn_point, exit_points, and room_centres.

const TILE_SIZE := 4.0
const WALL_HEIGHT := 4.0


## Build the 3D level under [param parent] and return placement info.
## Result keys: "spawn_point" (Vector3), "exit_points" (Array[Vector3]),
## "room_centres" (Array[Vector3]).
static func build(level: LevelData, parent: Node3D) -> Dictionary:
	var spawn_point := Vector3.ZERO
	var exit_points: Array[Vector3] = []

	for row in range(level.height):
		for col in range(level.width):
			var tile: int = level.grid[row][col]
			var world_pos := Vector3(col * TILE_SIZE, 0.0, row * TILE_SIZE)

			match tile:
				LevelData.TileType.FLOOR:
					_place_floor(parent, world_pos)

				LevelData.TileType.ENTRY:
					_place_floor(parent, world_pos)
					_place_entry_marker(parent, world_pos)
					spawn_point = world_pos + Vector3(0.0, 1.0, 0.0)

				LevelData.TileType.EXIT:
					_place_floor(parent, world_pos)
					_place_exit_marker(parent, world_pos)
					exit_points.append(world_pos)

				LevelData.TileType.DOOR:
					_place_floor(parent, world_pos)
					_place_door(parent, world_pos)

				LevelData.TileType.WALL:
					if _wall_is_visible(level, row, col):
						_place_wall(parent, world_pos)

				LevelData.TileType.PILLAR:
					_place_pillar(parent, world_pos)

				# VOID: nothing

	# Apply theme environment (ambient light, fog) if a theme JSON exists
	_apply_theme_environment(level.theme_name, parent)

	return {
		"spawn_point": spawn_point,
		"exit_points": exit_points,
	}


# --- placement helpers -------------------------------------------------------

static func _place_floor(parent: Node3D, pos: Vector3) -> void:
	var floor_tile := ProceduralAssets.create_floor_tile(Vector3(TILE_SIZE, 0.2, TILE_SIZE))
	floor_tile.position = pos
	parent.add_child(floor_tile)


static func _place_wall(parent: Node3D, pos: Vector3) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TILE_SIZE, WALL_HEIGHT, TILE_SIZE)
	mesh_instance.mesh = box
	mesh_instance.material_override = ProceduralAssets.create_material(
		Color(0.4, 0.38, 0.35), 0.05, 0.9
	)
	mesh_instance.position = pos + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)

	var static_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)

	parent.add_child(mesh_instance)


static func _place_pillar(parent: Node3D, pos: Vector3) -> void:
	var pillar := ProceduralAssets.create_pillar(WALL_HEIGHT, 0.5)
	pillar.position = pos + Vector3(0.0, WALL_HEIGHT * 0.5, 0.0)
	parent.add_child(pillar)


static func _place_door(parent: Node3D, pos: Vector3) -> void:
	var door := ProceduralAssets.create_door(TILE_SIZE * 0.5, WALL_HEIGHT * 0.75)
	door.position = pos + Vector3(0.0, WALL_HEIGHT * 0.375, 0.0)
	parent.add_child(door)


static func _place_entry_marker(parent: Node3D, pos: Vector3) -> void:
	# Glowing green pad at spawn point
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TILE_SIZE * 0.6, 0.05, TILE_SIZE * 0.6)
	marker.mesh = box
	marker.material_override = ProceduralAssets.create_emissive_material(
		Color(0.2, 1.0, 0.3), 1.5
	)
	marker.position = pos + Vector3(0.0, 0.12, 0.0)
	parent.add_child(marker)


static func _place_exit_marker(parent: Node3D, pos: Vector3) -> void:
	# Glowing red pad at exit
	var marker := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(TILE_SIZE * 0.6, 0.05, TILE_SIZE * 0.6)
	marker.mesh = box
	marker.material_override = ProceduralAssets.create_emissive_material(
		Color(1.0, 0.2, 0.2), 2.0
	)
	marker.position = pos + Vector3(0.0, 0.12, 0.0)
	parent.add_child(marker)


## Skip walls that are completely hidden (all 4 neighbours are also WALL or PILLAR).
static func _wall_is_visible(level: LevelData, row: int, col: int) -> bool:
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var neighbor: int = level.get_tile(row + d.x, col + d.y)
		if neighbor != LevelData.TileType.WALL and neighbor != LevelData.TileType.PILLAR:
			return true
	return false


## Load theme JSON and apply ambient light / fog to a WorldEnvironment.
static func _apply_theme_environment(theme_name: String, parent: Node3D) -> void:
	var theme_path := "res://themes/%s.json" % theme_name
	if not FileAccess.file_exists(theme_path):
		# Fall back to procedural sky with defaults
		parent.add_child(ProceduralAssets.create_procedural_sky("day"))
		return

	var file := FileAccess.open(theme_path, FileAccess.READ)
	if not file:
		parent.add_child(ProceduralAssets.create_procedural_sky("day"))
		return

	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data is Dictionary:
		parent.add_child(ProceduralAssets.create_procedural_sky("day"))
		return

	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.background_mode = Environment.BG_SKY

	# Ambient light
	var amb: Array = data.get("ambient_light", [0.3, 0.3, 0.3])
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_color = Color(amb[0], amb[1], amb[2])
	env.ambient_light_energy = 0.6

	# Fog
	var fog_density: float = data.get("fog_density", 0.0)
	if fog_density > 0.0:
		var fc: Array = data.get("fog_color", [0.1, 0.1, 0.1])
		env.volumetric_fog_enabled = true
		env.volumetric_fog_albedo = Color(fc[0], fc[1], fc[2])
		env.volumetric_fog_density = fog_density

	world_env.environment = env
	parent.add_child(world_env)

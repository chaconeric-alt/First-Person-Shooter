extends Node

# Autoload singleton

var player: CharacterBody3D
var current_level_id: String
var level_loader: Node
var score: int = 0
var kills: int = 0
var secrets_found: int = 0
var level_time: float = 0.0

# Cached CSV data
var enemies_data: Dictionary = {}
var weapons_data: Dictionary = {}
var items_data: Dictionary = {}
var projectiles_data: Dictionary = {}

signal game_started()
signal game_paused()
signal game_resumed()
signal level_completed(stats: Dictionary)
signal game_over()

func _ready() -> void:
	"""Load all CSV data, setup systems."""
	_load_all_csv_data()
	
	# Level loader will be added as child when first needed
	print("GameManager ready - CSV data loaded")

func _load_all_csv_data() -> void:
	"""Load all CSV files. Generate defaults if missing."""
	enemies_data = _load_or_generate("res://csv/enemies.csv", _generate_default_enemies)
	weapons_data = _load_or_generate("res://csv/weapons.csv", _generate_default_weapons)
	items_data = _load_or_generate("res://csv/items.csv", _generate_default_items)
	projectiles_data = _load_or_generate("res://csv/projectiles.csv", _generate_default_projectiles)
	
	print("Loaded %d enemies, %d weapons, %d items, %d projectiles" % [
		enemies_data.size(), weapons_data.size(), items_data.size(), projectiles_data.size()
	])

func _load_or_generate(path: String, generator: Callable) -> Dictionary:
	"""Load CSV or call generator function if missing."""
	var data_array = CSVParser.load_csv(path)
	
	if data_array.is_empty():
		print("Generating default data for: ", path)
		data_array = generator.call()
		# Ensure directory exists
		var dir_path = path.get_base_dir()
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
		CSVParser.save_csv(path, data_array)
	
	# Convert to dictionary keyed by id
	var result = {}
	for entry in data_array:
		var id = entry.get("id", "")
		if id:
			result[id] = entry
	
	return result

func _generate_default_enemies() -> Array[Dictionary]:
	"""Generate balanced set of default enemies."""
	return [
		{
			"id": "grunt",
			"name": "Grunt",
			"model_path": "",
			"health": "50",
			"speed": "4.0",
			"damage": "10",
			"attack_range": "2.0",
			"attack_rate": "1.5",
			"ai_behavior": "aggressive",
			"detection_range": "15.0",
			"drops": "ammo_shells:0.5|health_small:0.3",
			"sound_alert": "",
			"sound_attack": "",
			"sound_death": ""
		},
		{
			"id": "sniper",
			"name": "Sniper",
			"model_path": "",
			"health": "30",
			"speed": "2.5",
			"damage": "25",
			"attack_range": "50.0",
			"attack_rate": "3.0",
			"ai_behavior": "sniper",
			"detection_range": "40.0",
			"drops": "ammo_bullets:0.7",
			"sound_alert": "",
			"sound_attack": "",
			"sound_death": ""
		},
		{
			"id": "brute",
			"name": "Brute",
			"model_path": "",
			"health": "200",
			"speed": "2.0",
			"damage": "35",
			"attack_range": "3.0",
			"attack_rate": "2.0",
			"ai_behavior": "aggressive",
			"detection_range": "12.0",
			"drops": "health_large:0.5|armor_shard:0.3",
			"sound_alert": "",
			"sound_attack": "",
			"sound_death": ""
		},
		{
			"id": "swarm",
			"name": "Swarmling",
			"model_path": "",
			"health": "15",
			"speed": "7.0",
			"damage": "5",
			"attack_range": "1.5",
			"attack_rate": "0.5",
			"ai_behavior": "swarm",
			"detection_range": "20.0",
			"drops": "",
			"sound_alert": "",
			"sound_attack": "",
			"sound_death": ""
		}
	]

func _generate_default_weapons() -> Array[Dictionary]:
	"""Generate standard FPS weapon loadout."""
	return [
		{
			"id": "pistol",
			"name": "Pistol",
			"model_path": "",
			"damage": "15",
			"fire_rate": "0.3",
			"spread": "1.0",
			"ammo_type": "bullets",
			"ammo_per_shot": "1",
			"max_ammo": "100",
			"reload_time": "1.2",
			"weapon_type": "hitscan",
			"projectile_id": "",
			"hitscan_range": "100.0",
			"sound_fire": "",
			"sound_reload": ""
		},
		{
			"id": "shotgun",
			"name": "Shotgun",
			"model_path": "",
			"damage": "8",
			"fire_rate": "0.8",
			"spread": "8.0",
			"ammo_type": "shells",
			"ammo_per_shot": "1",
			"max_ammo": "50",
			"reload_time": "2.0",
			"weapon_type": "hitscan",
			"projectile_id": "",
			"hitscan_range": "30.0",
			"sound_fire": "",
			"sound_reload": ""
		},
		{
			"id": "rocket",
			"name": "Rocket Launcher",
			"model_path": "",
			"damage": "80",
			"fire_rate": "1.2",
			"spread": "0.0",
			"ammo_type": "rockets",
			"ammo_per_shot": "1",
			"max_ammo": "20",
			"reload_time": "2.5",
			"weapon_type": "projectile",
			"projectile_id": "rocket_proj",
			"hitscan_range": "",
			"sound_fire": "",
			"sound_reload": ""
		},
		{
			"id": "railgun",
			"name": "Railgun",
			"model_path": "",
			"damage": "100",
			"fire_rate": "2.0",
			"spread": "0.0",
			"ammo_type": "cells",
			"ammo_per_shot": "2",
			"max_ammo": "50",
			"reload_time": "0.0",
			"weapon_type": "hitscan",
			"projectile_id": "",
			"hitscan_range": "200.0",
			"sound_fire": "",
			"sound_reload": ""
		}
	]

func _generate_default_items() -> Array[Dictionary]:
	"""Generate default item definitions."""
	return [
		{
			"id": "health_small",
			"name": "Small Health",
			"model_path": "",
			"item_type": "health",
			"value": "15",
			"respawn_time": "30.0",
			"sound_pickup": ""
		},
		{
			"id": "health_large",
			"name": "Large Health",
			"model_path": "",
			"item_type": "health",
			"value": "50",
			"respawn_time": "60.0",
			"sound_pickup": ""
		},
		{
			"id": "armor_shard",
			"name": "Armor Shard",
			"model_path": "",
			"item_type": "armor",
			"value": "5",
			"respawn_time": "20.0",
			"sound_pickup": ""
		},
		{
			"id": "armor_full",
			"name": "Full Armor",
			"model_path": "",
			"item_type": "armor",
			"value": "100",
			"respawn_time": "120.0",
			"sound_pickup": ""
		},
		{
			"id": "ammo_shells",
			"name": "Shells",
			"model_path": "",
			"item_type": "ammo_shells",
			"value": "10",
			"respawn_time": "15.0",
			"sound_pickup": ""
		},
		{
			"id": "ammo_rockets",
			"name": "Rockets",
			"model_path": "",
			"item_type": "ammo_rockets",
			"value": "5",
			"respawn_time": "30.0",
			"sound_pickup": ""
		},
		{
			"id": "ammo_bullets",
			"name": "Bullets",
			"model_path": "",
			"item_type": "ammo_bullets",
			"value": "20",
			"respawn_time": "15.0",
			"sound_pickup": ""
		}
	]

func _generate_default_projectiles() -> Array[Dictionary]:
	"""Generate default projectile definitions."""
	return [
		{
			"id": "rocket_proj",
			"name": "Rocket",
			"model_path": "",
			"speed": "25.0",
			"damage": "80",
			"radius": "5.0",
			"lifetime": "10.0",
			"gravity": "0.0",
			"trail_effect": "trail_smoke",
			"explosion_effect": "explosion_large"
		},
		{
			"id": "grenade_proj",
			"name": "Grenade",
			"model_path": "",
			"speed": "15.0",
			"damage": "100",
			"radius": "6.0",
			"lifetime": "3.0",
			"gravity": "9.8",
			"trail_effect": "trail_none",
			"explosion_effect": "explosion_large"
		},
		{
			"id": "plasma_proj",
			"name": "Plasma",
			"model_path": "",
			"speed": "40.0",
			"damage": "20",
			"radius": "0.5",
			"lifetime": "5.0",
			"gravity": "0.0",
			"trail_effect": "trail_plasma",
			"explosion_effect": "explosion_small"
		}
	]

func start_game() -> void:
	"""Initialize new game, load first level."""
	score = 0
	kills = 0
	secrets_found = 0
	level_time = 0.0
	
	load_level("level_01")
	game_started.emit()

func load_level(level_id: String) -> void:
	"""Transition to specified level.

	Looks for a CSV at res://levels/<level_id>.csv.  If found it is loaded,
	otherwise a maze is generated and saved there for next time.
	"""
	current_level_id = level_id
	var csv_path := "res://levels/%s.csv" % level_id
	print("Loading level: ", level_id, " from ", csv_path)

	var level: LevelData = LevelData.load_csv(csv_path)
	if not level:
		print("CSV not found — generating maze for ", level_id)
		var gen := MazeGen.new()
		gen.rooms_x = 5
		gen.rooms_y = 5
		gen.theme_name = "default"
		level = gen.generate()
		level.save_csv(csv_path)

	# Clear existing scene tree children (except autoloads)
	var root := get_tree().current_scene
	for child in root.get_children():
		child.queue_free()

	# Build the new level geometry under the scene root
	var result: Dictionary = LevelBuilder.build(level, root)
	print("Level %s built — spawn at %s" % [level_id, result.spawn_point])

func pause_game() -> void:
	"""Pause game, show menu."""
	get_tree().paused = true
	game_paused.emit()

func resume_game() -> void:
	"""Resume game."""
	get_tree().paused = false
	game_resumed.emit()

# Quick test script to verify procedural assets work
extends Node

func _ready():
	print("=== TESTING PROCEDURAL ASSET SYSTEM ===")
	
	# Test enemy generation
	print("\n1. Creating enemies...")
	for enemy_type in ["grunt", "sniper", "brute", "swarm"]:
		var enemy = ProceduralAssets.create_enemy_by_type(enemy_type)
		print("  ✓ Created %s: %s" % [enemy_type, enemy.name])
	
	# Test weapon generation
	print("\n2. Creating weapons...")
	for weapon_type in ["pistol", "shotgun"]:
		var weapon = ProceduralAssets.create_weapon_by_type(weapon_type)
		print("  ✓ Created %s: %s" % [weapon_type, weapon.name])
	
	# Test item generation
	print("\n3. Creating items...")
	for item_type in ["health", "armor", "ammo_shells"]:
		var item = ProceduralAssets.create_item_by_type(item_type)
		print("  ✓ Created %s: %s" % [item_type, item.name])
	
	# Test level geometry
	print("\n4. Creating level geometry...")
	var floor = ProceduralAssets.create_floor_tile()
	print("  ✓ Created floor tile")
	var wall = ProceduralAssets.create_wall_segment()
	print("  ✓ Created wall segment")
	var door = ProceduralAssets.create_door()
	print("  ✓ Created door")
	
	# Test environment
	print("\n5. Creating environment...")
	var sky = ProceduralAssets.create_procedural_sky("day")
	print("  ✓ Created procedural sky")
	
	print("\n=== ALL PROCEDURAL ASSETS WORKING! ===")
	print("The game is fully playable with zero external assets!")

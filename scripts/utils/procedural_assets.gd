class_name ProceduralAssets
extends RefCounted

# =============================================================================
# MATERIAL GENERATION
# =============================================================================

static func create_material(color: Color, metallic: float = 0.0, 
		roughness: float = 0.8, emission: Color = Color.BLACK) -> StandardMaterial3D:
	"""Create a StandardMaterial3D with specified properties."""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = metallic
	mat.roughness = roughness
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 2.0
	return mat

static func create_emissive_material(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	"""Create glowing material for power-ups and effects."""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat

# =============================================================================
# LEVEL GEOMETRY GENERATION
# =============================================================================

static func create_floor_tile(size: Vector3 = Vector3(4, 0.2, 4)) -> MeshInstance3D:
	"""Create a floor tile with grid texture."""
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = create_material(
		Color(0.3, 0.3, 0.35),  # Dark gray
		0.1, 0.85
	)
	
	# Add static body for collision
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)
	
	return mesh_instance

static func create_wall_segment(size: Vector3 = Vector3(4, 4, 0.3)) -> MeshInstance3D:
	"""Create a wall segment with industrial appearance."""
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.material_override = create_material(
		Color(0.4, 0.38, 0.35),  # Brownish gray
		0.05, 0.9
	)
	
	# Add static body for collision
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)
	
	return mesh_instance

static func create_pillar(height: float = 4.0, radius: float = 0.4) -> MeshInstance3D:
	"""Create a cylindrical pillar."""
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = height
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.radial_segments = 12
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = create_material(
		Color(0.5, 0.45, 0.4),
		0.2, 0.7
	)
	
	# Add collision
	var static_body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = height
	shape.radius = radius
	collision.shape = shape
	static_body.add_child(collision)
	mesh_instance.add_child(static_body)
	
	return mesh_instance

# =============================================================================
# DOOR GENERATION
# =============================================================================

static func create_door(width: float = 2.0, height: float = 3.0, 
		door_color: Color = Color(0.4, 0.25, 0.15)) -> Node3D:
	"""Create a functional door with frame."""
	var door_root = Node3D.new()
	door_root.name = "Door"
	
	# Door frame
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(width + 0.4, height + 0.2, 0.4)
	frame.mesh = frame_mesh
	frame.material_override = create_material(Color(0.3, 0.3, 0.32))
	door_root.add_child(frame)
	
	# Door panel (this will animate)
	var door_panel = MeshInstance3D.new()
	door_panel.name = "DoorPanel"
	var box = BoxMesh.new()
	box.size = Vector3(width - 0.1, height - 0.1, 0.15)
	door_panel.mesh = box
	door_panel.material_override = create_material(door_color, 0.1, 0.75)
	door_panel.position.y = -0.05
	door_root.add_child(door_panel)
	
	# Door handle
	var handle = MeshInstance3D.new()
	var handle_mesh = BoxMesh.new()
	handle_mesh.size = Vector3(0.15, 0.08, 0.1)
	handle.mesh = handle_mesh
	handle.material_override = create_material(Color(0.7, 0.65, 0.2), 0.9, 0.3)
	handle.position = Vector3(width * 0.35, 0, 0.12)
	door_panel.add_child(handle)
	
	return door_root

# =============================================================================
# ENEMY GENERATION
# =============================================================================

static func create_enemy_grunt() -> Node3D:
	"""Create humanoid grunt enemy - aggressive close-range fighter."""
	var enemy = Node3D.new()
	enemy.name = "EnemyGrunt"
	
	# Body (capsule)
	var body = MeshInstance3D.new()
	body.name = "Body"
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.4
	capsule.height = 1.4
	body.mesh = capsule
	body.material_override = create_material(Color(0.6, 0.3, 0.2))  # Reddish brown
	body.position.y = 0.9
	enemy.add_child(body)
	
	# Head (sphere)
	var head = MeshInstance3D.new()
	head.name = "Head"
	var sphere = SphereMesh.new()
	sphere.radius = 0.25
	head.mesh = sphere
	head.material_override = create_material(Color(0.7, 0.5, 0.4))  # Flesh tone
	head.position.y = 1.85
	enemy.add_child(head)
	
	# Eyes (small emissive spheres)
	for i in [-1, 1]:
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.05
		eye.mesh = eye_mesh
		eye.material_override = create_emissive_material(Color(1.0, 0.2, 0.2), 1.5)
		eye.position = Vector3(i * 0.1, 1.9, 0.2)
		enemy.add_child(eye)
	
	# Arms (cylinders)
	for i in [-1, 1]:
		var arm = MeshInstance3D.new()
		var arm_mesh = CylinderMesh.new()
		arm_mesh.height = 0.8
		arm_mesh.top_radius = 0.1
		arm_mesh.bottom_radius = 0.12
		arm.mesh = arm_mesh
		arm.material_override = create_material(Color(0.6, 0.3, 0.2))
		arm.position = Vector3(i * 0.55, 1.2, 0)
		arm.rotation_degrees.z = i * 15
		enemy.add_child(arm)
	
	# Legs (cylinders)
	for i in [-1, 1]:
		var leg = MeshInstance3D.new()
		var leg_mesh = CylinderMesh.new()
		leg_mesh.height = 0.8
		leg_mesh.top_radius = 0.15
		leg_mesh.bottom_radius = 0.12
		leg.mesh = leg_mesh
		leg.material_override = create_material(Color(0.4, 0.25, 0.2))
		leg.position = Vector3(i * 0.2, 0.4, 0)
		enemy.add_child(leg)
	
	# Collision shape
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.8
	collision.shape = shape
	collision.position.y = 0.9
	enemy.add_child(collision)
	
	return enemy

static func create_enemy_sniper() -> Node3D:
	"""Create tall, thin sniper enemy - ranged attacker."""
	var enemy = Node3D.new()
	enemy.name = "EnemySniper"
	
	# Tall thin body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	body.mesh = capsule
	body.material_override = create_material(Color(0.2, 0.25, 0.4))  # Dark blue
	body.position.y = 1.1
	enemy.add_child(body)
	
	# Hooded head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var box = BoxMesh.new()
	box.size = Vector3(0.35, 0.4, 0.35)
	head.mesh = box
	head.material_override = create_material(Color(0.15, 0.15, 0.2))
	head.position.y = 2.2
	enemy.add_child(head)
	
	# Single glowing eye visor
	var visor = MeshInstance3D.new()
	var visor_mesh = BoxMesh.new()
	visor_mesh.size = Vector3(0.3, 0.08, 0.05)
	visor.mesh = visor_mesh
	visor.material_override = create_emissive_material(Color(0.2, 0.8, 1.0), 2.0)
	visor.position = Vector3(0, 2.2, 0.18)
	enemy.add_child(visor)
	
	# Sniper rifle (long box)
	var rifle = MeshInstance3D.new()
	var rifle_mesh = BoxMesh.new()
	rifle_mesh.size = Vector3(0.08, 0.1, 1.2)
	rifle.mesh = rifle_mesh
	rifle.material_override = create_material(Color(0.3, 0.3, 0.3), 0.6, 0.4)
	rifle.position = Vector3(0.4, 1.3, 0.4)
	enemy.add_child(rifle)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 2.2
	collision.shape = shape
	collision.position.y = 1.1
	enemy.add_child(collision)
	
	return enemy

static func create_enemy_brute() -> Node3D:
	"""Create large, heavy brute enemy - tank class."""
	var enemy = Node3D.new()
	enemy.name = "EnemyBrute"
	
	# Large blocky body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var box = BoxMesh.new()
	box.size = Vector3(1.2, 1.6, 0.8)
	body.mesh = box
	body.material_override = create_material(Color(0.5, 0.35, 0.25))  # Brown
	body.position.y = 1.0
	enemy.add_child(body)
	
	# Small head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	head.mesh = sphere
	head.material_override = create_material(Color(0.55, 0.4, 0.3))
	head.position.y = 2.0
	enemy.add_child(head)
	
	# Angry eyes
	for i in [-1, 1]:
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.08
		eye.mesh = eye_mesh
		eye.material_override = create_emissive_material(Color(1.0, 0.5, 0.0), 2.0)
		eye.position = Vector3(i * 0.12, 2.05, 0.22)
		enemy.add_child(eye)
	
	# Massive arms
	for i in [-1, 1]:
		var arm = MeshInstance3D.new()
		var arm_mesh = BoxMesh.new()
		arm_mesh.size = Vector3(0.4, 1.0, 0.35)
		arm.mesh = arm_mesh
		arm.material_override = create_material(Color(0.5, 0.35, 0.25))
		arm.position = Vector3(i * 0.8, 1.0, 0)
		enemy.add_child(arm)
		
		# Fists
		var fist = MeshInstance3D.new()
		var fist_mesh = SphereMesh.new()
		fist_mesh.radius = 0.25
		fist.mesh = fist_mesh
		fist.material_override = create_material(Color(0.55, 0.4, 0.3))
		fist.position = Vector3(i * 0.8, 0.4, 0)
		enemy.add_child(fist)
	
	# Thick legs
	for i in [-1, 1]:
		var leg = MeshInstance3D.new()
		var leg_mesh = BoxMesh.new()
		leg_mesh.size = Vector3(0.35, 0.6, 0.35)
		leg.mesh = leg_mesh
		leg.material_override = create_material(Color(0.4, 0.3, 0.2))
		leg.position = Vector3(i * 0.35, 0.3, 0)
		enemy.add_child(leg)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(1.4, 2.2, 1.0)
	collision.shape = shape
	collision.position.y = 1.1
	enemy.add_child(collision)
	
	return enemy

static func create_enemy_swarm() -> Node3D:
	"""Create small, fast swarmling enemy."""
	var enemy = Node3D.new()
	enemy.name = "EnemySwarm"
	
	# Small round body
	var body = MeshInstance3D.new()
	body.name = "Body"
	var sphere = SphereMesh.new()
	sphere.radius = 0.3
	body.mesh = sphere
	body.material_override = create_material(Color(0.3, 0.5, 0.2))  # Sickly green
	body.position.y = 0.35
	enemy.add_child(body)
	
	# Multiple eyes
	for i in range(3):
		var eye = MeshInstance3D.new()
		var eye_mesh = SphereMesh.new()
		eye_mesh.radius = 0.06
		eye.mesh = eye_mesh
		eye.material_override = create_emissive_material(Color(0.8, 1.0, 0.2), 1.5)
		var angle = (i - 1) * 0.4
		eye.position = Vector3(sin(angle) * 0.25, 0.45, cos(angle) * 0.25)
		enemy.add_child(eye)
	
	# Spiky legs
	for i in range(6):
		var leg = MeshInstance3D.new()
		var leg_mesh = CylinderMesh.new()
		leg_mesh.height = 0.3
		leg_mesh.top_radius = 0.02
		leg_mesh.bottom_radius = 0.04
		leg.mesh = leg_mesh
		leg.material_override = create_material(Color(0.2, 0.3, 0.15))
		var angle = i * TAU / 6
		leg.position = Vector3(cos(angle) * 0.2, 0.1, sin(angle) * 0.2)
		leg.rotation_degrees = Vector3(30 * cos(angle), 0, -30 * sin(angle))
		enemy.add_child(leg)
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.35
	collision.shape = shape
	collision.position.y = 0.35
	enemy.add_child(collision)
	
	return enemy

static func create_enemy_by_type(enemy_type: String) -> Node3D:
	"""Factory method to create enemy by type string."""
	match enemy_type:
		"grunt":
			return create_enemy_grunt()
		"sniper":
			return create_enemy_sniper()
		"brute":
			return create_enemy_brute()
		"swarm":
			return create_enemy_swarm()
		_:
			# Default fallback - simple capsule
			return create_enemy_grunt()

# =============================================================================
# WEAPON GENERATION
# =============================================================================

static func create_weapon_pistol() -> Node3D:
	"""Create basic pistol viewmodel."""
	var weapon = Node3D.new()
	weapon.name = "WeaponPistol"
	
	# Main body
	var body = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.06, 0.15, 0.25)
	body.mesh = box
	body.material_override = create_material(Color(0.2, 0.2, 0.22), 0.7, 0.4)
	weapon.add_child(body)
	
	# Barrel
	var barrel = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.height = 0.15
	cyl.top_radius = 0.02
	cyl.bottom_radius = 0.025
	barrel.mesh = cyl
	barrel.rotation_degrees.x = 90
	barrel.position = Vector3(0, 0.03, 0.18)
	barrel.material_override = create_material(Color(0.15, 0.15, 0.15), 0.8, 0.3)
	weapon.add_child(barrel)
	
	# Grip
	var grip = MeshInstance3D.new()
	var grip_mesh = BoxMesh.new()
	grip_mesh.size = Vector3(0.05, 0.12, 0.06)
	grip.mesh = grip_mesh
	grip.position = Vector3(0, -0.1, -0.05)
	grip.rotation_degrees.x = -15
	grip.material_override = create_material(Color(0.3, 0.25, 0.2))
	weapon.add_child(grip)
	
	return weapon

static func create_weapon_shotgun() -> Node3D:
	"""Create shotgun viewmodel."""
	var weapon = Node3D.new()
	weapon.name = "WeaponShotgun"
	
	# Receiver
	var receiver = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.08, 0.1, 0.25)
	receiver.mesh = box
	receiver.material_override = create_material(Color(0.25, 0.25, 0.27), 0.6, 0.5)
	weapon.add_child(receiver)
	
	# Double barrel
	for i in [-1, 1]:
		var barrel = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.height = 0.5
		cyl.top_radius = 0.025
		cyl.bottom_radius = 0.03
		barrel.mesh = cyl
		barrel.rotation_degrees.x = 90
		barrel.position = Vector3(i * 0.025, 0.02, 0.35)
		barrel.material_override = create_material(Color(0.15, 0.15, 0.15), 0.8, 0.3)
		weapon.add_child(barrel)
	
	# Stock
	var stock = MeshInstance3D.new()
	var stock_mesh = BoxMesh.new()
	stock_mesh.size = Vector3(0.06, 0.08, 0.2)
	stock.mesh = stock_mesh
	stock.position = Vector3(0, -0.02, -0.2)
	stock.material_override = create_material(Color(0.4, 0.28, 0.15))
	weapon.add_child(stock)
	
	return weapon

static func create_weapon_by_type(weapon_type: String) -> Node3D:
	"""Factory method to create weapon by type string."""
	match weapon_type:
		"pistol":
			return create_weapon_pistol()
		"shotgun":
			return create_weapon_shotgun()
		_:
			return create_weapon_pistol()

# =============================================================================
# ITEM GENERATION
# =============================================================================

static func create_item_health_small() -> Node3D:
	"""Create small health pickup - medkit style."""
	var item = Node3D.new()
	item.name = "HealthSmall"
	
	# Box base
	var base = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.3, 0.2, 0.3)
	base.mesh = box
	base.material_override = create_material(Color(0.9, 0.9, 0.9))
	item.add_child(base)
	
	# Red cross (horizontal)
	var cross_h = MeshInstance3D.new()
	var cross_h_mesh = BoxMesh.new()
	cross_h_mesh.size = Vector3(0.2, 0.03, 0.06)
	cross_h.mesh = cross_h_mesh
	cross_h.position.y = 0.11
	cross_h.material_override = create_material(Color(0.9, 0.1, 0.1))
	item.add_child(cross_h)
	
	# Red cross (vertical)
	var cross_v = MeshInstance3D.new()
	var cross_v_mesh = BoxMesh.new()
	cross_v_mesh.size = Vector3(0.06, 0.03, 0.2)
	cross_v.mesh = cross_v_mesh
	cross_v.position.y = 0.11
	cross_v.material_override = create_material(Color(0.9, 0.1, 0.1))
	item.add_child(cross_v)
	
	return item

static func create_item_armor_shard() -> Node3D:
	"""Create armor shard pickup."""
	var item = Node3D.new()
	item.name = "ArmorShard"
	
	# Diamond/crystal shape using box
	var shard = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.2, 0.3, 0.2)
	shard.mesh = box
	shard.rotation_degrees = Vector3(45, 45, 0)
	shard.material_override = create_emissive_material(Color(0.2, 0.8, 0.3), 1.0)
	item.add_child(shard)
	
	return item

static func create_item_ammo(ammo_type: String) -> Node3D:
	"""Create ammo pickup based on type."""
	var item = Node3D.new()
	item.name = "Ammo_" + ammo_type
	
	var color: Color
	match ammo_type:
		"shells":
			color = Color(0.8, 0.2, 0.2)  # Red
		"rockets":
			color = Color(0.2, 0.6, 0.2)  # Green
		"cells":
			color = Color(0.2, 0.4, 0.9)  # Blue
		"bullets":
			color = Color(0.7, 0.6, 0.2)  # Yellow/brass
		_:
			color = Color(0.5, 0.5, 0.5)
	
	# Ammo box
	var box_node = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.25, 0.15, 0.15)
	box_node.mesh = box
	box_node.material_override = create_material(color)
	item.add_child(box_node)
	
	return item

static func create_item_by_type(item_type: String, item_id: String = "") -> Node3D:
	"""Factory method to create item by type."""
	match item_type:
		"health":
			return create_item_health_small()
		"armor":
			return create_item_armor_shard()
		"ammo_shells":
			return create_item_ammo("shells")
		"ammo_rockets":
			return create_item_ammo("rockets")
		"ammo_bullets":
			return create_item_ammo("bullets")
		_:
			return create_item_health_small()

# =============================================================================
# PROJECTILE GENERATION
# =============================================================================

static func create_projectile_rocket() -> Node3D:
	"""Create rocket projectile."""
	var proj = Node3D.new()
	proj.name = "RocketProjectile"
	
	# Rocket body
	var body = MeshInstance3D.new()
	var capsule = CapsuleMesh.new()
	capsule.radius = 0.08
	capsule.height = 0.4
	body.mesh = capsule
	body.rotation_degrees.x = 90
	body.material_override = create_material(Color(0.4, 0.45, 0.35), 0.5, 0.6)
	proj.add_child(body)
	
	# Exhaust glow
	var exhaust = MeshInstance3D.new()
	var exhaust_mesh = SphereMesh.new()
	exhaust_mesh.radius = 0.06
	exhaust.mesh = exhaust_mesh
	exhaust.position.z = -0.22
	exhaust.material_override = create_emissive_material(Color(1.0, 0.6, 0.2), 3.0)
	proj.add_child(exhaust)
	
	return proj

# =============================================================================
# ENVIRONMENT
# =============================================================================

static func create_procedural_sky(sky_type: String = "day") -> WorldEnvironment:
	"""Create procedural sky environment."""
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	
	match sky_type:
		"day":
			sky_material.sky_top_color = Color(0.3, 0.5, 0.9)
			sky_material.sky_horizon_color = Color(0.7, 0.8, 0.95)
			sky_material.ground_bottom_color = Color(0.3, 0.25, 0.2)
			sky_material.ground_horizon_color = Color(0.5, 0.45, 0.4)
		"hell":
			sky_material.sky_top_color = Color(0.2, 0.0, 0.0)
			sky_material.sky_horizon_color = Color(0.6, 0.2, 0.1)
			sky_material.ground_bottom_color = Color(0.1, 0.05, 0.0)
			sky_material.ground_horizon_color = Color(0.4, 0.15, 0.05)
	
	sky.sky_material = sky_material
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	
	# Ambient lighting
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	
	world_env.environment = env
	return world_env

# =============================================================================
# ASSET LOADER WITH FALLBACK
# =============================================================================

static func load_or_generate_model(path: String, fallback_type: String, 
		fallback_id: String = "") -> Node3D:
	"""
	Attempt to load a model from path. If it doesn't exist,
	generate a procedural placeholder.
	"""
	if path != "" and ResourceLoader.exists(path):
		var scene = load(path)
		if scene:
			return scene.instantiate()
	
	# Generate placeholder based on type
	match fallback_type:
		"enemy":
			return create_enemy_by_type(fallback_id)
		"weapon":
			return create_weapon_by_type(fallback_id)
		"item":
			return create_item_by_type(fallback_id, fallback_id)
		"projectile":
			return create_projectile_rocket()
		"door":
			return create_door()
		"floor":
			return create_floor_tile()
		"wall":
			return create_wall_segment()
		_:
			# Ultimate fallback - colored box
			var mesh_instance = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3.ONE
			mesh_instance.mesh = box
			mesh_instance.material_override = create_material(Color(1, 0, 1))  # Magenta = missing
			return mesh_instance

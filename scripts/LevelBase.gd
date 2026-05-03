extends Node3D

func _ready():
	_build_terrain()
	_build_anchors()
	_setup_environment()

func _build_terrain():
	# ── Left Cliff ────────────────────────────────────────────────
	var left_cliff = _create_cliff(Vector3(-13, -2, 0), Vector3(10, 12, 8),
		Color(0.35, 0.25, 0.15), Color(0.28, 0.20, 0.12))
	add_child(left_cliff)
	
	# Grass top on left cliff
	var left_grass = _create_box(Vector3(-13, 4.1, 0), Vector3(10, 0.3, 8),
		Color(0.25, 0.55, 0.15))
	add_child(left_grass)
	
	# ── Right Cliff ───────────────────────────────────────────────
	var right_cliff = _create_cliff(Vector3(13, -2, 0), Vector3(10, 12, 8),
		Color(0.35, 0.25, 0.15), Color(0.28, 0.20, 0.12))
	add_child(right_cliff)
	
	var right_grass = _create_box(Vector3(13, 4.1, 0), Vector3(10, 0.3, 8),
		Color(0.25, 0.55, 0.15))
	add_child(right_grass)
	
	# ── Water ─────────────────────────────────────────────────────
	var water = _create_water_plane(Vector3(0, -5, 0), Vector3(20, 0.1, 8))
	add_child(water)
	
	# ── Rock details on cliffs ────────────────────────────────────
	for i in 6:
		var rx = randf_range(-17, -10)
		var ry = randf_range(-3, 3)
		var rock = _create_rock(Vector3(rx, ry, randf_range(-3, 3)))
		add_child(rock)
		
		rx = randf_range(10, 17)
		rock = _create_rock(Vector3(rx, ry, randf_range(-3, 3)))
		add_child(rock)
	
	# ── Trees ─────────────────────────────────────────────────────
	for i in 5:
		var tree = _create_tree(Vector3(randf_range(-20, -10), 4.0, randf_range(-3, 3)))
		add_child(tree)
		tree = _create_tree(Vector3(randf_range(10, 20), 4.0, randf_range(-3, 3)))
		add_child(tree)
	
	# ── Background mountains ──────────────────────────────────────
	for i in 4:
		var mpos = Vector3(randf_range(-30, 30), randf_range(-2, 2), randf_range(-20, -12))
		var mscale = Vector3(randf_range(8, 16), randf_range(10, 20), randf_range(6, 10))
		var mountain = _create_mountain(mpos, mscale)
		add_child(mountain)
	
	# ── Static collision for cliffs ───────────────────────────────
	var left_body = StaticBody3D.new()
	var left_col = CollisionShape3D.new()
	var left_shape = BoxShape3D.new()
	left_shape.size = Vector3(10, 12, 8)
	left_col.shape = left_shape
	left_body.add_child(left_col)
	left_body.position = Vector3(-13, -2, 0)
	add_child(left_body)
	
	var right_body = StaticBody3D.new()
	var right_col = CollisionShape3D.new()
	var right_shape = BoxShape3D.new()
	right_shape.size = Vector3(10, 12, 8)
	right_col.shape = right_shape
	right_body.add_child(right_col)
	right_body.position = Vector3(13, -2, 0)
	add_child(right_body)

func _build_anchors():
	# Left anchor platform
	var anchor_a = _create_anchor_platform(Vector3(-8, 0, 0), "A")
	add_child(anchor_a)
	
	# Right anchor platform  
	var anchor_b = _create_anchor_platform(Vector3(8, 0, 0), "B")
	add_child(anchor_b)

func _setup_environment():
	var env = Environment.new()
	
	# Sky
	var sky = Sky.new()
	var sky_mat = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.2, 0.4, 0.8)
	sky_mat.sky_horizon_color = Color(0.6, 0.75, 0.9)
	sky_mat.ground_bottom_color = Color(0.1, 0.1, 0.1)
	sky_mat.ground_horizon_color = Color(0.4, 0.3, 0.2)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	
	# Ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	
	# Fog
	env.fog_enabled = true
	env.fog_density = 0.008
	env.fog_sky_affect = 0.3
	
	# SSAO for depth
	env.ssao_enabled = true
	env.ssao_radius = 1.0
	env.ssao_intensity = 1.5
	
	# Glow
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.1
	
	var we = get_node_or_null("../Environment") as WorldEnvironment
	if we:
		we.environment = env
	else:
		var we2 = WorldEnvironment.new()
		we2.environment = env
		add_child(we2)

# ─── MESH BUILDERS ────────────────────────────────────────────────
func _create_cliff(pos: Vector3, size: Vector3, col1: Color, col2: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col1
	mat.roughness = 0.95
	mat.metallic = 0.0
	# Vertex color variation for rocky look
	mat.vertex_color_use_as_albedo = false
	mi.material_override = mat
	
	return mi

func _create_box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mi.material_override = mat
	return mi

func _create_water_plane(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.4, 0.8, 0.75)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.3
	mat.roughness = 0.05
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.15, 0.4) * 0.3
	mi.material_override = mat
	return mi

func _create_rock(pos: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	var s = randf_range(0.3, 0.9)
	mesh.radius = s
	mesh.height = s * randf_range(0.6, 1.2)
	mesh.radial_segments = 6
	mesh.rings = 4
	mi.mesh = mesh
	mi.position = pos
	mi.scale = Vector3(1, randf_range(0.5, 1.0), randf_range(0.7, 1.3))
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(randf_range(0.3, 0.5), randf_range(0.25, 0.4), randf_range(0.2, 0.35))
	mat.roughness = 0.9
	mi.material_override = mat
	return mi

func _create_tree(pos: Vector3) -> Node3D:
	var tree = Node3D.new()
	tree.position = pos
	
	var h = randf_range(2.0, 4.0)
	
	# Trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.top_radius = 0.12
	trunk_mesh.bottom_radius = 0.18
	trunk_mesh.height = h * 0.4
	trunk.mesh = trunk_mesh
	trunk.position = Vector3(0, h * 0.2, 0)
	var trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.3, 0.18, 0.08)
	trunk_mat.roughness = 0.95
	trunk.material_override = trunk_mat
	tree.add_child(trunk)
	
	# Foliage layers
	for layer in 3:
		var foliage = MeshInstance3D.new()
		var cone = CylinderMesh.new()
		var layer_r = (0.8 - layer * 0.15) * h * 0.25
		cone.top_radius = 0.0
		cone.bottom_radius = layer_r
		cone.height = h * 0.35
		foliage.mesh = cone
		foliage.position = Vector3(0, h * 0.4 + layer * h * 0.15, 0)
		var f_mat = StandardMaterial3D.new()
		f_mat.albedo_color = Color(
			randf_range(0.1, 0.2),
			randf_range(0.35, 0.5),
			randf_range(0.1, 0.2)
		)
		f_mat.roughness = 0.9
		foliage.material_override = f_mat
		tree.add_child(foliage)
	
	return tree

func _create_mountain(pos: Vector3, scale: Vector3) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 1.0
	mesh.height = 1.0
	mesh.radial_segments = 8
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scale
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(
		randf_range(0.35, 0.5),
		randf_range(0.4, 0.55),
		randf_range(0.3, 0.45)
	)
	mat.roughness = 0.85
	mi.material_override = mat
	return mi

func _create_anchor_platform(pos: Vector3, label: String) -> Node3D:
	var anchor = Node3D.new()
	anchor.position = pos
	
	# Platform base
	var base = MeshInstance3D.new()
	var base_mesh = BoxMesh.new()
	base_mesh.size = Vector3(1.5, 0.4, 1.5)
	base.mesh = base_mesh
	var base_mat = StandardMaterial3D.new()
	base_mat.albedo_color = Color(0.5, 0.45, 0.4)
	base_mat.roughness = 0.8
	base_mat.metallic = 0.2
	base.material_override = base_mat
	anchor.add_child(base)
	
	# Anchor sphere
	var sphere_mi = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	sphere_mi.mesh = sphere
	sphere_mi.position = Vector3(0, 0.55, 0)
	var sphere_mat = StandardMaterial3D.new()
	sphere_mat.albedo_color = Color(1.0, 0.8, 0.0)
	sphere_mat.metallic = 0.9
	sphere_mat.roughness = 0.1
	sphere_mat.emission_enabled = true
	sphere_mat.emission = Color(0.8, 0.5, 0.0) * 0.4
	sphere_mi.material_override = sphere_mat
	anchor.add_child(sphere_mi)
	
	return anchor

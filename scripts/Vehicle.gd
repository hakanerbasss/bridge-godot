extends Node3D

var speed: float = 2.5
var body_color: Color = Color(0.9, 0.35, 0.1)

func _ready():
	_build_car()

func _build_car():
	# ── Body ──────────────────────────────────────────────────────
	var body = _get_or_create_mesh("Body")
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(1.8, 0.5, 0.9)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.25, 0)
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = body_color
	body_mat.metallic = 0.6
	body_mat.roughness = 0.3
	body.material_override = body_mat
	
	# ── Cabin ─────────────────────────────────────────────────────
	var cabin = _get_or_create_mesh("Cabin")
	var cabin_mesh = BoxMesh.new()
	cabin_mesh.size = Vector3(1.0, 0.45, 0.8)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(-0.15, 0.72, 0)
	var cabin_mat = StandardMaterial3D.new()
	cabin_mat.albedo_color = body_color * 0.85
	cabin_mat.metallic = 0.5
	cabin_mat.roughness = 0.3
	cabin.material_override = cabin_mat
	
	# Windows
	var win_f = MeshInstance3D.new()
	var win_mesh = BoxMesh.new()
	win_mesh.size = Vector3(0.05, 0.35, 0.7)
	win_f.mesh = win_mesh
	win_f.position = Vector3(0.38, 0.72, 0)
	var win_mat = StandardMaterial3D.new()
	win_mat.albedo_color = Color(0.5, 0.75, 1.0, 0.6)
	win_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	win_mat.metallic = 0.1
	win_mat.roughness = 0.05
	win_f.material_override = win_mat
	add_child(win_f)
	
	# ── Wheels ────────────────────────────────────────────────────
	var wheel_positions = [
		Vector3(-0.7, 0, 0.52),
		Vector3(-0.7, 0, -0.52),
		Vector3(0.65, 0, 0.52),
		Vector3(0.65, 0, -0.52),
	]
	var wheel_names = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	
	for i in 4:
		var wheel = _get_or_create_mesh(wheel_names[i])
		var wheel_mesh = CylinderMesh.new()
		wheel_mesh.top_radius = 0.28
		wheel_mesh.bottom_radius = 0.28
		wheel_mesh.height = 0.22
		wheel_mesh.radial_segments = 14
		wheel.mesh = wheel_mesh
		wheel.position = wheel_positions[i]
		wheel.rotation_degrees = Vector3(0, 0, 90)
		
		var w_mat = StandardMaterial3D.new()
		w_mat.albedo_color = Color(0.12, 0.12, 0.12)
		w_mat.roughness = 0.95
		wheel.material_override = w_mat
		
		# Hub cap
		var hub = MeshInstance3D.new()
		var hub_mesh = CylinderMesh.new()
		hub_mesh.top_radius = 0.14
		hub_mesh.bottom_radius = 0.14
		hub_mesh.height = 0.24
		hub_mesh.radial_segments = 8
		hub.mesh = hub_mesh
		hub.position = wheel_positions[i]
		hub.rotation_degrees = Vector3(0, 0, 90)
		var hub_mat = StandardMaterial3D.new()
		hub_mat.albedo_color = Color(0.7, 0.7, 0.75)
		hub_mat.metallic = 0.9
		hub_mat.roughness = 0.1
		hub.material_override = hub_mat
		add_child(hub)
	
	# ── Headlights ────────────────────────────────────────────────
	for side in [-0.3, 0.3]:
		var light_mesh_inst = MeshInstance3D.new()
		var light_mesh = SphereMesh.new()
		light_mesh.radius = 0.1
		light_mesh.height = 0.2
		light_mesh_inst.mesh = light_mesh
		light_mesh_inst.position = Vector3(0.91, 0.22, side)
		var light_mat = StandardMaterial3D.new()
		light_mat.albedo_color = Color(1, 1, 0.8)
		light_mat.emission_enabled = true
		light_mat.emission = Color(1, 0.9, 0.5) * 1.5
		light_mesh_inst.material_override = light_mat
		add_child(light_mesh_inst)

func _get_or_create_mesh(node_name: String) -> MeshInstance3D:
	var existing = get_node_or_null(node_name)
	if existing and existing is MeshInstance3D:
		return existing
	var mi = MeshInstance3D.new()
	mi.name = node_name
	add_child(mi)
	return mi

func _process(delta: float):
	# Wheel rotation animation
	var wheel_names = ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	for wname in wheel_names:
		var w = get_node_or_null(wname)
		if w:
			w.rotation_degrees.y += speed * delta * 80

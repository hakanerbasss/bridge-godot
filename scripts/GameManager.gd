extends Node3D

# Game states
enum State { MENU, BUILD, TEST, WIN, FAIL }
var state: State = State.BUILD

# Bridge data
var nodes: Array[Vector3] = []
var edges: Array[Dictionary] = []  # {a: int, b: int, mat: String, mesh: MeshInstance3D, body: StaticBody3D}
var selected_node: int = -1
var selected_material: String = "wood"

# Budget
var budget_max: int = 1000
var budget_used: int = 0

# Level config
var anchor_a: Vector3 = Vector3(-8, 0, 0)
var anchor_b: Vector3 = Vector3(8, 0, 0)

# Materials config
const MATERIALS = {
	"wood":  {"cost": 50,  "strength": 200, "color": Color(0.6, 0.35, 0.1),  "radius": 0.15, "locked": false},
	"iron":  {"cost": 100, "strength": 500, "color": Color(0.55, 0.6, 0.7),  "radius": 0.18, "locked": true},
	"steel": {"cost": 180, "strength": 900, "color": Color(0.85, 0.7, 0.1),  "radius": 0.20, "locked": true},
	"rope":  {"cost": 30,  "strength": 120, "color": Color(0.55, 0.35, 0.15),"radius": 0.08, "locked": true},
	"cable": {"cost": 80,  "strength": 400, "color": Color(0.6, 0.65, 0.75), "radius": 0.10, "locked": true},
}

# Node spheres visual
var node_meshes: Array[MeshInstance3D] = []

# Vehicle
var vehicle_scene = preload("res://scenes/Vehicle.tscn")
var vehicle_instance = null

# Stress tracking
var edge_stresses: Array[float] = []
var sim_timer: float = 0.0

# Camera
var camera: Camera3D
var touch_start: Vector2
var is_dragging: bool = false

func _ready():
	# Setup camera
	camera = $Camera3D if has_node("Camera3D") else _create_camera()
	
	# Add anchor nodes
	nodes.append(anchor_a)
	nodes.append(anchor_b)
	_spawn_node_mesh(0, true)
	_spawn_node_mesh(1, true)
	
	# Setup UI connections
	_connect_ui()
	
	# Load level 1
	_load_level(1)
	
	print("Bridge Builder 3D ready!")

func _create_camera() -> Camera3D:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 8, 20)
	cam.rotation_degrees = Vector3(-20, 0, 0)
	cam.fov = 60
	add_child(cam)
	return cam

func _connect_ui():
	if has_node("UI/HUD/BottomBar/BuildBtn"):
		$"UI/HUD/BottomBar/BuildBtn".pressed.connect(_on_build_pressed)
	if has_node("UI/HUD/BottomBar/TestBtn"):
		$"UI/HUD/BottomBar/TestBtn".pressed.connect(_on_test_pressed)
	if has_node("UI/HUD/BottomBar/ClearBtn"):
		$"UI/HUD/BottomBar/ClearBtn".pressed.connect(_on_clear_pressed)

func _load_level(lvl: int):
	match lvl:
		1:
			budget_max = 1000
			anchor_a = Vector3(-8, 0, 0)
			anchor_b = Vector3(8, 0, 0)
		2:
			budget_max = 1500
			anchor_a = Vector3(-10, 0, 0)
			anchor_b = Vector3(10, 2, 0)
		3:
			budget_max = 2000
			anchor_a = Vector3(-12, 2, 0)
			anchor_b = Vector3(12, -1, 0)
	
	_update_budget_ui()

func _update_budget_ui():
	if has_node("UI/HUD/TopBar/BudgetLabel"):
		var pct = float(budget_used) / float(budget_max)
		var col = "green" if pct < 0.6 else ("yellow" if pct < 0.85 else "red")
		$"UI/HUD/TopBar/BudgetLabel".text = "💰 %d / %d" % [budget_used, budget_max]

# ─── INPUT ────────────────────────────────────────────────────────
func _input(event):
	if state != State.BUILD:
		return
	
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_start(event.position)
		else:
			_on_touch_end(event.position)
	
	elif event is InputEventScreenDrag:
		_on_touch_drag(event.position)

func _on_touch_start(pos: Vector2):
	touch_start = pos
	is_dragging = false
	
	# Raycast to find clicked node or position
	var ray_result = _raycast_from_screen(pos)
	if ray_result:
		var closest = _find_closest_node(ray_result)
		if closest >= 0:
			selected_node = closest
			_highlight_node(closest, true)
		else:
			# New node at this position
			selected_node = nodes.size()
			nodes.append(ray_result)
			_spawn_node_mesh(selected_node, false)

func _on_touch_drag(pos: Vector2):
	is_dragging = true

func _on_touch_end(pos: Vector2):
	if selected_node < 0:
		return
	
	var ray_result = _raycast_from_screen(pos)
	if ray_result and is_dragging:
		var end_node = _find_closest_node(ray_result)
		if end_node < 0:
			# New node
			end_node = nodes.size()
			nodes.append(ray_result)
			_spawn_node_mesh(end_node, false)
		
		if end_node != selected_node:
			_add_edge(selected_node, end_node)
	
	if selected_node >= 0:
		_highlight_node(selected_node, false)
	selected_node = -1
	is_dragging = false

# ─── RAYCAST ──────────────────────────────────────────────────────
func _raycast_from_screen(screen_pos: Vector2) -> Variant:
	var from = camera.project_ray_origin(screen_pos)
	var dir = camera.project_ray_normal(screen_pos)
	
	# Intersect with Y=0 plane (bridge plane)
	var plane = Plane(Vector3.UP, 0)
	var hit = plane.intersects_ray(from, dir)
	return hit

func _find_closest_node(world_pos: Vector3, radius: float = 1.5) -> int:
	var best = -1
	var best_dist = radius
	for i in nodes.size():
		var d = nodes[i].distance_to(world_pos)
		if d < best_dist:
			best_dist = d
			best = i
	return best

# ─── NODE VISUALS ─────────────────────────────────────────────────
func _spawn_node_mesh(idx: int, is_anchor: bool):
	var mesh_inst = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.3 if is_anchor else 0.2
	sphere.height = sphere.radius * 2
	mesh_inst.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0) if is_anchor else Color(1, 1, 1)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.3
	mat.metallic = 0.8
	mat.roughness = 0.2
	mesh_inst.material_override = mat
	
	mesh_inst.position = nodes[idx]
	add_child(mesh_inst)
	node_meshes.append(mesh_inst)

func _highlight_node(idx: int, highlight: bool):
	if idx < node_meshes.size():
		var mat = node_meshes[idx].material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0, 1, 1) if highlight else Color(1, 1, 1)

# ─── EDGE / BEAM ──────────────────────────────────────────────────
func _add_edge(a: int, b: int):
	# Check duplicate
	for e in edges:
		if (e.a == a and e.b == b) or (e.a == b and e.b == a):
			return
	
	var mat_data = MATERIALS[selected_material]
	var len = nodes[a].distance_to(nodes[b])
	var cost = int(len * mat_data.cost * 0.3)
	
	if budget_used + cost > budget_max:
		print("Not enough budget!")
		_flash_budget_red()
		return
	
	budget_used += cost
	_update_budget_ui()
	
	# Create beam mesh
	var beam = _create_beam_mesh(nodes[a], nodes[b], mat_data)
	
	var edge = {
		"a": a, "b": b,
		"mat": selected_material,
		"rest_len": len,
		"stress": 0.0,
		"cost": cost,
		"mesh": beam,
	}
	edges.append(edge)
	edge_stresses.append(0.0)

func _create_beam_mesh(p1: Vector3, p2: Vector3, mat_data: Dictionary) -> MeshInstance3D:
	var mesh_inst = MeshInstance3D.new()
	
	var mid = (p1 + p2) * 0.5
	var dir = (p2 - p1).normalized()
	var length = p1.distance_to(p2)
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = mat_data.radius
	cylinder.bottom_radius = mat_data.radius
	cylinder.height = length
	cylinder.radial_segments = 10
	mesh_inst.mesh = cylinder
	
	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = mat_data.color
	mat.metallic = 0.4
	mat.roughness = 0.5
	
	# Add texture detail based on material
	match selected_material:
		"wood":
			mat.roughness = 0.9
			mat.metallic = 0.0
		"steel":
			mat.metallic = 0.9
			mat.roughness = 0.1
			mat.emission_enabled = true
			mat.emission = Color(0.3, 0.25, 0) * 0.5
		"rope":
			mat.roughness = 1.0
			mat.metallic = 0.0
	
	mesh_inst.material_override = mat
	
	# Position & rotation
	mesh_inst.position = mid
	mesh_inst.look_at_from_position(mid, p2, Vector3.UP)
	mesh_inst.rotate_object_local(Vector3.RIGHT, PI/2)
	
	add_child(mesh_inst)
	return mesh_inst

func _flash_budget_red():
	if has_node("UI/HUD/TopBar/BudgetLabel"):
		var lbl = $"UI/HUD/TopBar/BudgetLabel"
		lbl.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.5).timeout
		lbl.remove_theme_color_override("font_color")

# ─── BUILD / TEST MODES ───────────────────────────────────────────
func _on_build_pressed():
	if state == State.TEST:
		_stop_test()
	state = State.BUILD

func _on_test_pressed():
	if edges.is_empty():
		return
	_start_test()

func _on_clear_pressed():
	_stop_test()
	_clear_bridge()

func _clear_bridge():
	# Remove edge meshes
	for e in edges:
		if e.mesh:
			e.mesh.queue_free()
	edges.clear()
	edge_stresses.clear()
	
	# Remove non-anchor nodes
	for i in range(node_meshes.size() - 1, 1, -1):
		node_meshes[i].queue_free()
		node_meshes.remove_at(i)
	nodes.resize(2)
	
	budget_used = 0
	_update_budget_ui()

# ─── SIMULATION ───────────────────────────────────────────────────
var sim_nodes: Array[Dictionary] = []  # {pos, vel, fixed}
var sim_edges: Array[Dictionary] = []
const GRAVITY = Vector3(0, -9.8, 0)
const DAMPING = 0.98
const ITERS = 8

func _start_test():
	state = State.TEST
	sim_timer = 0.0
	
	# Copy nodes to sim
	sim_nodes.clear()
	for i in nodes.size():
		sim_nodes.append({
			"pos": nodes[i],
			"vel": Vector3.ZERO,
			"fixed": (i == 0 or i == 1)
		})
	
	# Copy edges to sim
	sim_edges.clear()
	for i in edges.size():
		var e = edges[i]
		sim_edges.append({
			"a": e.a, "b": e.b,
			"mat": e.mat,
			"rest_len": e.rest_len,
			"stress": 0.0,
			"broken": false,
		})
	
	# Spawn vehicle
	if vehicle_scene:
		vehicle_instance = vehicle_scene.instantiate()
		add_child(vehicle_instance)
		vehicle_instance.position = anchor_a + Vector3(0, 0.5, 0)

func _stop_test():
	state = State.BUILD
	if vehicle_instance:
		vehicle_instance.queue_free()
		vehicle_instance = null
	
	# Restore original edge meshes
	for i in edges.size():
		if i < edge_stresses.size():
			_update_edge_stress_color(i, 0.0)

func _physics_process(delta: float):
	if state != State.TEST:
		return
	
	sim_timer += delta
	
	# Verlet integration
	for sn in sim_nodes:
		if sn.fixed:
			continue
		sn.vel += GRAVITY * delta
		sn.pos += sn.vel * delta * DAMPING
		sn.vel *= DAMPING
	
	# Constraint solving
	for _iter in ITERS:
		for i in sim_edges.size():
			var se = sim_edges[i]
			if se.broken:
				continue
			var n1 = sim_nodes[se.a]
			var n2 = sim_nodes[se.b]
			var diff = n2.pos - n1.pos
			var cur_len = diff.length()
			if cur_len < 0.001:
				continue
			var stretch = (cur_len - se.rest_len) / cur_len
			se.stress = abs(stretch)
			sim_edges[i].stress = se.stress
			
			var mat_data = MATERIALS[se.mat]
			# Tension only for rope/cable
			if se.mat in ["rope", "cable"] and stretch < 0:
				continue
			
			var correction = diff * stretch * 0.5 * 0.7
			if not n1.fixed:
				n1.pos += correction
			if not n2.fixed:
				n2.pos -= correction
			
			# Break if overstressed
			if se.stress > mat_data.strength / 5000.0:
				sim_edges[i].broken = true
				_on_edge_break(i)
	
	# Update visual positions & stress colors
	for i in min(edges.size(), sim_edges.size()):
		var se = sim_edges[i]
		var e = edges[i]
		if se.broken or not e.mesh:
			continue
		
		var p1 = sim_nodes[se.a].pos
		var p2 = sim_nodes[se.b].pos
		var mid = (p1 + p2) * 0.5
		var length = p1.distance_to(p2)
		
		e.mesh.position = mid
		if length > 0.01:
			e.mesh.look_at_from_position(mid, p2, Vector3.UP)
			e.mesh.rotate_object_local(Vector3.RIGHT, PI/2)
			# Scale length
			var mat_data = MATERIALS[e.mat]
			var cyl = e.mesh.mesh as CylinderMesh
			if cyl:
				cyl.height = length
		
		_update_edge_stress_color(i, se.stress)
	
	# Vehicle logic
	if vehicle_instance:
		var vpos = vehicle_instance.position
		# Find support under vehicle
		var support_y = _find_support_y(vpos.x)
		if support_y != null:
			vehicle_instance.position.y = support_y + 0.4
			vehicle_instance.position.x += 3.0 * delta
		else:
			vehicle_instance.position.y -= 5.0 * delta
			if vehicle_instance.position.y < -10:
				_on_fail()
				return
		
		# Win check
		if vehicle_instance.position.x >= anchor_b.x - 0.5:
			_on_win()

func _find_support_y(vx: float) -> Variant:
	var best_y = null
	for i in sim_edges.size():
		var se = sim_edges[i]
		if se.broken:
			continue
		var p1 = sim_nodes[se.a].pos
		var p2 = sim_nodes[se.b].pos
		var min_x = min(p1.x, p2.x)
		var max_x = max(p1.x, p2.x)
		if vx >= min_x and vx <= max_x:
			var t = (vx - p1.x) / (p2.x - p1.x + 0.001)
			var y = p1.y + (p2.y - p1.y) * t
			if best_y == null or y > best_y:
				best_y = y
	return best_y

func _update_edge_stress_color(idx: int, stress: float):
	if idx >= edges.size():
		return
	var e = edges[idx]
	if not e.mesh:
		return
	var mat = e.mesh.material_override as StandardMaterial3D
	if not mat:
		return
	
	stress = clamp(stress, 0.0, 1.0)
	var col: Color
	if stress < 0.5:
		col = Color(0, 0.8, 0.5).lerp(Color(1, 0.85, 0), stress * 2.0)
	else:
		col = Color(1, 0.85, 0).lerp(Color(1, 0.1, 0.1), (stress - 0.5) * 2.0)
	
	mat.albedo_color = col
	mat.emission_enabled = stress > 0.7
	if stress > 0.7:
		mat.emission = col * 0.4

func _on_edge_break(idx: int):
	if idx >= edges.size():
		return
	var e = edges[idx]
	if e.mesh:
		# Flash red then hide
		var mat = e.mesh.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color.RED
		await get_tree().create_timer(0.15).timeout
		e.mesh.visible = false

func _on_win():
	state = State.WIN
	print("WIN!")
	_show_result(true)

func _on_fail():
	state = State.FAIL
	print("FAIL!")
	_show_result(false)

func _show_result(win: bool):
	# Simple result label
	var lbl = Label.new()
	lbl.text = "🎉 BRIDGE HELD!" if win else "💥 BRIDGE COLLAPSED!"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 48)
	lbl.add_theme_color_override("font_color", Color.YELLOW if win else Color.RED)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.size = Vector2(800, 200)
	lbl.position = Vector2(-400, -100)
	$UI.add_child(lbl)
	
	await get_tree().create_timer(3.0).timeout
	lbl.queue_free()
	_stop_test()

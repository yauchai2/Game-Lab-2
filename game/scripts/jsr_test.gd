extends Node3D
## JSR look test scene: greybox L-shaped street (about 24 x 40 m), three-band toon shader,
## character hull outline and screen-space scenery outline. Separate from main.tscn.
## Keys: WASD move camera target | C ortho/perspective | Tab showcase camera
##       O outlines on/off | R render resolution 640x360 / 960x540 / 1280x720
## Spec: docs/art/style-guide.md, section "JSR 目標規格". All numbers are test defaults.

const ART := preload("res://game/scripts/art-palette.gd")
const TOON := preload("res://game/shaders/jsr-toon.gdshader")
const HULL := preload("res://game/shaders/jsr-outline-hull.gdshader")
const SCREEN := preload("res://game/shaders/jsr-outline-screen.gdshader")
const JAX := preload("res://assets/characters/jax.glb")
const RESOLUTIONS: Array[Vector2i] = [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280, 720)]

var outlines := true
var use_ortho := true
var showcase := false
var resolution_index := 0
var cam_target := Vector3(12, 0, 2)
var game_cam: Camera3D
var show_cam: Camera3D
var edge_quad: MeshInstance3D
var hull_mat: ShaderMaterial
var mats := {}
var jax: Node3D

func _ready() -> void:
	_environment()
	_ground()
	_buildings()
	_props()
	_jax()
	_cameras()
	_outline_quad()
	_apply_resolution()
	_update_camera()

func _toon(color: Color) -> ShaderMaterial:
	var key := color
	if not mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = TOON
		m.set_shader_parameter("base_color", key)
		mats[key] = m
	return mats[key]

func _box(pos: Vector3, size: Vector3, color: Color, collide := false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = _toon(color)
	mesh.position = pos + Vector3(0, size.y * 0.5, 0)
	add_child(mesh)
	return mesh

func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = ART.SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.BLACK
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)

func _ground() -> void:
	# Road A along +X, road B along +Z, both 6 m wide; sidewalks 2 m.
	_box(Vector3(18, -0.2, 8), Vector3(48, 0.2, 40), ART.CONCRETE, false)
	_box(Vector3(20, 0.0, 0), Vector3(44, 0.02, 6), ART.ROAD)
	_box(Vector3(0, 0.0, 12), Vector3(6, 0.02, 24), ART.ROAD)
	for i in 8:
		_box(Vector3(6 + i * 5, 0.03, 0), Vector3(2.2, 0.01, 0.3), ART.PAPER)

func _building(pos: Vector3, size: Vector3, color: Color, awning: Color, face_z: float) -> void:
	_box(pos, size, color)
	# Storefront strip with shutter recess, coral/yellow awning, windows.
	var front := pos + Vector3(0, 0, face_z * (size.z * 0.5 + 0.05))
	_box(front, Vector3(size.x * 0.8, 2.6, 0.12), ART.TEAL)
	_box(front + Vector3(0, 2.0, face_z * 0.5), Vector3(size.x * 0.85, 0.2, 1.1), awning)
	_box(front + Vector3(-size.x * 0.2, 0, face_z * 0.08), Vector3(size.x * 0.28, 2.2, 0.06), ART.INK)
	for floor_i in range(1, int(size.y / 3.2)):
		for w in 3:
			_box(front + Vector3((w - 1) * size.x * 0.28, floor_i * 3.2 + 0.4, face_z * 0.02), Vector3(1.4, 1.4, 0.1), ART.INK)
	# Roof: AC unit and railing.
	_box(pos + Vector3(size.x * 0.25, size.y, 0), Vector3(1.6, 0.9, 1.2), ART.CONCRETE)

func _buildings() -> void:
	var c := [ART.PAPER, ART.CONCRETE, ART.MINT, ART.PAPER, ART.CONCRETE, ART.PAPER]
	var a := [ART.CORAL, ART.YELLOW, ART.CORAL, ART.YELLOW, ART.CORAL, ART.YELLOW]
	# North of road A (face +Z).
	_building(Vector3(8, 0, -8.5), Vector3(9, 9, 8), c[0], a[0], 1.0)
	_building(Vector3(18, 0, -8.5), Vector3(9, 12, 8), c[1], a[1], 1.0)
	_building(Vector3(28, 0, -8.5), Vector3(9, 7.5, 8), c[2], a[2], 1.0)
	# West of road B (face +X, built by rotating the same layout).
	for z in [9.0, 19.0]:
		var holder := Node3D.new()
		holder.position = Vector3(-8.5, 0, z)
		holder.rotation_degrees.y = 90
		add_child(holder)
		var before := get_child_count()
		_building(Vector3.ZERO, Vector3(9, 9, 8), c[3], a[3], 1.0)
		for i in range(before, get_child_count()):
			var n := get_child(before)
			remove_child(n)
			holder.add_child(n)
	# East of road B: one building with a tall water tower.
	_building(Vector3(8.5, 0, 14), Vector3(8, 10, 9), c[4], a[4], 1.0)
	_box(Vector3(8.5, 10, 14), Vector3(2.4, 0.3, 2.4), ART.INK)
	var tower := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.2
	cyl.height = 2.4
	cyl.radial_segments = 8
	tower.mesh = cyl
	tower.material_override = _toon(ART.CORAL)
	tower.position = Vector3(8.5, 11.5, 14)
	add_child(tower)
	# Elevated walkway across road A with two pillars.
	_box(Vector3(14, 5.0, 0), Vector3(3, 0.5, 8), ART.TEAL)
	_box(Vector3(14, 0, -3.6), Vector3(0.6, 5.0, 0.6), ART.TEAL)
	_box(Vector3(14, 0, 3.6), Vector3(0.6, 5.0, 0.6), ART.TEAL)
	_box(Vector3(12.6, 5.5, 0), Vector3(0.1, 1.0, 8), ART.INK)
	_box(Vector3(15.4, 5.5, 0), Vector3(0.1, 1.0, 8), ART.INK)

func _props() -> void:
	# Vending machine, AC, graffiti walls (flat coloured panels), railing, poles.
	_box(Vector3(5, 0, -4.2), Vector3(1.0, 1.9, 0.8), ART.CORAL)
	_box(Vector3(5, 1.0, -3.78), Vector3(0.7, 0.8, 0.06), ART.PAPER)
	_box(Vector3(22, 1.0, -4.1), Vector3(1.4, 0.8, 0.5), ART.CONCRETE)
	var graffiti := [ART.YELLOW, ART.MINT, ART.CORAL, ART.PAPER]
	_box(Vector3(18, 0.8, -4.45), Vector3(5, 2.6, 0.08), graffiti[0])
	_box(Vector3(17, 1.2, -4.5), Vector3(2.2, 1.6, 0.06), graffiti[2])
	_box(Vector3(-4.5, 0.8, 9), Vector3(0.08, 2.6, 4), graffiti[1])
	_box(Vector3(-4.55, 1.3, 9), Vector3(0.06, 1.2, 2), graffiti[3])
	for i in 6:
		_box(Vector3(24 + i * 1.2, 0, 3.6), Vector3(0.08, 1.0, 0.08), ART.INK)
	_box(Vector3(26.6, 0.95, 3.6), Vector3(7.2, 0.08, 0.08), ART.INK)
	for z in [4.0, 16.0]:
		_box(Vector3(3.6, 0, z), Vector3(0.25, 7.0, 0.25), ART.INK)
		_box(Vector3(3.6, 7.0, z), Vector3(1.6, 0.12, 0.12), ART.INK)

func _jax() -> void:
	jax = JAX.instantiate()
	jax.position = Vector3(12, 0, 2)
	jax.rotation_degrees.y = 225
	add_child(jax)
	hull_mat = ShaderMaterial.new()
	hull_mat.shader = HULL
	hull_mat.set_shader_parameter("width_px", 2.0)
	for mi in jax.find_children("*", "MeshInstance3D", true, false):
		var m: MeshInstance3D = mi
		for s in m.get_surface_override_material_count():
			var src := m.get_active_material(s)
			if src is StandardMaterial3D:
				var t := ShaderMaterial.new()
				t.shader = TOON
				t.set_shader_parameter("base_color", (src as StandardMaterial3D).albedo_color)
				t.next_pass = hull_mat
				m.set_surface_override_material(s, t)

func _cameras() -> void:
	game_cam = Camera3D.new()
	add_child(game_cam)
	show_cam = Camera3D.new()
	show_cam.fov = 85.0
	add_child(show_cam)

func _outline_quad() -> void:
	edge_quad = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	edge_quad.mesh = q
	edge_quad.extra_cull_margin = 16384.0
	var m := ShaderMaterial.new()
	m.shader = SCREEN
	m.render_priority = 100
	edge_quad.material_override = m
	game_cam.add_child(edge_quad)
	# Showcase camera needs its own copy.
	var q2 := edge_quad.duplicate()
	show_cam.add_child(q2)

func _update_camera() -> void:
	# Fixed 45 degree yaw and 45 degree pitch (Alan, 2026-11-01); no rotation input.
	var dir := Vector3(1, sqrt(2.0), 1).normalized()
	game_cam.projection = Camera3D.PROJECTION_ORTHOGONAL if use_ortho else Camera3D.PROJECTION_PERSPECTIVE
	game_cam.size = 24.0
	game_cam.fov = 30.0
	game_cam.near = 0.5
	game_cam.far = 120.0
	game_cam.position = cam_target + dir * 40.0
	game_cam.look_at(cam_target + Vector3(0, 1, 0))
	show_cam.position = cam_target + Vector3(5.5, 0.6, 7.0)
	show_cam.look_at(cam_target + Vector3(0, 1.4, 0))
	game_cam.current = not showcase
	show_cam.current = showcase
	for cam in [game_cam, show_cam]:
		for c in cam.get_children():
			c.visible = outlines
	hull_mat.set_shader_parameter("width_px", 2.0 if outlines else 0.0)

func _apply_resolution() -> void:
	var w := get_window()
	var r := RESOLUTIONS[resolution_index]
	w.content_scale_size = r
	w.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT

func _process(delta: float) -> void:
	var v := Vector3.ZERO
	if Input.is_key_pressed(KEY_W): v += Vector3(-1, 0, -1)
	if Input.is_key_pressed(KEY_S): v += Vector3(1, 0, 1)
	if Input.is_key_pressed(KEY_A): v += Vector3(-1, 0, 1)
	if Input.is_key_pressed(KEY_D): v += Vector3(1, 0, -1)
	if v != Vector3.ZERO:
		cam_target += v.normalized() * 8.0 * delta
		_update_camera()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_C: use_ortho = not use_ortho
		KEY_TAB: showcase = not showcase
		KEY_O: outlines = not outlines
		KEY_R:
			resolution_index = (resolution_index + 1) % RESOLUTIONS.size()
			_apply_resolution()
	_update_camera()

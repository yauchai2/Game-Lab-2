extends Node3D
## Builds the low-poly street arena from flat-colour boxes (palette from docs/art/style-guide.md).

const ART := preload("res://game/scripts/art-palette.gd")
const ASPHALT := ART.ROAD
const CHALK := ART.PAPER
const SIDEWALK := ART.CONCRETE
const INK := ART.INK
const BUILDING_COLORS: Array[Color] = [
	ART.PAPER, ART.CONCRETE, ART.MINT, ART.TEAL, ART.OLIVE,
]
const SHOP_COLORS: Array[Color] = [ART.CORAL, ART.YELLOW, ART.TEAL]
var materials: Dictionary = {}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 7
	_setup_environment()
	_build_ground()
	_build_buildings()
	_build_props()
	_build_street_details()

func _mat(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		materials[color] = ART.material(color)
	return materials[color]

func _box(pos: Vector3, size: Vector3, color: Color, collide := false) -> Node3D:
	var node: Node3D
	if collide:
		node = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		node.add_child(shape)
	else:
		node = Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	node.add_child(mi)
	node.position = pos
	add_child(node)
	return node

func _setup_environment() -> void:
	get_parent().get_node("Floor/Mesh").material_override = _mat(ASPHALT)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky_material := ShaderMaterial.new()
	sky_material.shader = preload("res://game/scripts/street-sky.gdshader")
	sky_material.set_shader_parameter("sky_color", Vector3(ART.SKY.r, ART.SKY.g, ART.SKY.b))
	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun: DirectionalLight3D = get_parent().get_node_or_null("Sun")
	if sun:
		sun.light_color = Color("FFF8E8")
		sun.light_energy = 0.65
		sun.shadow_enabled = true

func _build_ground() -> void:
	# Road with centre dashes, sidewalk strips and a crosswalk.
	_box(Vector3(0, 0.015, -17.5), Vector3(60, 0.03, 5), SIDEWALK)
	_box(Vector3(0, 0.015, 19.0), Vector3(60, 0.03, 4), SIDEWALK)
	for i in range(-5, 6):
		_box(Vector3(i * 4.0, 0.02, 0.0), Vector3(2.0, 0.03, 0.25), CHALK)
	for i in range(-3, 4):
		_box(Vector3(10.0, 0.02, i * 1.1), Vector3(3.0, 0.03, 0.55), CHALK)

func _facade(pos: Vector3, size: Vector3, color: Color, face_dir: Vector3) -> void:
	_box(pos, size, color, true)
	# windows on the visible face
	var cols := maxi(int(size.x / 2.2) if absf(face_dir.z) > 0.5 else int(size.z / 2.2), 1)
	var rows := maxi(int((size.y - 3.0) / 2.6), 1)
	for r in rows:
		for c in cols:
			var along := (c + 0.5) / cols - 0.5
			var y := 3.2 + r * 2.6
			var offset := face_dir * (size.z / 2.0 + 0.04) if absf(face_dir.z) > 0.5 else face_dir * (size.x / 2.0 + 0.04)
			var win_pos := pos - Vector3(0, size.y / 2.0, 0) + Vector3(0, y, 0) + offset
			var win_size := Vector3(1.2, 1.3, 0.08)
			if absf(face_dir.z) > 0.5:
				win_pos.x += along * size.x
			else:
				win_pos.z += along * size.z
				win_size = Vector3(0.08, 1.3, 1.2)
			_box(win_pos, win_size, INK)
	if face_dir.z > 0.5:
		_box(Vector3(pos.x, 1.2, pos.z + size.z / 2.0 + 0.06), Vector3(size.x * 0.72, 2.2, 0.1), INK)
		_box(Vector3(pos.x, 1.1, pos.z + size.z / 2.0 + 0.13), Vector3(size.x * 0.57, 1.6, 0.06), ART.TEAL)
		_sign(Vector3(pos.x, 3.0, pos.z + size.z / 2.0 + 0.15), "TURB / 07" if pos.x > 10 else "BO / SUPPLY", ART.PAPER, INK)
	# shop awning on the ground floor
	var awning_color: Color = SHOP_COLORS[rng.randi() % SHOP_COLORS.size()]
	if absf(face_dir.z) > 0.5:
		_box(pos - Vector3(0, size.y / 2.0 - 2.6, 0) + face_dir * (size.z / 2.0 + 0.5), Vector3(size.x * 0.8, 0.25, 1.2), awning_color)
	else:
		_box(pos - Vector3(0, size.y / 2.0 - 2.6, 0) + face_dir * (size.x / 2.0 + 0.5), Vector3(1.2, 0.25, size.z * 0.8), awning_color)

func _build_buildings() -> void:
	# back row (z-), seen from the camera
	var x := -30.0
	while x < 30.0:
		var w := rng.randf_range(6.0, 9.0)
		var h := rng.randf_range(8.0, 16.0)
		var color: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
		_facade(Vector3(x + w / 2.0, h / 2.0, -23.0), Vector3(w, h, 6.0), color, Vector3(0, 0, 1))
		x += w + 0.2
	# left and right rows
	for side in [-1, 1]:
		var z := -20.0
		while z < 21.0:
			var d := rng.randf_range(6.0, 9.0)
			var h := rng.randf_range(6.0, 12.0)
			var color: Color = BUILDING_COLORS[rng.randi() % BUILDING_COLORS.size()]
			_facade(Vector3(side * 24.0, h / 2.0, z + d / 2.0), Vector3(6.0, h, d), color, Vector3(-side, 0, 0))
			z += d + 0.2

func _build_props() -> void:
	# lamp posts
	for p in [Vector3(-12, 0, -15), Vector3(12, 0, -15), Vector3(-16, 0, 17), Vector3(16, 0, 17)]:
		_box(p + Vector3(0, 2.5, 0), Vector3(0.25, 5.0, 0.25), INK, true)
		_box(p + Vector3(0, 5.1, 0), Vector3(1.0, 0.3, 0.5), ART.YELLOW)
	# trees
	for p in [Vector3(-6, 0, -15.5), Vector3(5, 0, -15.5), Vector3(-19, 0, 6), Vector3(19, 0, -6)]:
		_box(p + Vector3(0, 1.0, 0), Vector3(0.4, 2.0, 0.4), Color("7A5A44"), true)
		var crown := _box(p + Vector3(0, 3.0, 0), Vector3(2.4, 2.2, 2.4), ART.TEAL)
		crown.rotation.y = 0.6
		var top := _box(p + Vector3(0, 4.4, 0), Vector3(1.6, 1.2, 1.6), ART.LEAF)
		top.rotation.y = 0.2
	# parked yellow car
	_box(Vector3(-11, 0.7, -11.5), Vector3(4.2, 1.1, 2.0), ART.YELLOW, true)
	_box(Vector3(-11.3, 1.55, -11.5), Vector3(2.2, 0.8, 1.8), INK)
	# vending machines and crates along the back sidewalk
	_box(Vector3(8, 1.0, -15.8), Vector3(1.0, 2.0, 0.8), ART.CORAL, true)
	_box(Vector3(9.4, 1.0, -15.8), Vector3(1.0, 2.0, 0.8), ART.TEAL, true)
	_box(Vector3(-3, 0.5, -15.5), Vector3(1.0, 1.0, 1.0), ART.MINT, true)
	_box(Vector3(-1.8, 0.4, -15.5), Vector3(0.8, 0.8, 0.8), ART.YELLOW, true)

func _sign(pos: Vector3, text: String, background: Color, foreground: Color) -> void:
	_box(pos, Vector3(4.8, 0.85, 0.12), background)
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.012
	label.modulate = foreground
	label.outline_size = 0
	label.no_depth_test = false
	label.position = pos + Vector3(0, 0, 0.08)
	add_child(label)

func _build_street_details() -> void:
	# Tile seams: decorative, leave all combat/click-to-move collision unchanged.
	for x in range(-28, 29, 2):
		_box(Vector3(x, 0.035, -17.5), Vector3(0.035, 0.012, 5), ART.PAPER)
	for x in range(-28, 29, 2):
		_box(Vector3(x, 0.035, 19), Vector3(0.035, 0.012, 4), ART.INK)
	for z in [17.05, 19.0, 20.95]:
		_box(Vector3(0, 0.035, z), Vector3(60, 0.012, 0.035), ART.INK)
	for z in [-19.0, -17.0, -15.1]:
		_box(Vector3(0, 0.035, z), Vector3(60, 0.012, 0.035), ART.PAPER)
	# Elevated freight line behind the arena, away from boss and enemy spawn points.
	_box(Vector3(0, 7.5, -20.3), Vector3(60, 0.9, 2.3), ART.CONCRETE)
	_box(Vector3(0, 8.02, -19.16), Vector3(60, 0.18, 0.12), ART.TEAL)
	for x in [-20, -12, 12, 20]:
		_box(Vector3(x, 3.55, -20.3), Vector3(0.8, 7.1, 1.0), ART.CONCRETE)
		_box(Vector3(x, 0.6, -20.3), Vector3(0.88, 0.7, 1.08), ART.YELLOW)
	# Foreground street stall: broad stripes, no emissive sci-fi panels.
	_box(Vector3(-18, 2.5, 16), Vector3(5, 0.22, 2.0), ART.CORAL)
	for x in [-20.2, -15.8]:
		_box(Vector3(x, 1.2, 16), Vector3(0.12, 2.4, 0.12), ART.INK)
	_box(Vector3(-18, 0.8, 16), Vector3(4.5, 1.3, 1.0), ART.PAPER)
	for i in 5:
		_box(Vector3(-20 + i, 2.63, 16), Vector3(0.45, 0.03, 2.0), ART.PAPER)
	# Front panels make the existing vending-machine silhouettes readable.
	for x in [8.0, 9.4]:
		_box(Vector3(x, 1.15, -15.36), Vector3(0.76, 1.25, 0.06), ART.PAPER)
		for row in 3:
			for col in 3:
				_box(Vector3(x - 0.23 + col * 0.23, 0.85 + row * 0.3, -15.3), Vector3(0.12, 0.18, 0.05), ART.YELLOW if col == 1 else ART.TEAL)
		_box(Vector3(x, 0.35, -15.3), Vector3(0.65, 0.15, 0.06), ART.INK)
	# A small, original painted wall graphic (not copied reference logos).
	_sign(Vector3(-12, 4.2, -19.85), "SIDE / ROUTE", ART.CORAL, ART.PAPER)

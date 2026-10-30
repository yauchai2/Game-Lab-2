extends Node3D
## 第一章關卡共用工具：方塊、標示、人物、互動點。配色沿用 docs/art/style-guide.md。

const CHAPTER := preload("res://game/scripts/chapter.gd")
const INTERACTABLE := preload("res://game/scripts/interactable.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")

const NAVY := Color("292D3B")
const CHALK := Color("E7DFC9")
const CORAL := Color("CC6657")
const MINT := Color("75C7B0")
const MAUVE := Color("9B8ACC")
const YELLOW := Color("D6D573")
const SLATE := Color("859AC1")
const MOSS := Color("8C9871")
const WOOD := Color("A9825F")

var main: Node3D
var jax: CharacterBody3D
var story: Node
var hud_ui: CanvasLayer

func _setup_refs() -> void:
	# 結構固定：Main / Street（level_loader）/ 本關卡節點
	main = get_parent().get_parent()
	jax = main.get_node("Jax")
	story = main.get_node("Story")

func _story_hud() -> CanvasLayer:
	return story.hud

func _mat(color: Color, unshaded := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func box(pos: Vector3, size: Vector3, color: Color, collide := false, parent: Node = null) -> Node3D:
	var node: Node3D
	if collide:
		node = StaticBody3D.new()
		var shape := CollisionShape3D.new()
		shape.name = "Collision"
		var bs := BoxShape3D.new()
		bs.size = size
		shape.shape = bs
		node.add_child(shape)
	else:
		node = Node3D.new()
	var mi := MeshInstance3D.new()
	mi.name = "Mesh"
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	node.add_child(mi)
	node.position = pos
	(parent if parent != null else self).add_child(node)
	return node

func sign3d(text: String, pos: Vector3, size := 40, color := Color("E7DFC9")) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 8
	l.outline_modulate = NAVY
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	add_child(l)
	return l

## 低多邊形人物：身體加頭。回傳根節點，名牌是 Label3D。
func person(pos: Vector3, body_color: Color, label := "", height := 1.5) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	box(Vector3(0, height * 0.35, 0), Vector3(0.7, height * 0.7, 0.45), body_color, false, root)
	box(Vector3(0, height * 0.82, 0), Vector3(0.45, 0.45, 0.45), Color("E7C9A8"), false, root)
	if label != "":
		var l := Label3D.new()
		l.name = "Label"
		l.text = label
		l.position = Vector3(0, height + 0.5, 0)
		l.font_size = 28
		l.pixel_size = 0.01
		l.outline_size = 8
		l.outline_modulate = NAVY
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		root.add_child(l)
	return root

func interact(pos: Vector3, prompt: String, action: Callable, radius := 2.0, once := true) -> Node3D:
	var it := Node3D.new()
	it.set_script(INTERACTABLE)
	it.prompt = prompt
	it.radius = radius
	it.once = once
	it.action = action
	it.position = pos
	add_child(it)
	return it

func say(speaker: String, text: String, seconds := 2.8) -> void:
	story.hud.say(speaker, text, seconds)

func objective(text: String) -> void:
	story.hud.set_objective(text)

func shake(amount := 0.3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(amount)

func spawn_enemy(pos: Vector3, ranged: bool, group: String, color: Color, hp := 40, awake_now := true) -> Node3D:
	var e := ENEMY_SCENE.instantiate()
	e.awake = awake_now
	e.camp = group
	e.max_hp = hp
	e.ranged = ranged
	e.base_color = color
	add_child(e)
	e.global_position = pos
	return e

func give_and_equip(type: String, rarity := 0) -> void:
	var item: Dictionary = jax.make_item(type, rarity)
	if jax.add_item(item):
		jax.toggle_equip(item["uid"])

func save_and_go(level_name: String) -> void:
	jax.save_progress(false)
	CHAPTER.level = level_name
	get_tree().reload_current_scene()

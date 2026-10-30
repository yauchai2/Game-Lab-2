extends CanvasLayer
## 掉落物名牌（仿 PoE 2）：地上的配件與裝備顯示為深色名牌，文字按稀有度上色，互相疊排不重疊。

const FISHEYE := preload("res://game/scripts/fisheye.gd")
const RARITY_COLORS := [Color("F4F0E4"), Color("9FB6E8"), Color("D6D573")]
const LABEL_H := 19.0
const PAD := 9.0

var labels := {}
var hide_common := false

func _ready() -> void:
	layer = -1

func _label_for(p: Node) -> Panel:
	if labels.has(p):
		return labels[p]
	var item: Dictionary = p.item
	var col: Color = RARITY_COLORS[item["rarity"]]
	var panel := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.05, 0.04, 0.03, 0.82)
	box.border_color = col.darkened(0.35)
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.name = "Text"
	l.text = _name_of(p)
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.position = Vector2(PAD, -2)
	panel.add_child(l)
	var w := l.get_minimum_size().x + PAD * 2.0
	panel.size = Vector2(w, LABEL_H)
	add_child(panel)
	labels[p] = panel
	return panel

func _name_of(p: Node) -> String:
	var player := get_tree().get_first_node_in_group("player")
	return player.ITEM_TYPES[p.item["type"]]["name"] if player else "物品"

# Z：只顯示藍色以上的名牌；按住 Alt：暫時顯示全部。
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Z:
		hide_common = not hide_common

# 點名牌撿取：滑鼠位置先按濾鏡校正，再比對名牌範圍。
func _input(event: InputEvent) -> void:
	if get_tree().paused or not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var m: Vector2 = FISHEYE.warp_pos(event.position, get_viewport().get_visible_rect().size)
	for p in labels.keys():
		var panel: Panel = labels[p]
		if is_instance_valid(p) and panel.visible and Rect2(panel.position, panel.size).has_point(m):
			p.pulled = true
			get_viewport().set_input_as_handled()
			return

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	visible = not get_tree().paused
	var show_all := Input.is_key_pressed(KEY_ALT)
	var rects: Array = []
	for p in get_tree().get_nodes_in_group("item_pickups"):
		if not is_instance_valid(p):
			continue
		var pos: Vector3 = p.global_position + Vector3(0, 0.8, 0)
		if cam.is_position_behind(pos):
			continue
		var sp := cam.unproject_position(pos)
		var panel := _label_for(p)
		var hidden: bool = hide_common and not show_all and p.item["rarity"] == 0
		panel.visible = not hidden
		if hidden:
			continue
		panel.position = sp - Vector2(panel.size.x * 0.5, LABEL_H)
		rects.append([panel, p])
	# 由上而下排開，重疊就往下推
	rects.sort_custom(func(a: Array, b: Array) -> bool: return a[0].position.y < b[0].position.y)
	var placed: Array = []
	for r in rects:
		var panel: Panel = r[0]
		var rect := Rect2(panel.position, panel.size)
		var moved := true
		var guard := 0
		while moved and guard < 30:
			moved = false
			guard += 1
			for o in placed:
				if rect.intersects(o.grow(1.0)):
					rect.position.y = o.end.y + 1.0
					moved = true
		panel.position = rect.position
		placed.append(rect)
		var blocked: bool = r[1].blocked_now
		panel.modulate.a = 0.5 if blocked else 1.0
	for p in labels.keys():
		if not is_instance_valid(p):
			labels[p].queue_free()
			labels.erase(p)

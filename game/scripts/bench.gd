extends Control
## 工作枱：左邊是技能卡匣與裝備欄，右邊是背包格子，下方是物品詳情與操作。
## 單擊選取、雙擊直接裝上／拆下；滑鼠移上去即時預覽。

const SFX := preload("res://game/scripts/sfx.gd")
const RARITY_COLORS := [Color("F4F0E4"), Color("9FB6E8"), Color("D6D573")]
const BG := Color("20232E")
const PANEL := Color("292D3B")
const CELL := Color("3A4054")
const CELL_ON := Color("4A6A66")
const CELL_HOVER := Color("565E7C")
const GEAR_ORDER := ["weapon", "head", "body", "feet", "trinket"]
const GEAR_NAMES := {"weapon": "武器", "head": "頭部", "body": "身體", "feet": "腳部", "trinket": "飾物"}
const SLOT_HINTS := {
	"weapon": "武器欄：決定普通攻擊的方式（近戰或遠程）。",
	"head": "頭部欄：提供生命、攻速等屬性。",
	"body": "身體欄：提供生命或技能傷害。",
	"feet": "腳部欄：提供移速或技能冷卻。",
	"trinket": "飾物欄：提供技能傷害、冷卻或普攻傷害。",
	"demolish": "技能卡匣槽：裝上配件，改變這個技能的效果。",
	"skate": "衝刺卡匣槽：裝上配件，改變衝刺的效果。",
}
const TAGS := {"demolish": "技", "skate": "衝", "weapon": "武", "head": "頭", "body": "身", "feet": "腳", "trinket": "飾"}

var jax: Node
var selected_uid := -1
var hover_uid := -1
var hover_slot := ""
var message := ""
var body := Control.new()
var detail := RichTextLabel.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.06, 0.09, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := ColorRect.new()
	panel.color = BG
	panel.position = Vector2(16, 12)
	panel.size = Vector2(608, 336)
	add_child(panel)
	add_child(body)
	var detail_bg := ColorRect.new()
	detail_bg.color = PANEL
	detail_bg.position = Vector2(316, 190)
	detail_bg.size = Vector2(290, 106)
	add_child(detail_bg)
	detail.bbcode_enabled = true
	detail.position = Vector2(322, 193)
	detail.size = Vector2(280, 100)
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_theme_font_size_override("normal_font_size", 10)
	detail.add_theme_font_size_override("bold_font_size", 12)
	add_child(detail)

func open() -> void:
	message = ""
	hover_uid = -1
	hover_slot = ""
	visible = true
	refresh()

func close() -> void:
	visible = false

# ---------- 小工具 ----------

func _label(text: String, pos: Vector2, size := 10, color := Color("E7DFC9")) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	body.add_child(l)
	return l

func _style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.content_margin_left = 2
	s.content_margin_right = 2
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s

func _cell(pos: Vector2, size: Vector2, text: String, border: Color, fill: Color, width: int) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = size
	b.text = text
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 10)
	b.add_theme_stylebox_override("normal", _style(fill, border, width))
	b.add_theme_stylebox_override("hover", _style(CELL_HOVER, border, width))
	b.add_theme_stylebox_override("pressed", _style(CELL_HOVER, border, width))
	b.add_theme_stylebox_override("focus", _style(fill, border, width))
	b.add_theme_stylebox_override("disabled", _style(fill, border, width))
	body.add_child(b)
	return b

func _short_name(item: Dictionary) -> String:
	return jax.ITEM_TYPES[item["type"]]["name"]

func _item_cart(item: Dictionary) -> String:
	return jax.ITEM_TYPES[item["type"]]["cart"]

func _hex(c: Color) -> String:
	return "#" + c.to_html(false)

# ---------- 畫面 ----------

func refresh() -> void:
	for c in body.get_children():
		c.queue_free()
	_header()
	_left_column()
	_inventory_grid()
	_detail_panel()
	_buttons()

func _header() -> void:
	_label("工作枱", Vector2(28, 16), 14)
	_label("單據 %d" % jax.receipts, Vector2(120, 18), 12, Color("D6D573"))
	_label("單擊選取　雙擊裝上／拆下　［C］或［Esc］關閉", Vector2(330, 19), 9, Color("9AA3AD"))

func _left_column() -> void:
	_label("技能卡匣", Vector2(28, 40), 10, Color("75C7B0"))
	var rows := [
		["demolish", "%s［Q／右鍵］" % jax.skill_name, jax.skill_desc],
		["skate", "滑板衝刺［空白鍵］", "朝移動方向衝刺，期間無敵"],
	]
	var y := 54
	for r in rows:
		_label("%s　%s" % [r[1], r[2]], Vector2(28, y), 9, Color("BCC5D4"))
		for i in 2:
			_slot_cell(r[0], i, Vector2(28 + i * 138, y + 14), Vector2(134, 30))
		y += 52
	_label("裝備（任何角色都能穿）", Vector2(28, 160), 10, Color("75C7B0"))
	for i in GEAR_ORDER.size():
		_slot_cell(GEAR_ORDER[i], 0, Vector2(28 + i * 55, 176), Vector2(52, 38))
	_label("屬性", Vector2(28, 222), 10, Color("75C7B0"))
	var w: Dictionary = jax.weapon_stats()
	var lines := [
		"生命 %d／%d　移速 %.1f" % [jax.hp, jax.max_hp, jax.speed],
		"普通攻擊：%s　傷害 %d　%.2f 秒　射程 %.1f 米" % ["近戰" if w["kind"] == "melee" else "遠程", roundi(w["dmg"]), w["cd"], w["reach"]],
		"技能傷害 +%d%%　技能冷卻 -%d%%" % [roundi(jax.affix_total("dmg", "demolish")), roundi(jax.affix_total("cd", "demolish"))],
	]
	for i in lines.size():
		_label(lines[i], Vector2(28, 236 + i * 14), 9)

func _slot_cell(cart: String, idx: int, pos: Vector2, size: Vector2) -> void:
	var item: Variant = jax.slots[cart][idx]
	var title: String
	var border := Color("5A6280")
	var name_color := Color("9AA3AD")
	if cart in GEAR_NAMES:
		title = "%s\n%s" % [GEAR_NAMES[cart], _short_name(item) if item != null else "（空）"]
	else:
		title = "槽 %s　%s" % ["AB"[idx], _short_name(item) if item != null else "（空）"]
	var uid: int = item["uid"] if item != null else -1
	if item != null:
		border = RARITY_COLORS[item["rarity"]]
		name_color = border
	var selected := item != null and uid == selected_uid
	var b := _cell(pos, size, title, Color.WHITE if selected else border, CELL_ON if item != null else CELL, 3 if selected else 2)
	b.add_theme_color_override("font_color", name_color)
	b.add_theme_color_override("font_hover_color", name_color)
	b.pressed.connect(_on_slot_pressed.bind(uid))
	b.mouse_entered.connect(_on_hover.bind(uid, cart))
	b.mouse_exited.connect(_on_hover.bind(-1, ""))
	b.gui_input.connect(_on_cell_input.bind(uid))

func _inventory_grid() -> void:
	_label("背包 %d／%d" % [jax.inventory.size(), jax.INVENTORY_LIMIT], Vector2(316, 40), 10, Color("75C7B0"))
	for n in jax.INVENTORY_LIMIT:
		var pos := Vector2(316 + (n % 4) * 74, 54 + (n / 4) * 44)
		if n >= jax.inventory.size():
			_cell(pos, Vector2(68, 40), "", Color("3A4054"), Color("262A38"), 1).disabled = true
			continue
		var it: Dictionary = jax.inventory[n]
		var equipped: bool = not jax.slot_info(it["uid"]).is_empty()
		var col: Color = RARITY_COLORS[it["rarity"]]
		var selected: bool = it["uid"] == selected_uid
		var text := "%s%s\n%s" % [TAGS[_item_cart(it)], "　已裝" if equipped else "", _short_name(it)]
		var b := _cell(pos, Vector2(68, 40), text, Color.WHITE if selected else col, CELL_ON if equipped else CELL, 3 if selected else 2)
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_hover_color", col)
		b.pressed.connect(_on_select.bind(it["uid"]))
		b.mouse_entered.connect(_on_hover.bind(it["uid"], ""))
		b.mouse_exited.connect(_on_hover.bind(-1, ""))
		b.gui_input.connect(_on_cell_input.bind(it["uid"]))

func _describe(item: Dictionary) -> String:
	var def: Dictionary = jax.ITEM_TYPES[item["type"]]
	var cart: String = def["cart"]
	var col := _hex(RARITY_COLORS[item["rarity"]])
	var t := "[color=%s][b]%s[/b][/color]\n" % [col, jax.item_name(item)]
	if cart in GEAR_NAMES:
		t += "裝備・%s" % GEAR_NAMES[cart]
		if cart == "weapon":
			t += "　" + ("自動揮擊身邊敵人" if def["kind"] == "melee" else ("自動射擊最近的 3 個敵人" if def.get("pellets", 1) > 1 else "自動射擊最近的敵人"))
	else:
		var cname: String = jax.skill_name if cart == "demolish" else "滑板衝刺"
		t += "卡匣配件・%s　%s" % [cname, def["desc"]]
	t += "\n"
	for part in jax.item_affix_text(item).split(", "):
		if part != "":
			t += "• %s\n" % part
	var info: Dictionary = jax.slot_info(item["uid"])
	if info.is_empty():
		var current: Variant = null
		if cart in GEAR_NAMES:
			current = jax.slots[cart][0]
		if current != null:
			t += "[color=#9AA3AD]裝上後會替換：%s[/color]" % jax.item_name(current)
		elif cart not in GEAR_NAMES and jax.slots[cart].find(null) < 0:
			t += "[color=#CC6657]兩個槽已滿，請先拆下一個[/color]"
	else:
		t += "[color=#75C7B0]已裝備中[/color]"
	return t

func _detail_panel() -> void:
	update_detail()
	var m := _label(message, Vector2(316, 300), 9, Color("CC6657"))
	m.size = Vector2(290, 14)

func update_detail() -> void:
	var uid := hover_uid if hover_uid >= 0 else selected_uid
	var item: Variant = jax.find_item(uid) if uid >= 0 else null
	if item != null:
		detail.text = _describe(item)
	elif hover_slot != "":
		detail.text = SLOT_HINTS[hover_slot]
	else:
		detail.text = "[color=#9AA3AD]點選背包或欄位中的物品查看詳情。\n\n配件改變技能效果，裝備提供屬性，\n武器決定普通攻擊。\n拆解物品可得單據，用來升級或重擲。[/color]"

func _buttons() -> void:
	var sel: Variant = jax.find_item(selected_uid)
	var equipped: bool = sel != null and not jax.slot_info(selected_uid).is_empty()
	var rarity: int = sel["rarity"] if sel != null else 0
	var specs := [
		["拆下" if equipped else "裝上", "toggle_equip", sel != null],
		["重擲 %d" % jax.REROLL_COST, "reroll_item", sel != null and rarity > 0 and jax.receipts >= jax.REROLL_COST],
		["升級 %s" % (str(jax.UPGRADE_COSTS[rarity]) if rarity < 2 else "已滿"), "upgrade_item", sel != null and rarity < 2 and jax.receipts >= jax.UPGRADE_COSTS[rarity]],
		["拆解 +1", "scrap_item", sel != null],
	]
	for i in specs.size():
		var b := _cell(Vector2(316 + i * 74, 318), Vector2(68, 24), specs[i][0], Color("75C7B0"), CELL, 1)
		b.disabled = not specs[i][2]
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_color_override("font_disabled_color", Color("6B7288"))
		b.pressed.connect(act.bind(specs[i][1]))
	if sel == null:
		_label("先選一件物品", Vector2(28, 318), 9, Color("9AA3AD"))
	elif rarity == 0:
		_label("普通物品沒有詞綴，可先升級再重擲", Vector2(28, 318), 9, Color("9AA3AD"))

# ---------- 互動 ----------

func _on_hover(uid: int, slot: String) -> void:
	hover_uid = uid
	hover_slot = slot if uid < 0 else ""
	update_detail()

func _on_select(uid: int) -> void:
	selected_uid = uid
	message = ""
	refresh()

func _on_slot_pressed(uid: int) -> void:
	if uid >= 0:
		_on_select(uid)

func _on_cell_input(event: InputEvent, uid: int) -> void:
	if uid >= 0 and event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		selected_uid = uid
		act("toggle_equip")

func act(method: String) -> void:
	var msg: String = jax.call(method, selected_uid)
	SFX.play(self, "ui_error" if msg != "" else "ui_click", -4.0)
	if method == "scrap_item":
		selected_uid = -1
	hover_uid = -1
	message = msg
	refresh()

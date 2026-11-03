extends Control
## 裝備頁（參考 PoE 2）：左邊是物品提示框與屬性，右邊上方是人形裝備欄與技能卡匣槽，下方是背包格子。
## 滑鼠移上去即時顯示提示；單擊選取、雙擊裝上／拆下。

const SFX := preload("res://game/scripts/sfx.gd")
const RARITY_COLORS := [Color("F4F0E4"), Color("8FA8E8"), Color("E6D26A")]
const BG := Color("14120F")
const GOLD := Color("7A6A3E")
const CELL := Color("221F1A")
const CELL_ON := Color("2F3F3B")
const CELL_HOVER := Color("3D372D")
const AFFIX_BLUE := "#8F8FFF"
const GEAR_NAMES := {"weapon": "武器", "head": "頭部", "body": "身體", "feet": "腳部", "trinket": "飾物"}
const SLOT_HINTS := {
	"weapon": "武器欄\n決定普通攻擊的方式（近戰或遠程）。",
	"head": "頭部欄\n提供生命、攻速等屬性。",
	"body": "身體欄\n提供生命或技能傷害。",
	"feet": "腳部欄\n提供移速或技能冷卻。",
	"trinket": "飾物欄\n提供技能傷害、冷卻或普攻傷害。",
	"demolish": "招牌技能槽（Q）\n裝上配件，改變這個技能的效果。\n點選技能槽後，再裝上配件，就會裝進這個技能。",
	"skill_e": "鐵鍊旋風（E）\n身邊連續三下範圍打擊。\n點選技能槽後再裝配件。",
	"skill_r": "衝擊線（R）\n朝滑鼠方向炸出一排爆炸。\n點選技能槽後再裝配件。",
	"skill_f": "油門全開（F）\n短時間加快移動與普攻。\n配件的冷卻與範圍詞綴有效。",
	"skate": "翻滾卡匣槽\n裝上配件，改變翻滾的效果。",
}
const TAGS := {"demolish": "技", "skate": "衝", "weapon": "武", "head": "頭", "body": "身", "feet": "腳", "trinket": "飾"}
const DOLL_ORIGIN := Vector2(244, 30)

var jax: Node
var selected_uid := -1
var hover_uid := -1
var hover_slot := ""
var message := ""
var target_cart := "demolish"
var body := Control.new()
var tip_head_bg := ColorRect.new()
var tip_head := Label.new()
var tip_body := RichTextLabel.new()
var stats := RichTextLabel.new()
var gear_panels: Array = []
var view := "gear"
var route := ""
var zoom_pending := false
var talent_tip := ""
var talent_tip_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.85)
	dim.position = Vector2(-4000, -4000)
	dim.size = Vector2(8640, 8360)
	add_child(dim)
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", _style(BG, GOLD, 2))
	panel.position = Vector2(8, 8)
	panel.size = Vector2(624, 344)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	# 左邊提示框
	var tip := Panel.new()
	tip.add_theme_stylebox_override("panel", _style(Color("0B0A08"), GOLD, 1))
	tip.position = Vector2(16, 30)
	tip.size = Vector2(216, 214)
	tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tip)
	gear_panels.append(tip)
	tip_head_bg.position = Vector2(17, 31)
	tip_head_bg.size = Vector2(214, 28)
	add_child(tip_head_bg)
	tip_head.position = Vector2(17, 31)
	tip_head.size = Vector2(214, 28)
	tip_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_head.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_head.add_theme_font_size_override("font_size", 12)
	add_child(tip_head)
	tip_body.bbcode_enabled = true
	tip_body.position = Vector2(22, 64)
	tip_body.size = Vector2(204, 176)
	tip_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip_body.add_theme_font_size_override("normal_font_size", 10)
	add_child(tip_body)
	var stat_panel := Panel.new()
	stat_panel.add_theme_stylebox_override("panel", _style(Color("0B0A08"), Color("3A3426"), 1))
	stat_panel.position = Vector2(16, 252)
	stat_panel.size = Vector2(216, 92)
	stat_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stat_panel)
	gear_panels.append(stat_panel)
	stats.bbcode_enabled = true
	stats.position = Vector2(22, 256)
	stats.size = Vector2(206, 86)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats.add_theme_font_size_override("normal_font_size", 9)
	add_child(stats)
	gear_panels.append_array([tip_head_bg, tip_head, tip_body, stats])
	add_child(body)

func open() -> void:
	message = ""
	view = "gear"
	route = ""
	hover_uid = -1
	hover_slot = ""
	visible = true
	refresh()

func close() -> void:
	visible = false

# ---------- 小工具 ----------

func _label(text: String, pos: Vector2, font_px := 10, color := Color("C9BC9A")) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", font_px)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

func _cell(pos: Vector2, cell_size: Vector2, text: String, border: Color, fill: Color, width: int) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = cell_size
	b.text = text
	b.clip_text = true
	b.add_theme_font_size_override("font_size", 9)
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
	for n in gear_panels:
		n.visible = view == "gear"
	_header()
	if view == "talent":
		_talent_view()
		return
	_doll()
	_cartridges()
	_inventory_grid()
	_buttons()
	update_detail()

func _header() -> void:
	for i in 2:
		var on := (view == "gear") == (i == 0)
		var b := _cell(Vector2(244 + i * 52, 6), Vector2(48, 16), ["裝備", "天賦"][i], GOLD if on else Color("3A3426"), CELL_ON if on else CELL, 1)
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_color_override("font_color", Color("E6D9B5") if on else Color("8C8470"))
		b.pressed.connect(set_view.bind("gear" if i == 0 else "talent"))
	_label("單據 %d" % jax.receipts, Vector2(356, 8), 11, Color("E6D26A"))
	_label("［C］或［Esc］關閉", Vector2(440, 11), 8, Color("8C8470"))
	if view == "gear":
		_label("雙擊裝上／拆下", Vector2(520, 11), 8, Color("8C8470"))

func set_view(v: String) -> void:
	SFX.play(self, "ui_click", -4.0)
	view = v
	route = ""
	refresh()

# ---------- 天賦樹 ----------

func _talent_view() -> void:
	var free: int = jax.talent_points_free()
	_label("天賦點 %d／%d" % [free, jax.talent_points_total()], Vector2(16, 8), 11, Color("E6D9B5") if free > 0 else Color("8C8470"))
	if route == "":
		_talent_overview()
	else:
		_talent_route()
	var rb := _cell(Vector2(536, 332), Vector2(88, 16), "重置 免費" if jax.TALENTS.respec_cost(jax.level) == 0 else "重置 %d" % jax.TALENTS.respec_cost(jax.level), GOLD, CELL, 1)
	rb.alignment = HORIZONTAL_ALIGNMENT_CENTER
	rb.disabled = jax.talents.is_empty() or jax.receipts < jax.TALENTS.respec_cost(jax.level)
	rb.add_theme_color_override("font_color", Color("E6D9B5"))
	rb.add_theme_color_override("font_disabled_color", Color("5E5848"))
	rb.pressed.connect(_on_respec)
	talent_tip_label = _label(talent_tip, Vector2(16, 334), 10, Color("E6D9B5"))

func _taken_in(r: String) -> int:
	var n := 0
	for id in jax.talents:
		if str(id).begins_with(r):
			n += 1
	return n

func _talent_overview() -> void:
	_label("選一條路線，鏡頭會拉近看細節。", Vector2(16, 28), 10, Color("8C8470"))
	var c := Vector2(320, 186)
	var core := _cell(c - Vector2(30, 14), Vector2(60, 28), "起點", GOLD, CELL_ON, 2)
	core.alignment = HORIZONTAL_ALIGNMENT_CENTER
	core.disabled = true
	for r in jax.TALENTS.route_ids():
		var def: Dictionary = jax.TALENTS.ROUTES[r]
		var pos: Vector2 = c + def["dir"] * Vector2(150, 84)
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = def["color"].darkened(0.4)
		line.add_point(c)
		line.add_point(pos)
		body.add_child(line)
		body.move_child(line, 0)
		var col: Color = def["color"]
		var b := _cell(pos - Vector2(56, 24), Vector2(112, 48), "%s\n%s\n已點 %d／%d" % [def["name"], def["hint"], _taken_in(r), jax.TALENTS.SHAPE.size()], col, CELL, 2)
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		b.add_theme_color_override("font_color", Color("E6D9B5"))
		b.pressed.connect(_enter_route.bind(r))

func _enter_route(r: String) -> void:
	SFX.play(self, "ui_click", -4.0)
	route = r
	zoom_pending = true
	talent_tip = ""
	refresh()

func _talent_route() -> void:
	var def: Dictionary = jax.TALENTS.ROUTES[route]
	var col: Color = def["color"]
	_label("%s　%s" % [def["name"], def["hint"]], Vector2(16, 28), 11, col)
	var back := _cell(Vector2(16, 48), Vector2(60, 16), "返回總覽", GOLD, CELL, 1)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.pressed.connect(_leave_route)
	_label("★ 為值得探索的點", Vector2(16, 70), 9, Color("E6D26A"))
	if jax.level < jax.TALENTS.FREE_RESPEC_LEVEL:
		_label("10 級前重置免費，放心試。", Vector2(16, 84), 9, Color("8C8470"))
	var graph := Control.new()
	graph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	graph.position = Vector2.ZERO
	graph.size = Vector2(640, 360)
	body.add_child(graph)
	var vis: Array = jax.TALENTS.all_ids()
	var pos_of := func(id: String) -> Vector2:
		var lp: Vector2 = jax.TALENTS.local_pos(id)
		return Vector2(330 + (lp.x + 0.75) * 66, 300 - lp.y * 54)
	for i in jax.TALENTS.SHAPE.size():
		var id: String = jax.TALENTS.node_id(route, i)
		var par: String = jax.TALENTS.parent_of(id)
		if par == "" or not vis.has(id):
			continue
		var ln := Line2D.new()
		ln.width = 2.0
		ln.default_color = col if jax.talents.has(id) else Color("3A3426")
		ln.add_point(pos_of.call(par))
		ln.add_point(pos_of.call(id))
		graph.add_child(ln)
	for i in jax.TALENTS.SHAPE.size():
		var id: String = jax.TALENTS.node_id(route, i)
		if not vis.has(id):
			continue
		var n: Dictionary = jax.TALENTS.info(id)
		var taken: bool = jax.talents.has(id)
		var can: bool = jax.can_alloc(id)
		var b := Button.new()
		b.position = pos_of.call(id) - Vector2(30, 17)
		b.size = Vector2(60, 34)
		b.text = ("★" if jax.TALENTS.is_highlight(id) else "") + n["name"]
		b.add_theme_font_size_override("font_size", 9)
		var border: Color = col if taken else (GOLD if can else (Color("E6D26A").darkened(0.35) if jax.TALENTS.is_highlight(id) else Color("3A3426")))
		var fill: Color = col.darkened(0.55) if taken else CELL
		for st in ["normal", "hover", "pressed", "focus", "disabled"]:
			b.add_theme_stylebox_override(st, _style(CELL_HOVER if st == "hover" else fill, border, 2 if (taken or can) else 1))
		b.add_theme_color_override("font_color", Color("E6D9B5") if (taken or can) else Color("8C8470"))
		b.mouse_entered.connect(_talent_hover.bind(id))
		b.pressed.connect(_on_talent.bind(id))
		graph.add_child(b)
	if zoom_pending:
		zoom_pending = false
		graph.pivot_offset = Vector2(330, 300)
		graph.scale = Vector2(0.35, 0.35)
		graph.modulate.a = 0.0
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(graph, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(graph, "modulate:a", 1.0, 0.2)

func _leave_route() -> void:
	SFX.play(self, "ui_click", -4.0)
	route = ""
	talent_tip = ""
	refresh()

func _talent_hover(id: String) -> void:
	var n: Dictionary = jax.TALENTS.info(id)
	var state := "已點" if jax.talents.has(id) else ("可點" if jax.can_alloc(id) else "需先點相連的前一點")
	talent_tip = "%s：%s（%s）" % [n["name"], jax.TALENTS.describe(id), state]
	if talent_tip_label != null:
		talent_tip_label.text = talent_tip

func _on_talent(id: String) -> void:
	var ok: bool = jax.alloc_talent(id)
	SFX.play(self, "ui_click" if ok else "ui_error", -4.0)
	_talent_hover(id)
	if not ok and not jax.talents.has(id):
		talent_tip = "不能點：%s" % ("天賦點不足" if jax.talent_points_free() <= 0 else "需先點相連的前一點")
	refresh()

func _on_respec() -> void:
	var ok: bool = jax.respec_talents()
	SFX.play(self, "ui_click" if ok else "ui_error", -4.0)
	talent_tip = "已重置，天賦點全數退回。" if ok else ""
	refresh()

func _doll() -> void:
	# 人形欄位：武器在左、頭／身／腳在中、飾物在右
	var o := DOLL_ORIGIN
	var sil := ColorRect.new()
	sil.color = Color("1B1813")
	sil.position = o
	sil.size = Vector2(376, 128)
	sil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(sil)
	_slot_cell("weapon", 0, o + Vector2(24, 8), Vector2(48, 92))
	_slot_cell("head", 0, o + Vector2(164, 4), Vector2(48, 32))
	_slot_cell("body", 0, o + Vector2(164, 38), Vector2(48, 52))
	_slot_cell("feet", 0, o + Vector2(164, 92), Vector2(48, 32))
	_slot_cell("trinket", 0, o + Vector2(304, 8), Vector2(48, 36))
	var w: Dictionary = jax.weapon_stats()
	_label("普通攻擊：%s" % ("近戰" if w["kind"] == "melee" else "遠程"), o + Vector2(10, 106), 8, Color("8C8470"))

func _cartridges() -> void:
	# 技能列：Q／E／R／F 與翻滾，各 2 個配件槽。點技能槽＝指定配件裝進哪個技能。
	var groups := ["demolish", "skill_e", "skill_r", "skill_f", "skate"]
	for gi in groups.size():
		var cart: String = groups[gi]
		var x := 244 + (gi % 2) * 190
		var y := 164 + int(gi / 2.0) * 25
		var locked: bool = not jax.skill_unlocked(cart) if cart != "skate" else false
		var key: String = jax.SKILL_KEYS.get(cart, "空白")
		var nm: String = jax.skill_name if cart == "demolish" else ("翻滾" if cart == "skate" else jax.EXTRA_SKILLS[cart]["name"])
		var col := Color("75C7B0") if cart == target_cart else (Color("5E5848") if locked else Color("C9BC9A"))
		_label("%s\n%s" % [key, nm.left(3)], Vector2(x, y - 1), 8, col)
		if locked:
			_label("Lv.%d 解鎖" % jax.EXTRA_SKILLS[cart]["unlock"], Vector2(x + 48, y + 5), 9, Color("5E5848"))
			continue
		for i in 2:
			_slot_cell(cart, i, Vector2(x + 34 + i * 76, y), Vector2(74, 22))

func _slot_cell(cart: String, idx: int, pos: Vector2, cell_size: Vector2) -> void:
	var item: Variant = jax.slots[cart][idx]
	var border := Color("4A4332")
	var name_color := Color("5E5848")
	var title: String
	if cart in GEAR_NAMES:
		title = "%s\n%s" % [TAGS[cart], _short_name(item) if item != null else GEAR_NAMES[cart]]
	else:
		title = _short_name(item) if item != null else "槽 %s" % "AB"[idx]
	var uid: int = item["uid"] if item != null else -1
	if item != null:
		border = RARITY_COLORS[item["rarity"]]
		name_color = border
	var selected := item != null and uid == selected_uid
	var b := _cell(pos, cell_size, title, Color.WHITE if selected else border, CELL_ON if item != null else CELL, 3 if selected else 1)
	b.add_theme_color_override("font_color", name_color)
	b.add_theme_color_override("font_hover_color", name_color)
	b.pressed.connect(_on_slot_pressed.bind(uid, cart))
	b.mouse_entered.connect(_on_hover.bind(uid, cart))
	b.mouse_exited.connect(_on_hover.bind(-1, ""))
	b.gui_input.connect(_on_cell_input.bind(uid))

func _inventory_grid() -> void:
	var bag: Array = jax.bag_items()
	_label("背包 %d／%d（已裝上的不佔格）　配件裝進：%s" % [bag.size(), jax.INVENTORY_LIMIT, jax.skill_name_of(target_cart)], Vector2(244, 240), 9, Color("C9BC9A"))
	for n in jax.INVENTORY_LIMIT:
		var pos := Vector2(244 + (n % 6) * 63, 254 + (n / 6) * 38)
		if n >= bag.size():
			_cell(pos, Vector2(60, 35), "", Color("2A261E"), Color("0F0E0B"), 1).disabled = true
			continue
		var it: Dictionary = bag[n]
		var equipped := false
		var col: Color = RARITY_COLORS[it["rarity"]]
		var selected: bool = it["uid"] == selected_uid
		var text := "%s%s\n%s" % [TAGS[_item_cart(it)], "　已裝" if equipped else "", _short_name(it)]
		var b := _cell(pos, Vector2(60, 35), text, Color.WHITE if selected else col, CELL_ON if equipped else CELL, 3 if selected else 1)
		b.add_theme_color_override("font_color", col)
		b.add_theme_color_override("font_hover_color", col)
		b.pressed.connect(_on_select.bind(it["uid"]))
		b.mouse_entered.connect(_on_hover.bind(it["uid"], ""))
		b.mouse_exited.connect(_on_hover.bind(-1, ""))
		b.gui_input.connect(_on_cell_input.bind(it["uid"]))

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
		var b := _cell(Vector2(244 + i * 94, 332), Vector2(90, 16), specs[i][0], GOLD, CELL, 1)
		b.disabled = not specs[i][2]
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_color_override("font_color", Color("E6D9B5"))
		b.add_theme_color_override("font_disabled_color", Color("5E5848"))
		b.pressed.connect(act.bind(specs[i][1]))

# ---------- 提示框與屬性 ----------

func _describe(item: Dictionary) -> String:
	var def: Dictionary = jax.ITEM_TYPES[item["type"]]
	var cart: String = def["cart"]
	var t := "[center]"
	if cart in GEAR_NAMES:
		t += "[color=#9A927C]%s[/color]\n" % GEAR_NAMES[cart]
		if cart == "weapon":
			var w: Dictionary = jax.weapon_stats_of(item)
			t += "%s\n" % ("近戰・自動揮擊身邊敵人" if def["kind"] == "melee" else ("遠程・自動射擊最近的 3 個敵人" if def.get("pellets", 1) > 1 else "遠程・自動射擊最近的敵人"))
			t += "傷害 %d　間隔 %.2f 秒　射程 %.1f 米\n" % [roundi(w["dmg"]), w["cd"], w["reach"]]
	else:
		var cname: String = "技能配件" if cart == "demolish" else "滑板翻滾"
		t += "[color=#9A927C]%s[/color]\n%s\n" % [cname, def["desc"]]
	t += "[color=#5E5848]────────[/color]\n"
	var any := false
	for part in jax.item_affix_text(item).split(", "):
		if part != "":
			t += "[color=%s]%s[/color]\n" % [AFFIX_BLUE, part]
			any = true
	if not any:
		t += "[color=#5E5848]沒有詞綴[/color]\n"
	t += "[color=#5E5848]────────[/color]\n"
	var info: Dictionary = jax.slot_info(item["uid"])
	if info.is_empty():
		var current: Variant = null
		if cart in GEAR_NAMES:
			current = jax.slots[cart][0]
		if current != null:
			t += "[color=#9A927C]裝上後會替換：%s[/color]" % jax.item_name(current)
		elif cart not in GEAR_NAMES and jax.slots[target_cart if cart == "demolish" else cart].find(null) < 0:
			t += "[color=#CC6657]選定的技能兩個槽已滿，請先拆下一個[/color]"
		else:
			t += "[color=#9A927C]雙擊裝上[/color]"
	else:
		t += "[color=#75C7B0]已裝備中[/color]"
	return t + "[/center]"

func update_detail() -> void:
	var uid := hover_uid if hover_uid >= 0 else selected_uid
	var item: Variant = jax.find_item(uid) if uid >= 0 else null
	if item != null:
		var col: Color = RARITY_COLORS[item["rarity"]]
		tip_head_bg.color = col.darkened(0.75)
		tip_head.text = _short_name(item)
		tip_head.add_theme_color_override("font_color", col)
		tip_body.text = _describe(item)
	else:
		tip_head_bg.color = Color("1B1813")
		tip_head.text = "物品"
		tip_head.add_theme_color_override("font_color", Color("8C8470"))
		if hover_slot != "":
			tip_body.text = "[center]%s[/center]" % SLOT_HINTS[hover_slot]
		else:
			tip_body.text = "[center][color=#8C8470]點選背包或欄位中的物品查看。\n\n配件改變技能效果，\n裝備提供屬性，\n武器決定普通攻擊。\n\n拆解物品可得單據，\n用來升級或重擲。[/color][/center]"
	var w: Dictionary = jax.weapon_stats()
	var s := "[color=#75C7B0]屬性[/color]\n"
	s += "生命 %d／%d　移速 %.1f\n" % [jax.hp, jax.max_hp, jax.speed]
	s += "普攻 %s　傷害 %d　%.2f 秒　射程 %.1f\n" % ["近戰" if w["kind"] == "melee" else "遠程", roundi(w["dmg"]), w["cd"], w["reach"]]
	s += "護甲 %d（物理減傷 %d%%）\n抗性　火 %d%%　冰 %d%%　電 %d%%\n" % [roundi(jax.armor_value()), roundi(jax.armor_reduction(20.0) * 100.0), roundi(jax.resist_of("fire")), roundi(jax.resist_of("cold")), roundi(jax.resist_of("lightning"))]
	s += "技能傷害 +%d%%　技能冷卻 -%d%%" % [roundi(jax.affix_total("dmg", "demolish")), roundi(jax.affix_total("cd", "demolish"))]
	if message != "":
		s += "\n[color=#CC6657]%s[/color]" % message
	elif selected_uid < 0:
		s += "\n[color=#8C8470]先選一件物品[/color]"
	stats.text = s

# ---------- 互動 ----------

func _on_hover(uid: int, slot: String) -> void:
	hover_uid = uid
	hover_slot = slot if uid < 0 else ""
	update_detail()

func _on_select(uid: int) -> void:
	selected_uid = uid
	message = ""
	refresh()

func _on_slot_pressed(uid: int, cart: String) -> void:
	if cart in jax.SKILL_CARTS:
		target_cart = cart
	if uid >= 0:
		_on_select(uid)
	else:
		refresh()

func _on_cell_input(event: InputEvent, uid: int) -> void:
	if uid >= 0 and event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		selected_uid = uid
		act("toggle_equip")

func act(method: String) -> void:
	var msg: String = jax.toggle_equip(selected_uid, target_cart) if method == "toggle_equip" else jax.call(method, selected_uid)
	SFX.play(self, "ui_error" if msg != "" else "ui_click", -4.0)
	if method == "scrap_item":
		selected_uid = -1
	hover_uid = -1
	message = msg
	refresh()

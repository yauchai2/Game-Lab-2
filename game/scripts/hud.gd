extends CanvasLayer

const SFX := preload("res://game/scripts/sfx.gd")
const BAR_SIZE := Vector2(140, 8)

var orb := Control.new()
var zone_tr: Control
var zone_bl: Control
var zone_bc: Control
var zone_br: Control
var zone_c: Control
var hurt_overlay := ColorRect.new()
var poise_back := ColorRect.new()
var poise_fill := ColorRect.new()
var guard_label := Label.new()
var break_back := ColorRect.new()
var break_fill := ColorRect.new()
var break_label := Label.new()
var xp_back := ColorRect.new()
var xp_fill := ColorRect.new()
var info := Label.new()
var banner := Label.new()
var lines := Control.new()
var card_band := ColorRect.new()
var card_title := Label.new()
var card_sub := Label.new()
var card_tween: Tween
const BenchScript := preload("res://game/scripts/bench.gd")
var bench := Control.new()
var skill_boxes := {}
var boss_back := ColorRect.new()
var boss_fill := ColorRect.new()
var boss_label := Label.new()

@onready var jax: Node = get_parent().get_node("Jax")

# 介面分區：低解像度畫面會隨視窗大小擴展，所以介面貼住畫面邊角（每區是 640×360 的座標系）。
## 介面以 640×360 的座標設計，基準解像度是 960×540，所以整體放大 1.5 倍。
const UI_SCALE := 1.5

func _zone(ax: float, ay: float) -> Control:
	var z := Control.new()
	z.anchor_left = ax
	z.anchor_right = ax
	z.anchor_top = ay
	z.anchor_bottom = ay
	z.offset_left = -640.0 * ax
	z.offset_right = 640.0 * (1.0 - ax)
	z.offset_top = -360.0 * ay
	z.offset_bottom = 360.0 * (1.0 - ay)
	z.scale = Vector2(UI_SCALE, UI_SCALE)
	z.pivot_offset = Vector2(640.0 * ax, 360.0 * ay)
	z.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(z)
	return z

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	zone_tr = _zone(1.0, 0.0)
	zone_bl = _zone(0.0, 1.0)
	zone_bc = _zone(0.5, 1.0)
	zone_br = _zone(1.0, 1.0)
	zone_c = _zone(0.5, 0.5)
	bench.set_script(BenchScript)
	bench.jax = jax
	zone_c.add_child(bench)
	boss_back.color = Color("292D3B")
	boss_back.position = Vector2(430, 8)
	boss_back.size = Vector2(202, 10)
	boss_back.visible = false
	zone_tr.add_child(boss_back)
	boss_fill.color = Color("D6D573")
	boss_fill.position = Vector2(221, 9)
	boss_fill.size = Vector2(200, 8)
	boss_back.add_child(boss_fill)
	boss_fill.position = Vector2(1, 1)
	boss_label.add_theme_font_size_override("font_size", 10)
	boss_label.position = Vector2(430, 30)
	boss_label.visible = false
	zone_tr.add_child(boss_label)
	hurt_overlay.color = Color(0.8, 0.1, 0.08, 0.0)
	hurt_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hurt_overlay)
	orb.set_script(load("res://game/scripts/orb.gd"))
	orb.position = Vector2(8, 300)
	orb.size = Vector2(56, 56)
	orb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zone_bl.add_child(orb)
	break_back.color = Color("292D3B")
	break_back.position = Vector2(430, 22)
	break_back.size = Vector2(202, 5)
	break_back.visible = false
	zone_tr.add_child(break_back)
	break_fill.color = Color("9FB6E8")
	break_fill.position = Vector2(1, 1)
	break_fill.size = Vector2(0, 3)
	break_back.add_child(break_fill)
	break_label.add_theme_font_size_override("font_size", 8)
	break_label.position = Vector2(560, 30)
	break_label.visible = false
	zone_tr.add_child(break_label)
	xp_back.color = Color("292D3B")
	xp_back.position = Vector2(8, 20)
	xp_back.size = Vector2(BAR_SIZE.x + 2, 5)
	add_child(xp_back)
	xp_fill.color = Color("75C7B0")
	xp_fill.position = Vector2(9, 21)
	xp_fill.size = Vector2(BAR_SIZE.x, 3)
	add_child(xp_fill)
	poise_back.color = Color("292D3B")
	poise_back.position = Vector2(8, 27)
	poise_back.size = Vector2(BAR_SIZE.x + 2, 4)
	add_child(poise_back)
	poise_fill.color = Color("E6D26A")
	poise_fill.position = Vector2(9, 28)
	poise_fill.size = Vector2(BAR_SIZE.x, 2)
	add_child(poise_fill)
	info.position = Vector2(8, 34)
	info.add_theme_font_size_override("font_size", 10)
	add_child(info)
	_build_skill_bar()
	_build_flasks()
	lines.set_script(load("res://game/scripts/speed_lines.gd"))
	add_child(lines)
	card_band.color = Color(0.16, 0.18, 0.23, 0.8)
	card_band.size = Vector2(640, 34)
	card_band.position = Vector2(0, 100)
	card_band.pivot_offset = Vector2(320, 17)
	card_band.visible = false
	zone_c.add_child(card_band)
	card_title.add_theme_font_size_override("font_size", 22)
	card_title.add_theme_color_override("font_color", Color("CC6657"))
	card_title.add_theme_color_override("font_outline_color", Color("E7DFC9"))
	card_title.add_theme_constant_override("outline_size", 3)
	card_title.size = Vector2(640, 26)
	card_title.position = Vector2(0, -3)
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_band.add_child(card_title)
	card_sub.add_theme_font_size_override("font_size", 8)
	card_sub.add_theme_color_override("font_color", Color("E7DFC9"))
	card_sub.size = Vector2(640, 12)
	card_sub.position = Vector2(0, 22)
	card_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_band.add_child(card_sub)
	jax.skill_cast.connect(_show_card)
	jax.dashed.connect(func() -> void:
		if jax.slot_names("skate") != "":
			lines.burst(1.0)
			_show_card("滑板翻滾", jax.slot_names("skate")))
	jax.slammed.connect(func(hits: int) -> void: lines.burst(clampf(0.5 + hits * 0.25, 0.5, 1.5)))
	banner.position = Vector2(8, 150)
	banner.add_theme_font_size_override("font_size", 20)
	zone_c.add_child(banner)

func _process(_delta: float) -> void:
	hurt_overlay.color.a = jax.hurt_flash * 0.6
	poise_fill.size.x = BAR_SIZE.x * clampf(jax.poise / jax.poise_cap(), 0.0, 1.0)
	poise_fill.color = Color("9FB6E8") if jax.stagger_immune > 0.0 else Color("E6D26A")
	orb.ratio = float(jax.hp) / float(jax.max_hp)
	orb.label_text = "%d" % jax.hp
	orb.queue_redraw()
	xp_fill.size.x = BAR_SIZE.x * float(jax.xp) / float(jax.xp_to_next())
	info.text = "等級 %d  生命 %d/%d  據點 %d/%d  單據 %d" % [jax.level, jax.hp, jax.max_hp, get_parent().camps_cleared(), get_parent().CAMPS.size(), jax.receipts]
	_update_skill_bar()
	_update_flasks()
	var b: Variant = get_parent().boss
	var boss_alive: bool = b != null and is_instance_valid(b) and b.hp > 0 and b.awake
	boss_back.visible = boss_alive
	boss_label.visible = boss_alive
	if boss_alive:
		boss_fill.size.x = 200.0 * float(b.hp) / float(b.max_hp)
		boss_label.text = "頭目：" + b.boss_name
		break_fill.size.x = 200.0 * clampf(b.break_value / b.BREAK_MAX, 0.0, 1.0)
		break_label.text = "破防！" if b.stun_left > 0.0 else "破防"
		break_fill.color = Color("E6D26A") if b.stun_left > 0.0 else Color("9FB6E8")
	break_back.visible = boss_alive
	break_label.visible = boss_alive
	if get_parent().victory:
		banner.text = ""
	elif jax.dead:
		banner.text = "倒下了（保留等級與配件，單據減半）－ 按 R 重新開始"
	elif jax.levelup_flash > 0.0 and not bench.visible:
		banner.text = jax.flash_text
	else:
		banner.text = ""

func toggle_bench() -> void:
	if bench.visible:
		bench.close()
		get_tree().paused = false
	elif not jax.dead and not get_tree().paused:
		move_child(zone_c, get_child_count() - 1)
		bench.open()
		get_tree().paused = true

# ---------- 底部技能列 ----------

const SKILL_BOX := Vector2(68, 30)

func _build_skill_bar() -> void:
	var defs := [["demolish", "Q"], ["skill_e", "E"], ["skill_r", "R"], ["skill_f", "F"], ["dash", "空白"], ["weapon", "自動"]]
	for i in defs.size():
		var back := ColorRect.new()
		back.color = Color(0.16, 0.18, 0.23, 0.85)
		back.size = SKILL_BOX
		back.position = Vector2(320 - defs.size() * 35 + i * 70, 326)
		zone_bc.add_child(back)
		var cool := ColorRect.new()
		cool.color = Color(0.05, 0.06, 0.09, 0.7)
		cool.size = Vector2(SKILL_BOX.x, 0)
		cool.position = Vector2(0, SKILL_BOX.y)
		cool.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.add_child(cool)
		var key := Label.new()
		key.text = defs[i][1]
		key.position = Vector2(2, -1)
		key.add_theme_font_size_override("font_size", 8)
		key.add_theme_color_override("font_color", Color("D6D573"))
		back.add_child(key)
		var title := Label.new()
		title.position = Vector2(2, 6)
		title.size = Vector2(SKILL_BOX.x - 4, 12)
		title.clip_text = true
		title.add_theme_font_size_override("font_size", 10)
		back.add_child(title)
		var sub := Label.new()
		sub.position = Vector2(2, 17)
		sub.size = Vector2(SKILL_BOX.x - 4, 11)
		sub.clip_text = true
		sub.add_theme_font_size_override("font_size", 8)
		sub.add_theme_color_override("font_color", Color("9AA3AD"))
		back.add_child(sub)
		skill_boxes[defs[i][0]] = {"cool": cool, "title": title, "sub": sub}

var flask_labels := {}

func _build_flasks() -> void:
	var i := 0
	for k in ["soda", "bento"]:
		var back := ColorRect.new()
		back.color = Color(0.16, 0.18, 0.23, 0.85)
		back.size = Vector2(40, 30)
		back.position = Vector2(548 + i * 44, 326)
		zone_br.add_child(back)
		var key := Label.new()
		key.text = str(i + 1)
		key.position = Vector2(2, -1)
		key.add_theme_font_size_override("font_size", 8)
		key.add_theme_color_override("font_color", Color("D6D573"))
		back.add_child(key)
		var title := Label.new()
		title.position = Vector2(2, 6)
		title.add_theme_font_size_override("font_size", 10)
		back.add_child(title)
		var sub := Label.new()
		sub.position = Vector2(2, 17)
		sub.add_theme_font_size_override("font_size", 8)
		back.add_child(sub)
		flask_labels[k] = [title, sub]
		i += 1

func _update_flasks() -> void:
	for k in flask_labels:
		var def: Dictionary = jax.FLASKS[k]
		var ch: int = jax.flask_charges[k]
		flask_labels[k][0].text = def["name"]
		flask_labels[k][0].add_theme_color_override("font_color", Color("E7DFC9") if ch > 0 else Color("6B7288"))
		flask_labels[k][1].text = "%d／%d" % [ch, def["max"]]
		flask_labels[k][1].add_theme_color_override("font_color", Color("75C7B0") if ch > 0 else Color("6B7288"))

func _set_box(id: String, title: String, sub: String, remain: float, total: float, locked := false) -> void:
	var box: Dictionary = skill_boxes[id]
	box["title"].text = title
	box["sub"].text = sub
	box["cool"].size.y = SKILL_BOX.y * clampf(remain / maxf(total, 0.01), 0.0, 1.0)
	if locked:
		box["cool"].size.y = SKILL_BOX.y
	box["cool"].position.y = SKILL_BOX.y - box["cool"].size.y
	box["title"].add_theme_color_override("font_color", Color("E7DFC9") if remain <= 0.0 and not locked else Color("9AA3AD"))

func _update_skill_bar() -> void:
	var w: Dictionary = jax.weapon_stats()
	for cart in jax.SKILL_CARTS:
		var nm: String = jax.skill_name_of(cart)
		var remain: float = jax.skill_timer_of(cart)
		var total: float = jax.skill_cooldown if cart == "demolish" else jax.EXTRA_SKILLS[cart]["cd"]
		var locked: bool = not jax.skill_unlocked(cart)
		var atts: String = jax.slot_names(cart)
		var sub := "Lv.%d 解鎖" % jax.EXTRA_SKILLS[cart]["unlock"] if locked else (atts if atts != "" else "無配件")
		var title := nm if remain <= 0.0 or locked else "%s %.1f" % [nm, remain]
		if cart == "skill_f" and jax.buff_left > 0.0:
			title = "%s %.1f" % [nm, jax.buff_left]
		_set_box(cart, title, sub, remain, total, locked)
	var rmax: int = jax.roll_max()
	var dash_sub: String = jax.slot_names("skate")
	var rr: float = jax.roll_recharge if jax.roll_charges < rmax else 0.0
	_set_box("dash", "翻滾 %d／%d" % [jax.roll_charges, rmax], ("%.1f 秒" % rr) if rr > 0.0 else (dash_sub if dash_sub != "" else "無配件"), 0.0 if jax.roll_charges > 0 else rr, jax.ROLL_RECHARGE)
	var wi: Variant = jax.slots["weapon"][0]
	_set_box("weapon", jax.item_name(wi) if wi != null else "空手", "近戰" if w["kind"] == "melee" else "遠程", 0.0, 1.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_C or (bench.visible and event.keycode == KEY_ESCAPE)):
		toggle_bench()
		return

func _show_card(title: String, subtitle: String) -> void:
	card_title.text = title
	card_sub.text = subtitle
	card_band.visible = true
	card_band.modulate.a = 1.0
	card_band.scale = Vector2(1, 0.1)
	if card_tween:
		card_tween.kill()
	card_tween = create_tween()
	card_tween.tween_property(card_band, "scale", Vector2(1, 1), 0.08)
	card_tween.tween_interval(0.55)
	card_tween.tween_property(card_band, "modulate:a", 0.0, 0.2)
	card_tween.tween_callback(func() -> void: card_band.visible = false)

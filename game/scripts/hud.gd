extends CanvasLayer

const SFX := preload("res://game/scripts/sfx.gd")
const BAR_SIZE := Vector2(140, 8)

var hp_back := ColorRect.new()
var hp_fill := ColorRect.new()
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

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bench.set_script(BenchScript)
	bench.jax = jax
	add_child(bench)
	boss_back.color = Color("292D3B")
	boss_back.position = Vector2(430, 8)
	boss_back.size = Vector2(202, 10)
	boss_back.visible = false
	add_child(boss_back)
	boss_fill.color = Color("D6D573")
	boss_fill.position = Vector2(221, 9)
	boss_fill.size = Vector2(200, 8)
	boss_back.add_child(boss_fill)
	boss_fill.position = Vector2(1, 1)
	boss_label.add_theme_font_size_override("font_size", 10)
	boss_label.position = Vector2(430, 18)
	boss_label.visible = false
	add_child(boss_label)
	hp_back.color = Color("292D3B")
	hp_back.position = Vector2(8, 8)
	hp_back.size = BAR_SIZE + Vector2(2, 2)
	add_child(hp_back)
	hp_fill.color = Color("CC6657")
	hp_fill.position = Vector2(9, 9)
	hp_fill.size = BAR_SIZE
	add_child(hp_fill)
	xp_back.color = Color("292D3B")
	xp_back.position = Vector2(8, 20)
	xp_back.size = Vector2(BAR_SIZE.x + 2, 5)
	add_child(xp_back)
	xp_fill.color = Color("75C7B0")
	xp_fill.position = Vector2(9, 21)
	xp_fill.size = Vector2(BAR_SIZE.x, 3)
	add_child(xp_fill)
	info.position = Vector2(8, 28)
	info.add_theme_font_size_override("font_size", 10)
	add_child(info)
	_build_skill_bar()
	lines.set_script(load("res://game/scripts/speed_lines.gd"))
	add_child(lines)
	card_band.color = Color(0.16, 0.18, 0.23, 0.8)
	card_band.size = Vector2(640, 34)
	card_band.position = Vector2(0, 100)
	card_band.pivot_offset = Vector2(320, 17)
	card_band.visible = false
	add_child(card_band)
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
			_show_card("滑板衝刺", jax.slot_names("skate")))
	jax.slammed.connect(func(hits: int) -> void: lines.burst(clampf(0.5 + hits * 0.25, 0.5, 1.5)))
	banner.position = Vector2(8, 150)
	banner.add_theme_font_size_override("font_size", 20)
	add_child(banner)

func _process(_delta: float) -> void:
	hp_fill.size.x = BAR_SIZE.x * float(jax.hp) / float(jax.max_hp)
	xp_fill.size.x = BAR_SIZE.x * float(jax.xp) / float(jax.xp_to_next())
	info.text = "等級 %d  生命 %d/%d  據點 %d/%d  單據 %d" % [jax.level, jax.hp, jax.max_hp, get_parent().camps_cleared(), get_parent().CAMPS.size(), jax.receipts]
	_update_skill_bar()
	var b: Variant = get_parent().boss
	var boss_alive: bool = b != null and is_instance_valid(b) and b.hp > 0 and b.awake
	boss_back.visible = boss_alive
	boss_label.visible = boss_alive
	if boss_alive:
		boss_fill.size.x = 200.0 * float(b.hp) / float(b.max_hp)
		boss_label.text = "頭目：" + b.boss_name
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
		move_child(bench, get_child_count() - 1)
		bench.open()
		get_tree().paused = true

# ---------- 底部技能列 ----------

const SKILL_BOX := Vector2(96, 30)

func _build_skill_bar() -> void:
	var defs := [["skill", "Q"], ["dash", "空白"], ["weapon", "自動"]]
	for i in defs.size():
		var back := ColorRect.new()
		back.color = Color(0.16, 0.18, 0.23, 0.85)
		back.size = SKILL_BOX
		back.position = Vector2(320 - 150 + i * 102, 326)
		add_child(back)
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
		title.add_theme_font_size_override("font_size", 10)
		back.add_child(title)
		var sub := Label.new()
		sub.position = Vector2(2, 17)
		sub.add_theme_font_size_override("font_size", 8)
		sub.add_theme_color_override("font_color", Color("9AA3AD"))
		back.add_child(sub)
		skill_boxes[defs[i][0]] = {"cool": cool, "title": title, "sub": sub}

func _set_box(id: String, title: String, sub: String, remain: float, total: float) -> void:
	var box: Dictionary = skill_boxes[id]
	box["title"].text = title
	box["sub"].text = sub
	box["cool"].size.y = SKILL_BOX.y * clampf(remain / maxf(total, 0.01), 0.0, 1.0)
	box["cool"].position.y = SKILL_BOX.y - box["cool"].size.y
	box["title"].add_theme_color_override("font_color", Color("E7DFC9") if remain <= 0.0 else Color("9AA3AD"))

func _update_skill_bar() -> void:
	var skill_sub: String = jax.slot_names("demolish")
	var dash_sub: String = jax.slot_names("skate")
	var w: Dictionary = jax.weapon_stats()
	var cd: float = jax.skill_timer
	var dcd: float = jax.dash_timer
	_set_box("skill", jax.skill_name + ("" if cd <= 0.0 else "  %.1f" % cd), skill_sub if skill_sub != "" else "無配件", cd, jax.skill_cooldown)
	_set_box("dash", "衝刺" + ("" if dcd <= 0.0 else "  %.1f" % dcd), dash_sub if dash_sub != "" else "無配件", dcd, jax.dash_cooldown)
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

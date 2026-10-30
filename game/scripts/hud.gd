extends CanvasLayer

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
var bench := VBoxContainer.new()
var bench_msg := Label.new()
var selected_uid := -1

@onready var jax: Node = get_parent().get_node("Jax")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bench.position = Vector2(60, 62)
	bench.custom_minimum_size = Vector2(520, 0)
	bench.visible = false
	add_child(bench)
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
	jax.dashed.connect(lines.burst.bind(1.0))
	jax.slammed.connect(func(hits: int) -> void: lines.burst(clampf(0.5 + hits * 0.25, 0.5, 1.5)))
	banner.position = Vector2(8, 150)
	banner.add_theme_font_size_override("font_size", 20)
	add_child(banner)

func _process(_delta: float) -> void:
	hp_fill.size.x = BAR_SIZE.x * float(jax.hp) / float(jax.max_hp)
	xp_fill.size.x = BAR_SIZE.x * float(jax.xp) / float(jax.xp_to_next())
	var cd: float = jax.skill_timer
	var skill := "READY" if cd <= 0.0 else "%.1fs" % cd
	var dash: String = "READY" if jax.dash_timer <= 0.0 else "%.1fs" % jax.dash_timer
	info.text = "Lv %d  HP %d/%d  Wave %d  Receipts %d\nDemolish [Q/RMB]: %s   Dash [Space]: %s   Cartridge [C]" % [jax.level, jax.hp, jax.max_hp, get_parent().wave, jax.receipts, skill, dash]
	if jax.dead:
		banner.text = "KO  -  press R to restart"
	elif jax.levelup_flash > 0.0 and not bench.visible:
		banner.text = jax.flash_text
	else:
		banner.text = ""

func toggle_bench() -> void:
	if bench.visible:
		bench.visible = false
		get_tree().paused = false
	elif not jax.dead:
		bench.visible = true
		get_tree().paused = true
		bench_msg.text = ""
		_refresh_bench()

func _bench_label(text: String, size := 10) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color("292D3B"))
	l.add_theme_constant_override("outline_size", 4)
	return l

func _bench_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 10)
	b.pressed.connect(handler)
	return b

const RARITY_COLORS := [Color("F4F0E4"), Color("9FB6E8"), Color("D6D573")]

func _item_line(it: Dictionary) -> String:
	var line: String = jax.item_name(it)
	var affixes: String = jax.item_affix_text(it)
	return line + ("  (" + affixes + ")" if affixes != "" else "")

func _refresh_bench() -> void:
	for c in bench.get_children():
		c.queue_free()
	bench.add_child(_bench_label("CARTRIDGE: DEMOLISH   Receipts %d   (C to close)" % jax.receipts, 12))
	bench.add_child(_bench_label("Slots (click to unequip):"))
	for i in jax.slots.size():
		var it: Variant = jax.slots[i]
		var b := _bench_button("Slot %s: %s" % ["AB"[i], _item_line(it) if it != null else "(empty)"], _on_slot.bind(i))
		if it != null:
			b.add_theme_color_override("font_color", RARITY_COLORS[it["rarity"]])
		bench.add_child(b)
	bench.add_child(_bench_label("Inventory %d/%d (click to select):" % [jax.inventory.size(), jax.INVENTORY_LIMIT]))
	for it in jax.inventory:
		var mark := ">" if it["uid"] == selected_uid else " "
		var eq := "[E] " if jax.slot_of(it["uid"]) >= 0 else ""
		var b := _bench_button("%s %s%s" % [mark, eq, _item_line(it)], _on_select.bind(it["uid"]))
		b.add_theme_color_override("font_color", RARITY_COLORS[it["rarity"]])
		bench.add_child(b)
	var row := HBoxContainer.new()
	var sel: Variant = jax.find_item(selected_uid)
	var equipped: bool = sel != null and jax.slot_of(selected_uid) >= 0
	var rarity: int = sel["rarity"] if sel != null else 0
	var up_text := "Upgrade (%d)" % jax.UPGRADE_COSTS[rarity] if rarity < 2 else "Upgrade (max)"
	row.add_child(_bench_button("Unequip" if equipped else "Equip", _act.bind("toggle_equip")))
	row.add_child(_bench_button("Reroll (%d)" % jax.REROLL_COST, _act.bind("reroll_item")))
	row.add_child(_bench_button(up_text, _act.bind("upgrade_item")))
	row.add_child(_bench_button("Scrap (+1)", _act.bind("scrap_item")))
	for b in row.get_children():
		b.disabled = sel == null
	bench.add_child(row)
	bench_msg = _bench_label("")
	bench.add_child(bench_msg)

func _on_slot(i: int) -> void:
	var it: Variant = jax.slots[i]
	if it != null:
		jax.toggle_equip(it["uid"])
	_refresh_bench()

func _on_select(uid: int) -> void:
	selected_uid = uid
	_refresh_bench()

func _act(method: String) -> void:
	var msg: String = jax.call(method, selected_uid)
	if method == "scrap_item":
		selected_uid = -1
	_refresh_bench()
	bench_msg.text = msg

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

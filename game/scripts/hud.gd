extends CanvasLayer

const BAR_SIZE := Vector2(140, 8)

var hp_back := ColorRect.new()
var hp_fill := ColorRect.new()
var xp_back := ColorRect.new()
var xp_fill := ColorRect.new()
var info := Label.new()
var banner := Label.new()
var bench := VBoxContainer.new()
var bench_msg := Label.new()

@onready var jax: Node = get_parent().get_node("Jax")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bench.position = Vector2(120, 62)
	bench.custom_minimum_size = Vector2(400, 0)
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
	elif jax.levelup_flash > 0.0:
		banner.text = "LEVEL UP!"
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

func _refresh_bench() -> void:
	for c in bench.get_children():
		c.queue_free()
	bench.add_child(_bench_label("CARTRIDGE: DEMOLISH   Receipts %d   (C to close)" % jax.receipts, 12))
	bench.add_child(_bench_label("Slots (click to remove):"))
	for i in jax.slots.size():
		var id: String = jax.slots[i]
		var text := "Slot %s: %s" % ["AB"[i], jax.ATTACHMENTS[id]["name"] if id != "" else "(empty)"]
		bench.add_child(_bench_button(text, _on_slot.bind(i)))
	bench.add_child(_bench_label("Attachments (click to buy / equip):"))
	for id in jax.ATTACHMENTS:
		var a: Dictionary = jax.ATTACHMENTS[id]
		var state := "EQUIPPED" if jax.slots.has(id) else ("owned" if jax.owned.has(id) else "%d receipts" % a["cost"])
		bench.add_child(_bench_button("%s - %s  [%s]" % [a["name"], a["desc"], state], _on_attachment.bind(id)))
	bench_msg = _bench_label("")
	bench.add_child(bench_msg)

func _on_slot(i: int) -> void:
	jax.unequip(i)
	_refresh_bench()

func _on_attachment(id: String) -> void:
	var msg := ""
	if jax.slots.has(id):
		jax.unequip(jax.slots.find(id))
	elif jax.owned.has(id):
		if not jax.equip(id):
			msg = "Both slots are full. Remove one first."
	elif not jax.buy(id):
		msg = "Not enough receipts."
	_refresh_bench()
	bench_msg.text = msg

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_C or (bench.visible and event.keycode == KEY_ESCAPE)):
		toggle_bench()
		return

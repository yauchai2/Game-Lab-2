extends CanvasLayer

const BAR_SIZE := Vector2(140, 8)

var hp_back := ColorRect.new()
var hp_fill := ColorRect.new()
var xp_back := ColorRect.new()
var xp_fill := ColorRect.new()
var info := Label.new()
var banner := Label.new()
var choice_box := VBoxContainer.new()
var choices: Array = []

@onready var jax: Node = get_parent().get_node("Jax")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	choice_box.position = Vector2(170, 90)
	choice_box.custom_minimum_size = Vector2(300, 0)
	choice_box.visible = false
	add_child(choice_box)
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
	if jax.pending_choices > 0 and not choice_box.visible and not jax.dead:
		_show_choices()
	hp_fill.size.x = BAR_SIZE.x * float(jax.hp) / float(jax.max_hp)
	xp_fill.size.x = BAR_SIZE.x * float(jax.xp) / float(jax.xp_to_next())
	var cd: float = jax.skill_timer
	var skill := "READY" if cd <= 0.0 else "%.1fs" % cd
	var dash: String = "READY" if jax.dash_timer <= 0.0 else "%.1fs" % jax.dash_timer
	info.text = "Lv %d  HP %d/%d  Wave %d\nDemolish [Q/RMB]: %s   Dash [Space]: %s" % [jax.level, jax.hp, jax.max_hp, get_parent().wave, skill, dash]
	if jax.dead:
		banner.text = "KO  -  press R to restart"
	elif jax.levelup_flash > 0.0:
		banner.text = "LEVEL UP!"
	else:
		banner.text = ""

func _show_choices() -> void:
	for c in choice_box.get_children():
		c.queue_free()
	var pool: Array = jax.UPGRADES.duplicate()
	pool.shuffle()
	choices = pool.slice(0, 3)
	var title := Label.new()
	title.text = "LEVEL UP!  Pick an upgrade (1/2/3)"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_outline_color", Color("292D3B"))
	title.add_theme_constant_override("outline_size", 4)
	choice_box.add_child(title)
	for i in choices.size():
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, choices[i]["label"]]
		b.add_theme_font_size_override("font_size", 10)
		b.pressed.connect(choose.bind(i))
		choice_box.add_child(b)
	choice_box.visible = true
	get_tree().paused = true

func choose(i: int) -> void:
	if i < 0 or i >= choices.size():
		return
	jax.apply_upgrade(choices[i]["id"])
	jax.pending_choices -= 1
	choices = []
	choice_box.visible = false
	get_tree().paused = false

func _unhandled_key_input(event: InputEvent) -> void:
	if choice_box.visible and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: choose(0)
			KEY_2: choose(1)
			KEY_3: choose(2)

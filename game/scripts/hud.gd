extends CanvasLayer

const BAR_SIZE := Vector2(140, 8)

var hp_back := ColorRect.new()
var hp_fill := ColorRect.new()
var info := Label.new()
var banner := Label.new()

@onready var jax: Node = get_parent().get_node("Jax")

func _ready() -> void:
	hp_back.color = Color("292D3B")
	hp_back.position = Vector2(8, 8)
	hp_back.size = BAR_SIZE + Vector2(2, 2)
	add_child(hp_back)
	hp_fill.color = Color("CC6657")
	hp_fill.position = Vector2(9, 9)
	hp_fill.size = BAR_SIZE
	add_child(hp_fill)
	info.position = Vector2(8, 20)
	info.add_theme_font_size_override("font_size", 10)
	add_child(info)
	banner.position = Vector2(8, 150)
	banner.add_theme_font_size_override("font_size", 20)
	add_child(banner)

func _process(_delta: float) -> void:
	hp_fill.size.x = BAR_SIZE.x * float(jax.hp) / float(jax.max_hp)
	var cd: float = jax.skill_timer
	var skill := "READY" if cd <= 0.0 else "%.1fs" % cd
	info.text = "HP %d/%d   Wave %d   Demolish [Q / Right-click]: %s" % [jax.hp, jax.max_hp, get_parent().wave, skill]
	banner.text = "KO  -  press R to restart" if jax.dead else ""

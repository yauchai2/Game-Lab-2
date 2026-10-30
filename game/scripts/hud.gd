extends CanvasLayer

var hp_bar := ProgressBar.new()
var info := Label.new()
var banner := Label.new()

@onready var jax: Node = get_parent().get_node("Jax")

func _ready() -> void:
	hp_bar.position = Vector2(20, 20)
	hp_bar.size = Vector2(260, 24)
	hp_bar.max_value = jax.max_hp
	hp_bar.show_percentage = false
	add_child(hp_bar)
	info.position = Vector2(20, 52)
	add_child(info)
	banner.position = Vector2(20, 120)
	banner.add_theme_font_size_override("font_size", 32)
	add_child(banner)

func _process(_delta: float) -> void:
	hp_bar.value = jax.hp
	var cd: float = jax.skill_timer
	var skill := "READY" if cd <= 0.0 else "%.1fs" % cd
	info.text = "HP %d/%d   Wave %d   Demolish [Q / Right-click]: %s" % [jax.hp, jax.max_hp, get_parent().wave, skill]
	banner.text = "KO  -  press R to restart" if jax.dead else ""

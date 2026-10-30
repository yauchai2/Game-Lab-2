extends Node3D

const ENEMY_SCENE := preload("res://game/enemy.tscn")
const BOSS_SCENE := preload("res://game/boss.tscn")
const ARENA_LIMIT := 18.0
const BOSS_WAVE := 3

var wave := 0
var next_wave_timer := 1.5
var boss: Node = null
var victory := false

@onready var jax: CharacterBody3D = $Jax

func _process(delta: float) -> void:
	if jax.dead or victory or boss != null:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		next_wave_timer -= delta
		if next_wave_timer <= 0.0:
			if wave >= BOSS_WAVE:
				_spawn_boss()
			else:
				_spawn_wave()
	else:
		next_wave_timer = 3.0

func _spawn_wave() -> void:
	wave += 1
	var count := 2 + wave
	for i in count:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.max_hp = 40 + (wave - 1) * 8
		if wave >= 2 and i % 3 == 2:
			enemy.ranged = true
			enemy.max_hp = 25 + (wave - 2) * 5
			enemy.base_color = Color("9B8ACC")
		var angle := TAU * i / count + randf() * 0.5
		var pos := jax.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 12.0
		pos.x = clampf(pos.x, -ARENA_LIMIT, ARENA_LIMIT)
		pos.z = clampf(pos.z, -ARENA_LIMIT, ARENA_LIMIT)
		add_child(enemy)
		enemy.global_position = pos

func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate()
	add_child(boss)
	boss.global_position = jax.global_position + Vector3(0, 0, -11)
	boss.defeated.connect(func() -> void:
		victory = true
		boss = null)

func _unhandled_input(event: InputEvent) -> void:
	if victory and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()

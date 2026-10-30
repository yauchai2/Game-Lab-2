extends Node3D

const ENEMY_SCENE := preload("res://game/enemy.tscn")
const ARENA_LIMIT := 18.0

var wave := 0
var next_wave_timer := 1.5

@onready var jax: CharacterBody3D = $Jax

func _process(delta: float) -> void:
	if jax.dead:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		next_wave_timer -= delta
		if next_wave_timer <= 0.0:
			_spawn_wave()
	else:
		next_wave_timer = 3.0

func _spawn_wave() -> void:
	wave += 1
	var count := 2 + wave
	for i in count:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.max_hp = 40 + (wave - 1) * 8
		var angle := TAU * i / count + randf() * 0.5
		var pos := jax.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 12.0
		pos.x = clampf(pos.x, -ARENA_LIMIT, ARENA_LIMIT)
		pos.z = clampf(pos.z, -ARENA_LIMIT, ARENA_LIMIT)
		add_child(enemy)
		enemy.global_position = pos

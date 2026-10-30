extends Node3D

const SFX := preload("res://game/scripts/sfx.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")
const BOSS_SCENE := preload("res://game/boss.tscn")
const BOSS_POS := Vector3(0, 0.05, -17)
const START_POS := Vector3(0, 0.87, 11)
## 據點：位置、近戰數量、遠程數量。由近至遠，玩家自己推進。
const CAMPS := [
	{"pos": Vector3(-7, 0, 2), "melee": 3, "ranged": 0},
	{"pos": Vector3(8, 0, -3), "melee": 3, "ranged": 1},
	{"pos": Vector3(-8, 0, -8), "melee": 4, "ranged": 1},
	{"pos": Vector3(9, 0, -12), "melee": 3, "ranged": 2},
]

var boss: Node = null
var victory := false

@onready var jax: CharacterBody3D = $Jax

func _ready() -> void:
	jax.global_position = START_POS
	for i in CAMPS.size():
		_spawn_camp(i)
	_spawn_boss()

func _spawn_camp(index: int) -> void:
	var camp: Dictionary = CAMPS[index]
	var total: int = camp["melee"] + camp["ranged"]
	for i in total:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.awake = false
		enemy.camp = "camp_%d" % index
		enemy.max_hp = 40 + index * 8
		if i >= camp["melee"]:
			enemy.ranged = true
			enemy.max_hp = 25 + index * 5
			enemy.base_color = Color("9B8ACC")
		add_child(enemy)
		var a := TAU * i / total
		enemy.global_position = camp["pos"] + Vector3(cos(a), 0.05, sin(a)) * 2.0

func _spawn_boss() -> void:
	boss = BOSS_SCENE.instantiate()
	boss.awake = false
	add_child(boss)
	boss.global_position = BOSS_POS
	boss.defeated.connect(func() -> void:
		victory = true
		boss = null
		SFX.play(self, "victory"))

func camps_cleared() -> int:
	var n := 0
	for i in CAMPS.size():
		if get_tree().get_nodes_in_group("camp_%d" % i).is_empty():
			n += 1
	return n

func _unhandled_input(event: InputEvent) -> void:
	if victory and event is InputEventKey and event.pressed and event.keycode == KEY_R:
		jax.save_progress(false)
		get_tree().reload_current_scene()

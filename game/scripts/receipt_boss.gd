extends "res://game/scripts/enemy.gd"
## TK-075「收據」：蓋印機為核心的殺手頭目。不死：被打倒後禮貌離開。
## 階段 1 蓋印（預警圈）；階段 2 叫打工仔、打爆蓋印機才能削弱；階段 3 慢速單發槍擊。

signal defeated
signal phase_changed(phase: int)

const ZONE := preload("res://game/scripts/zone.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")
const STAMP_RADIUS := 2.6
const STAMP_DELAY := 1.0
const STAMP_DAMAGE := 18

var boss_name := "TK-075「收據」"
var phase := 1
var stamp_cd := 2.5
var stamp_pending := -1.0
var stamp_center := Vector3.ZERO
var stamp_machine: Node3D = null
var shot_cd := 2.0
var summon_cd := 8.0
var hp_scale := 1.0

func _ready() -> void:
	max_hp = int(420 * hp_scale)
	speed = 2.0
	attack_range = 2.2
	attack_damage = 10
	attack_cooldown = 1.5
	base_color = Color("292D3B")
	super._ready()
	add_to_group("boss")
	aggro_range = 11.0

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	if not awake:
		_check_aggro()
		return
	cooldown = maxf(cooldown - delta, 0.0)
	knockback = knockback.move_toward(Vector3.ZERO, 30.0 * delta)
	var move := Vector3.ZERO
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.dead:
		var to: Vector3 = player.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		_update_phase()
		if stamp_pending >= 0.0:
			stamp_pending -= delta
			if stamp_pending < 0.0:
				_stamp_land(player)
		else:
			if dist > attack_range:
				move = to.normalized() * speed
			elif cooldown <= 0.0:
				cooldown = attack_cooldown
				player.take_damage(attack_damage)
			stamp_cd -= delta
			if stamp_cd <= 0.0:
				_stamp_start(player)
		if phase == 2:
			summon_cd -= delta
			if summon_cd <= 0.0 and get_tree().get_nodes_in_group("workers").size() < 2:
				summon_cd = 12.0
				_summon()
		elif phase == 3:
			shot_cd -= delta
			if shot_cd <= 0.0 and dist > 3.0:
				shot_cd = 2.6
				_shoot(to.normalized())
		if dist > 0.01:
			look_at(global_position + to, Vector3.UP)
	velocity.x = move.x + knockback.x
	velocity.z = move.z + knockback.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _update_phase() -> void:
	if phase == 1 and hp <= max_hp * 0.66:
		phase = 2
		stamp_machine = ENEMY_SCENE.instantiate()
		stamp_machine.max_hp = 90
		stamp_machine.speed = 0.0
		stamp_machine.attack_damage = 0
		stamp_machine.base_color = Color("D6D573")
		stamp_machine.awake = true
		get_parent().add_child(stamp_machine)
		stamp_machine.global_position = global_position + Vector3(3.0, 0, 0)
		stamp_machine.scale = Vector3(0.7, 0.7, 0.7)
		stamp_cd = 2.0
		_summon()
		phase_changed.emit(2)
	elif phase == 2 and (stamp_machine == null or not is_instance_valid(stamp_machine) or stamp_machine.hp <= 0):
		phase = 3
		stamp_cd = 4.5
		attack_cooldown = 2.4
		phase_changed.emit(3)

func _stamp_start(player: Node3D) -> void:
	stamp_cd = 3.4 if phase == 1 else (3.0 if phase == 2 else 4.5)
	stamp_pending = STAMP_DELAY
	stamp_center = player.global_position
	_spawn_zone(stamp_center, STAMP_RADIUS, STAMP_DELAY, Color("D6D573"))

func _stamp_land(player: Node3D) -> void:
	stamp_pending = -1.0
	_spawn_zone(stamp_center, STAMP_RADIUS, 0.3, Color("CC6657"))
	var d: Vector3 = player.global_position - stamp_center
	d.y = 0.0
	if d.length() <= STAMP_RADIUS:
		player.take_damage(STAMP_DAMAGE)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(0.25)

func _spawn_zone(center: Vector3, radius: float, life: float, color: Color) -> void:
	var zone := Node3D.new()
	zone.set_script(ZONE)
	zone.radius = radius
	zone.life = life
	zone.damage = 0
	zone.color = color
	get_parent().add_child(zone)
	zone.global_position = Vector3(center.x, 0.06, center.z)

func _summon() -> void:
	for i in 2:
		var e := ENEMY_SCENE.instantiate()
		e.max_hp = 35
		e.base_color = Color("4A4E69")
		e.camp = "workers"
		get_parent().add_child(e)
		var a := PI * i + 0.8
		e.global_position = global_position + Vector3(cos(a), 0.0, sin(a)) * 3.0

func _drop_loot() -> void:
	var player := get_tree().get_first_node_in_group("player")
	for i in 2:
		var item: Dictionary = player.make_item(player.ITEM_TYPES.keys().pick_random(), 1)
		_spawn_pickup("item", 0, Vector3(cos(i * 3.1) * 1.5, 0, sin(i * 3.1) * 1.5), item)
	_spawn_pickup("receipt", 8, Vector3(0, 0, 1.0))
	remove_from_group("boss")
	defeated.emit()

extends "res://game/scripts/enemy.gd"
## TK-060「領帶」：章末頭目。極度整齊，打得再激烈也先拉直領帶。
## 階段 1 標準程序（扇形標記彈、預警圈）；階段 2 現場重組（場地改變、叫打工仔）；階段 3 程序失效（無法分類，定時露出破綻）。

signal defeated
signal phase_changed(phase: int)
signal confused_changed(on: bool)

const ZONE := preload("res://game/scripts/zone.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")

var boss_name := "TK-060「領帶」"
var phase := 1
var hp_scale := 1.0
var shot_cd := 2.5
var zone_cd := 4.0
var zone_pending := -1.0
var zone_center := Vector3.ZERO
var summon_cd := 6.0
var confuse_cd := 5.0
var confused_left := 0.0

func _ready() -> void:
	max_hp = int(600 * hp_scale)
	speed = 2.4
	attack_range = 2.2
	attack_damage = 12
	attack_cooldown = 1.4
	base_color = Color("3B3F4E")
	super._ready()
	add_to_group("boss")
	aggro_range = 12.0

func take_damage(amount: int, from_pos: Vector3 = Vector3.ZERO, knock := 6.0) -> void:
	if confused_left > 0.0:
		amount = int(amount * 1.5)
	super.take_damage(amount, from_pos, knock)

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
		if confused_left > 0.0:
			confused_left -= delta
			if confused_left <= 0.0:
				confused_changed.emit(false)
				_material.albedo_color = base_color
		else:
			if phase == 3:
				confuse_cd -= delta
				if confuse_cd <= 0.0:
					confuse_cd = 7.0
					confused_left = 3.0
					_material.albedo_color = Color("D6D573")
					confused_changed.emit(true)
			_attack(delta, player, to, dist)
			if zone_pending < 0.0 and dist > attack_range:
				move = to.normalized() * speed
		if dist > 0.01:
			look_at(global_position + to, Vector3.UP)
	velocity.x = move.x + knockback.x
	velocity.z = move.z + knockback.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _attack(delta: float, player: Node3D, to: Vector3, dist: float) -> void:
	if zone_pending >= 0.0:
		zone_pending -= delta
		if zone_pending < 0.0:
			_zone_land(player)
		return
	if dist <= attack_range and cooldown <= 0.0:
		cooldown = attack_cooldown
		player.take_damage(attack_damage)
	shot_cd -= delta
	if shot_cd <= 0.0 and dist > 3.0:
		shot_cd = 3.2 if phase == 1 else (2.6 if phase == 2 else 2.0)
		for a in [-0.35, 0.0, 0.35]:
			_shoot(to.normalized().rotated(Vector3.UP, a))
	zone_cd -= delta
	if zone_cd <= 0.0:
		zone_cd = 4.5 if phase == 1 else 3.6
		zone_pending = 1.0
		zone_center = player.global_position
		_spawn_zone(zone_center, 2.4, 1.0, Color("D6D573"))
	if phase == 2:
		summon_cd -= delta
		if summon_cd <= 0.0 and get_tree().get_nodes_in_group("workers").size() < 2:
			summon_cd = 12.0
			_summon()

func _update_phase() -> void:
	if phase == 1 and hp <= max_hp * 0.66:
		phase = 2
		_summon()
		phase_changed.emit(2)
	elif phase == 2 and hp <= max_hp * 0.33:
		phase = 3
		confuse_cd = 3.0
		phase_changed.emit(3)

func _zone_land(player: Node3D) -> void:
	zone_pending = -1.0
	_spawn_zone(zone_center, 2.4, 0.3, Color("CC6657"))
	var d: Vector3 = player.global_position - zone_center
	d.y = 0.0
	if d.length() <= 2.4:
		player.take_damage(20)

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
		e.max_hp = 40
		e.base_color = Color("4A4E69")
		e.camp = "workers"
		get_parent().add_child(e)
		e.global_position = global_position + Vector3(cos(PI * i), 0.0, sin(PI * i)) * 3.0

func _drop_loot() -> void:
	var player := get_tree().get_first_node_in_group("player")
	for i in 3:
		var item: Dictionary = player.make_item(player.ITEM_TYPES.keys().pick_random(), 1 + (1 if randf() < 0.5 else 0))
		_spawn_pickup("item", 0, Vector3(cos(i * 2.1) * 1.5, 0, sin(i * 2.1) * 1.5), item)
	_spawn_pickup("receipt", 12, Vector3(0, 0, 1.0))
	remove_from_group("boss")
	defeated.emit()

extends "res://game/scripts/enemy.gd"
## 頭目「收數大佬」：追擊、預警重擊（紅圈）、半血召喚小弟。

signal defeated

const ZONE := preload("res://game/scripts/zone.gd")
const ENEMY_SCENE := preload("res://game/enemy.tscn")
const SLAM_RADIUS := 3.5
const SLAM_DELAY := 1.0
const SLAM_DAMAGE := 22

var boss_name := "收數大佬"
var slam_cooldown := 2.5
var slam_pending := -1.0
var slam_center := Vector3.ZERO
var summoned := false

func _ready() -> void:
	max_hp = 520
	speed = 2.2
	attack_range = 2.4
	attack_damage = 12
	attack_cooldown = 1.4
	base_color = Color("CC6657")
	super._ready()
	add_to_group("boss")
	aggro_range = 10.0

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
		if slam_pending >= 0.0:
			slam_pending -= delta
			if slam_pending < 0.0:
				_slam_land(player)
		else:
			if dist > attack_range:
				move = to.normalized() * speed
			elif cooldown <= 0.0:
				cooldown = attack_cooldown
				player.take_damage(attack_damage)
			slam_cooldown -= delta
			if slam_cooldown <= 0.0:
				_slam_start(player)
		if dist > 0.01:
			look_at(global_position + to, Vector3.UP)
		if not summoned and hp <= max_hp * 0.5:
			summoned = true
			_summon()
	velocity.x = move.x + knockback.x
	velocity.z = move.z + knockback.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _slam_start(player: Node3D) -> void:
	slam_cooldown = 3.5 if hp > max_hp * 0.5 else 2.5
	slam_pending = SLAM_DELAY
	SFX.play(self, "boss_warn")
	slam_center = player.global_position
	_spawn_zone(slam_center, SLAM_RADIUS, SLAM_DELAY, 0, Color("D6D573"))

func _slam_land(player: Node3D) -> void:
	slam_pending = -1.0
	SFX.play(self, "boss_slam")
	_spawn_zone(slam_center, SLAM_RADIUS, 0.25, 0, Color("CC6657"))
	var d: Vector3 = player.global_position - slam_center
	d.y = 0.0
	if d.length() <= SLAM_RADIUS:
		player.take_damage(SLAM_DAMAGE)
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_shake"):
		cam.add_shake(0.25)

func _spawn_zone(center: Vector3, radius: float, life: float, damage: int, color: Color) -> void:
	var zone := Node3D.new()
	zone.set_script(ZONE)
	zone.radius = radius
	zone.life = life
	zone.damage = damage
	zone.color = color
	get_parent().add_child(zone)
	zone.global_position = Vector3(center.x, 0.06, center.z)

func _summon() -> void:
	for i in 3:
		var e := ENEMY_SCENE.instantiate()
		e.max_hp = 40
		get_parent().add_child(e)
		var a := TAU * i / 3.0
		e.global_position = global_position + Vector3(cos(a), 0.0, sin(a)) * 3.0

func _drop_loot() -> void:
	var player := get_tree().get_first_node_in_group("player")
	for i in 3:
		var item: Dictionary = player.make_item(player.ITEM_TYPES.keys().pick_random(), 1 + (1 if randf() < 0.5 else 0))
		_spawn_pickup("item", 0, Vector3(cos(i * 2.1) * 1.5, 0, sin(i * 2.1) * 1.5), item)
	_spawn_pickup("receipt", 10, Vector3(0, 0, 1.0))
	remove_from_group("boss")
	defeated.emit()

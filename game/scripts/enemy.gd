extends CharacterBody3D

@export var max_hp := 40
@export var speed := 2.8
@export var attack_range := 1.6
@export var attack_damage := 5
@export var attack_cooldown := 1.2
@export var gravity := 20.0
@export var ranged := false
@export var base_color := Color("8C9871")

var hp := 40
var awake := true
var aggro_range := 9.0
var camp := ""
var cooldown := 0.0
var knockback := Vector3.ZERO
var _material := StandardMaterial3D.new()

const PICKUP := preload("res://game/scripts/pickup.gd")
const PROJECTILE := preload("res://game/scripts/projectile.gd")

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	if camp != "":
		add_to_group(camp)
	_material.albedo_color = base_color
	mesh.material_override = _material

func take_damage(amount: int, from_pos: Vector3 = Vector3.ZERO, knock := 6.0) -> void:
	if hp <= 0:
		return
	hp -= amount
	wake()
	var away := global_position - from_pos
	away.y = 0.0
	if away.length() > 0.01:
		knockback = away.normalized() * knock
	_material.albedo_color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color", base_color, 0.2)
	if hp <= 0:
		remove_from_group("enemies")
		if camp != "":
			remove_from_group(camp)
		collision_layer = 0
		_drop_loot()
		var die := create_tween()
		die.tween_property(self, "scale", Vector3(1.2, 0.01, 1.2), 0.25)
		die.tween_callback(queue_free)

# 敵群平時站定，玩家走近（或同營敵人受驚動）才會一起追擊。
func wake() -> void:
	if awake:
		return
	awake = true
	if camp != "":
		get_tree().call_group(camp, "wake")

func _check_aggro() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.dead and global_position.distance_to(player.global_position) <= aggro_range:
		wake()

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	if not awake:
		_check_aggro()
		return
	cooldown = maxf(cooldown - delta, 0.0)
	knockback = knockback.move_toward(Vector3.ZERO, 20.0 * delta)
	var move := Vector3.ZERO
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.dead:
		var to: Vector3 = player.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if ranged:
			if dist > 9.0:
				move = to.normalized() * speed
			elif dist < 5.0:
				move = -to.normalized() * speed * 0.8
			if dist <= 11.0 and cooldown <= 0.0:
				cooldown = 2.0
				_shoot(to.normalized())
		elif dist > attack_range:
			move = to.normalized() * speed
		elif cooldown <= 0.0:
			cooldown = attack_cooldown
			player.take_damage(attack_damage)
		if dist > 0.01:
			look_at(global_position + to, Vector3.UP)
	velocity.x = move.x + knockback.x
	velocity.z = move.z + knockback.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _drop_loot() -> void:
	_spawn_pickup("xp", 10, Vector3(0.3, 0, 0))
	_spawn_pickup("receipt", 2 if ranged else 1, Vector3(0, 0, 0.3))
	if randf() < 0.35:
		_spawn_pickup("hp", 20, Vector3(-0.3, 0, 0))
	var player := get_tree().get_first_node_in_group("player")
	if player and player.should_drop_item(ranged):
		_spawn_pickup("item", 0, Vector3(0, 0, -0.3), player.random_item())

func _spawn_pickup(kind: String, value: int, offset: Vector3, item := {}) -> void:
	var p := Node3D.new()
	p.set_script(PICKUP)
	p.kind = kind
	p.value = value
	p.item = item
	get_parent().add_child(p)
	p.global_position = global_position + offset + Vector3(0, 0.5, 0)

func _shoot(dir: Vector3) -> void:
	var b := Node3D.new()
	b.set_script(PROJECTILE)
	b.direction = dir
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 1.0, 0) + dir * 0.8

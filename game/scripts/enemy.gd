extends CharacterBody3D

@export var max_hp := 40
@export var speed := 2.8
@export var attack_range := 1.6
@export var attack_damage := 5
@export var attack_cooldown := 1.2
@export var gravity := 20.0
@export var base_color := Color("8C9871")

var hp := 40
var cooldown := 0.0
var knockback := Vector3.ZERO
var _material := StandardMaterial3D.new()

const PICKUP := preload("res://game/scripts/pickup.gd")

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	_material.albedo_color = base_color
	mesh.material_override = _material

func take_damage(amount: int, from_pos: Vector3 = Vector3.ZERO) -> void:
	if hp <= 0:
		return
	hp -= amount
	var away := global_position - from_pos
	away.y = 0.0
	if away.length() > 0.01:
		knockback = away.normalized() * 6.0
	_material.albedo_color = Color.WHITE
	var tween := create_tween()
	tween.tween_property(_material, "albedo_color", base_color, 0.2)
	if hp <= 0:
		remove_from_group("enemies")
		collision_layer = 0
		_drop_loot()
		var die := create_tween()
		die.tween_property(self, "scale", Vector3(1.2, 0.01, 1.2), 0.25)
		die.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if hp <= 0:
		return
	cooldown = maxf(cooldown - delta, 0.0)
	knockback = knockback.move_toward(Vector3.ZERO, 20.0 * delta)
	var move := Vector3.ZERO
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.dead:
		var to: Vector3 = player.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > attack_range:
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
	if randf() < 0.35:
		_spawn_pickup("hp", 20, Vector3(-0.3, 0, 0))

func _spawn_pickup(kind: String, value: int, offset: Vector3) -> void:
	var p := Node3D.new()
	p.set_script(PICKUP)
	p.kind = kind
	p.value = value
	get_parent().add_child(p)
	p.global_position = global_position + offset + Vector3(0, 0.5, 0)

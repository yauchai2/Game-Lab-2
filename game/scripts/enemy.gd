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
const PAINTER := preload("res://game/scripts/painter.gd")
var _material := StandardMaterial3D.new()

const SFX := preload("res://game/scripts/sfx.gd")
const PICKUP := preload("res://game/scripts/pickup.gd")
const PROJECTILE := preload("res://game/scripts/projectile.gd")
const FLOATY := preload("res://game/scripts/floaty.gd")
const HITFX := preload("res://game/scripts/hitfx.gd")

var show_bar := true
var element := "phys"
## 韌性：小怪被連打幾下就踉蹌（短硬直）；大怪（精英、頭目）只有重擊（技能、完美格擋反擊）才打得破。
var big := false
## 裝甲（第一章維修場）：普通攻擊只有兩成傷害，技能（重擊）才能破防。
var armor := false
var poise_max := 24.0
var poise := 24.0
var poise_wait := 0.0
var stagger_left := 0.0
var stagger_immune := 0.0
var bar_poise := MeshInstance3D.new()
var bar_back := MeshInstance3D.new()
var bar_fill := MeshInstance3D.new()

@onready var mesh: MeshInstance3D = $Mesh

func _ready() -> void:
	hp = max_hp
	if big:
		poise_max = maxf(poise_max, 90.0)
	poise = poise_max
	add_to_group("enemies")
	if camp != "":
		add_to_group(camp)
	_material.albedo_color = base_color
	mesh.material_override = _material
	_material.albedo_texture = null
	PAINTER.apply_material(_material)
	if show_bar:
		_make_bar()

# 受擊反應：火花、身體被打扁彈回、輕微震鏡；重擊多一點頓幀。
func _hit_react(frac: float) -> void:
	HITFX.sparks(get_parent(), global_position + Vector3(0, 1.1, 0), Color("F4F0E4"), 4 + int(minf(frac, 1.0) * 14.0), 1.0 + minf(frac, 1.0))
	HITFX.shake(self, 0.04 + minf(frac, 1.0) * 0.25)
	if frac >= 0.2:
		HITFX.hit_stop(get_tree(), 0.04)
	var base := Vector3.ONE
	mesh.scale = Vector3(1.3, 0.75, 1.3)
	var tw := create_tween()
	tw.tween_property(mesh, "scale", base, 0.14)

func poise_damage(p: float) -> void:
	poise_wait = 2.0
	if stagger_immune > 0.0 or stagger_left > 0.0 or hp <= 0:
		return
	poise -= p
	if poise <= 0.0:
		poise = poise_max
		stagger_left = 2.2 if big else 0.5
		stagger_immune = stagger_left + 2.5
		cooldown = maxf(cooldown, 0.6)
		FLOATY.spawn(get_parent(), global_position + Vector3(0, 2.5, 0), "破防" if big else "踉蹌", Color("9FB6E8"), true)
		HITFX.sparks(get_parent(), global_position + Vector3(0, 1.5, 0), Color("9FB6E8"), 10, 1.2)
	_update_bar()

func _bar_mesh(m: MeshInstance3D, color: Color, width: float) -> void:
	var q := QuadMesh.new()
	q.size = Vector2(width, 0.09)
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	m.material_override = mat

# 敵人血條：受傷後才顯示。
func _make_bar() -> void:
	_bar_mesh(bar_back, Color("14161D"), 0.84)
	_bar_mesh(bar_fill, Color("CC6657"), 0.8)
	bar_back.position = Vector3(0, 2.0, 0)
	bar_fill.position = Vector3(0, 2.0, 0.01)
	_bar_mesh(bar_poise, Color("E6D26A"), 0.8)
	(bar_poise.mesh as QuadMesh).size = Vector2(0.8, 0.04)
	bar_poise.position = Vector3(0, 1.93, 0.01)
	bar_back.visible = false
	bar_fill.visible = false
	bar_poise.visible = false
	add_child(bar_back)
	add_child(bar_fill)
	add_child(bar_poise)

func _update_bar() -> void:
	var visible_bar := show_bar and hp > 0 and hp < max_hp
	bar_back.visible = visible_bar
	bar_fill.visible = visible_bar
	bar_poise.visible = visible_bar
	if visible_bar:
		var pf := clampf(poise / poise_max, 0.001, 1.0)
		bar_poise.scale.x = pf
		bar_poise.position.x = -0.4 * (1.0 - pf)
		var f := clampf(float(hp) / float(max_hp), 0.0, 1.0)
		bar_fill.scale.x = maxf(f, 0.001)
		bar_fill.position.x = -0.4 * (1.0 - f)

func take_damage(amount: int, from_pos: Vector3 = Vector3.ZERO, knock := 6.0, heavy_hit := false) -> void:
	if hp <= 0:
		return
	if armor and not heavy_hit:
		amount = maxi(int(amount * 0.2), 1)
	hp -= amount
	var frac := float(amount) / float(max_hp)
	var big_hit := frac >= 0.2
	FLOATY.spawn(get_parent(), global_position + Vector3(0, 1.9, 0), str(amount), Color("E6D26A") if big_hit else Color("F4F0E4"), big_hit)
	if hp > 0:
		var p := float(amount) * (2.0 if heavy_hit else 1.0)
		if heavy_hit:
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("talent_total"):
				p *= 1.0 + pl.talent_total("heavy") / 100.0
		if big:
			p *= 0.6 if heavy_hit else 0.15
		poise_damage(p)
	_update_bar()
	_hit_react(frac)
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
		HITFX.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), base_color.lightened(0.3), 18, 1.6)
		HITFX.hit_stop(get_tree(), 0.05)
		HITFX.shake(self, 0.18)
		knockback *= 1.8
		bar_back.visible = false
		bar_fill.visible = false
		_drop_loot()
		SFX.play(self, "enemy_die", -4.0)
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
	stagger_immune = maxf(stagger_immune - delta, 0.0)
	poise_wait = maxf(poise_wait - delta, 0.0)
	if poise_wait <= 0.0 and poise < poise_max:
		poise = minf(poise + poise_max * 0.3 * delta, poise_max)
	if stagger_left > 0.0:
		stagger_left -= delta
		_material.albedo_color = Color("9FB6E8")
		if stagger_left <= 0.0:
			_material.albedo_color = base_color
		velocity.x = knockback.x
		velocity.z = knockback.z
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
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
			player.take_damage(attack_damage, "phys", self)
		if dist > 0.01:
			look_at(global_position + to, Vector3.UP)
	velocity.x = move.x + knockback.x
	velocity.z = move.z + knockback.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()

func _drop_loot() -> void:
	var killer := get_tree().get_first_node_in_group("player")
	if killer:
		killer.on_kill()
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
	SFX.play(self, "shoot", -8.0)
	var b := Node3D.new()
	b.set_script(PROJECTILE)
	b.direction = dir
	b.element = element
	get_parent().add_child(b)
	b.global_position = global_position + Vector3(0, 1.0, 0) + dir * 0.8

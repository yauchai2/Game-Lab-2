extends CharacterBody3D

@export var speed := 6.0
@export var gravity := 20.0
@export var skill_cooldown := 1.5
@export var skill_windup := 0.3
@export var skill_radius := 3.5
@export var skill_damage := 25
@export var max_hp := 120
@export var dash_speed := 22.0
@export var dash_time := 0.22
@export var dash_cooldown := 1.0

var target := Vector3.ZERO
var has_target := false
var skill_timer := 0.0
var windup_left := -1.0
var anim_time := 0.0
var hp := 120
var dead := false
var level := 1
var xp := 0
var levelup_flash := 0.0
var flash_text := ""
signal skill_cast(title: String, subtitle: String)
signal dashed
signal slammed(hit_count: int)

var receipts := 0
var inventory: Array = []
var slots: Array = [null, null]
var next_uid := 1
var item_rolls := 0
var dash_left := 0.0
var dash_timer := 0.0
var dash_dir := Vector3.ZERO

@onready var model: Node3D = $Model
@onready var leg_l: Node3D = model.find_child("LegL", true, false)
@onready var leg_r: Node3D = model.find_child("LegR", true, false)
@onready var arm_l: Node3D = model.find_child("ArmL", true, false)
@onready var arm_r: Node3D = model.find_child("ArmR", true, false)

func _ready() -> void:
	hp = max_hp
	add_to_group("player")

func xp_to_next() -> int:
	return 30 * level

func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		max_hp += 10
		skill_damage += 3
		hp = max_hp
		flash_text = "LEVEL UP!"
		levelup_flash = 1.5

const ZONE := preload("res://game/scripts/zone.gd")

# --- Cartridge attachments: random drops with rarity, equipped into 2 slots ---

const ITEM_TYPES := {
	"heavy": {"name": "Heavy Stamp", "desc": "damage up, slower windup"},
	"burst": {"name": "Echo Slam", "desc": "hits multiple times"},
	"linger": {"name": "Scorch Zone", "desc": "leaves a damaging zone"},
	"delay": {"name": "Time Bomb", "desc": "delayed blast, wider range"},
}
const RARITY_NAMES := ["Normal", "Magic", "Rare"]
const RARITY_WEIGHTS := [70, 25, 5]
const AFFIXES := {
	"dmg": {"min": 8.0, "max": 18.0, "text": "+%d%% damage"},
	"range": {"min": 0.3, "max": 0.8, "text": "+%.1fm range"},
	"cd": {"min": 5.0, "max": 12.0, "text": "-%d%% cooldown"},
}
const INVENTORY_LIMIT := 12
const REROLL_COST := 2
const UPGRADE_COSTS := [3, 6]

func _roll_affix(kind: String) -> Dictionary:
	var def: Dictionary = AFFIXES[kind]
	var v := randf_range(def["min"], def["max"])
	v = snappedf(v, 0.1) if kind == "range" else float(roundi(v))
	return {"kind": kind, "value": v}

func _roll_affixes(count: int) -> Array:
	var kinds: Array = AFFIXES.keys()
	kinds.shuffle()
	var out: Array = []
	for i in count:
		out.append(_roll_affix(kinds[i]))
	return out

func make_item(type: String, rarity: int) -> Dictionary:
	var item := {"uid": next_uid, "type": type, "rarity": rarity, "affixes": _roll_affixes(rarity)}
	next_uid += 1
	return item

func random_item() -> Dictionary:
	var roll := randi() % 100
	var rarity := 0
	if roll >= RARITY_WEIGHTS[0] + RARITY_WEIGHTS[1]:
		rarity = 2
	elif roll >= RARITY_WEIGHTS[0]:
		rarity = 1
	var types: Array = ITEM_TYPES.keys()
	return make_item(types[randi() % types.size()], rarity)

func should_drop_item(from_ranged: bool) -> bool:
	item_rolls += 1
	if item_rolls <= 2:
		return true
	return randf() < (0.35 if from_ranged else 0.25)

func item_name(item: Dictionary) -> String:
	return "%s %s" % [RARITY_NAMES[item["rarity"]], ITEM_TYPES[item["type"]]["name"]]

func item_affix_text(item: Dictionary) -> String:
	var parts: Array[String] = []
	for a in item["affixes"]:
		parts.append(AFFIXES[a["kind"]]["text"] % a["value"])
	return ", ".join(parts)

func item_power(item: Dictionary) -> float:
	return 1.0 + 0.15 * item["rarity"]

func find_item(uid: int) -> Variant:
	for it in inventory:
		if it["uid"] == uid:
			return it
	return null

func slot_of(uid: int) -> int:
	for i in slots.size():
		if slots[i] != null and slots[i]["uid"] == uid:
			return i
	return -1

func item_in_slots(type: String) -> Variant:
	for it in slots:
		if it != null and it["type"] == type:
			return it
	return null

func affix_total(kind: String) -> float:
	var total := 0.0
	for it in slots:
		if it != null:
			for a in it["affixes"]:
				if a["kind"] == kind:
					total += a["value"]
	return total

func add_item(item: Dictionary) -> bool:
	if inventory.size() >= INVENTORY_LIMIT:
		flash_text = "INVENTORY FULL"
		levelup_flash = 1.0
		return false
	inventory.append(item)
	flash_text = "GOT: %s" % item_name(item)
	levelup_flash = 1.5
	return true

# Bench actions return an empty string on success, or a message for the player.
func toggle_equip(uid: int) -> String:
	var i := slot_of(uid)
	if i >= 0:
		slots[i] = null
		return ""
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	var free := slots.find(null)
	if free < 0:
		return "Both slots are full. Unequip one first."
	slots[free] = item
	return ""

func reroll_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null or item["rarity"] == 0:
		return "Normal items have nothing to reroll."
	if receipts < REROLL_COST:
		return "Not enough receipts."
	receipts -= REROLL_COST
	item["affixes"] = _roll_affixes(item["rarity"])
	return ""

func upgrade_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	if item["rarity"] >= 2:
		return "Already Rare."
	var cost: int = UPGRADE_COSTS[item["rarity"]]
	if receipts < cost:
		return "Not enough receipts."
	receipts -= cost
	item["rarity"] += 1
	item["affixes"] = _roll_affixes(item["rarity"])
	return ""

func scrap_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	var i := slot_of(uid)
	if i >= 0:
		slots[i] = null
	inventory.erase(item)
	receipts += 1
	return ""

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

func take_damage(amount: int) -> void:
	if dead or dash_left > 0.0:
		return
	hp = maxi(hp - amount, 0)
	if hp == 0:
		dead = true
		has_target = false
		windup_left = -1.0
		model.rotation.x = -1.4

func _unhandled_input(event: InputEvent) -> void:
	if dead:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var p: Variant = _pick_point(event.position)
			if p != null:
				target = p
				has_target = true
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			use_skill()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			use_skill()
		elif event.keycode == KEY_SPACE:
			dash(_pick_point(get_viewport().get_mouse_position()))

func _pick_point(screen_pos: Vector2) -> Variant:
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if hit else null

# Skateboard dash: a quick burst toward the cursor, invulnerable while it lasts.
func dash(toward: Variant = null) -> void:
	if dead or dash_timer > 0.0 or windup_left >= 0.0:
		return
	var dir := -global_transform.basis.z
	if toward != null:
		var d: Vector3 = toward - global_position
		d.y = 0.0
		if d.length() > 0.1:
			dir = d.normalized()
	dir.y = 0.0
	dash_dir = dir.normalized()
	dash_left = dash_time
	dashed.emit()
	skill_cast.emit("SKATE DASH", "")
	dash_timer = dash_cooldown
	has_target = false
	look_at(global_position + dash_dir, Vector3.UP)

# 拆場: short windup, then a shockwave that hits every enemy in range.
func use_skill() -> void:
	if dead or skill_timer > 0.0 or windup_left >= 0.0 or dash_left > 0.0:
		return
	has_target = false
	windup_left = skill_windup + (0.2 if item_in_slots("heavy") != null else 0.0)
	var names: Array[String] = []
	for it in slots:
		if it != null:
			names.append(item_name(it).to_upper())
	skill_cast.emit("DEMOLISH", " + ".join(names))
	skill_timer = skill_cooldown * (1.0 - affix_total("cd") / 100.0)

func _slam() -> void:
	var dmg := float(skill_damage) * (1.0 + affix_total("dmg") / 100.0)
	var radius := skill_radius + affix_total("range")
	var hits := 1
	var delay := 0.0
	var heavy: Variant = item_in_slots("heavy")
	var delayed: Variant = item_in_slots("delay")
	var burst: Variant = item_in_slots("burst")
	var linger: Variant = item_in_slots("linger")
	if heavy != null:
		dmg *= 1.0 + 0.5 * item_power(heavy)
	if delayed != null:
		dmg *= 1.0 + 0.4 * item_power(delayed)
		radius += 1.0 * item_power(delayed)
		delay = 0.8 if delayed["rarity"] < 2 else 0.6
	if burst != null:
		hits = 3 if burst["rarity"] == 2 else 2
		dmg *= (0.6 if hits == 2 else 0.5) * item_power(burst)
	var center := global_position
	for h in hits:
		var t := delay + h * 0.35
		if t <= 0.0:
			_impact(center, int(dmg), radius)
		else:
			get_tree().create_timer(t, false).timeout.connect(_impact.bind(center, int(dmg), radius))
	if delay > 0.0:
		_spawn_zone(center, radius, delay, 0, Color("D6D573"))
	if linger != null:
		_spawn_zone(center, 2.0, 3.0 + 0.5 * linger["rarity"], int(8 * item_power(linger)), Color("CC6657"))

func _impact(center: Vector3, dmg: int, radius: float) -> void:
	var hit_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var away: Vector3 = enemy.global_position - center
		away.y = 0.0
		if away.length() <= radius:
			enemy.take_damage(dmg, center)
			hit_count += 1
	if hit_count > 0:
		slammed.emit(hit_count)
		_hit_stop(0.07)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("add_shake"):
			cam.add_shake(minf(0.15 + hit_count * 0.05, 0.4))
	_spawn_shockwave(center, radius)

# Brief freeze on impact: the cheap trick that makes hits feel heavy.
func _hit_stop(duration: float) -> void:
	Engine.time_scale = 0.08
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)

func _spawn_zone(center: Vector3, radius: float, life: float, damage: int, color: Color) -> void:
	var zone := Node3D.new()
	zone.set_script(ZONE)
	zone.radius = radius
	zone.life = life
	zone.damage = damage
	zone.color = color
	get_parent().add_child(zone)
	zone.global_position = Vector3(center.x, 0.04, center.z)

func _spawn_shockwave(center: Vector3, radius: float) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("CC6657")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = m
	get_parent().add_child(ring)
	ring.global_position = Vector3(center.x, 0.1, center.z)
	ring.scale = Vector3(0.3, 0.3, 0.3)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), 0.4)
	tween.tween_callback(ring.queue_free)

func _physics_process(delta: float) -> void:
	skill_timer = maxf(skill_timer - delta, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	levelup_flash = maxf(levelup_flash - delta, 0.0)
	if dead:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	var move := Vector3.ZERO
	# Hold the left mouse button to keep walking toward the cursor.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and windup_left < 0.0 and dash_left <= 0.0:
		var held: Variant = _pick_point(get_viewport().get_mouse_position())
		if held != null:
			target = held
			has_target = true
	if dash_left > 0.0:
		dash_left -= delta
		move = dash_dir * dash_speed
	elif windup_left >= 0.0:
		windup_left -= delta
		model.rotation.x = lerpf(model.rotation.x, -0.4, 0.4)
		if windup_left < 0.0:
			_slam()
	elif has_target:
		var dir := target - global_position
		dir.y = 0.0
		if dir.length() < 0.2:
			has_target = false
		else:
			move = dir.normalized() * speed
			look_at(global_position + dir, Vector3.UP)
	if windup_left < 0.0:
		model.rotation.x = lerpf(model.rotation.x, -0.25 if dash_left > 0.0 else 0.0, 0.3)
	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_animate_limbs(delta, move.length() > 0.1 and dash_left <= 0.0)

func _animate_limbs(delta: float, moving: bool) -> void:
	var swing := 0.0
	if moving:
		anim_time += delta * speed * 1.8
		swing = sin(anim_time) * 0.6
	for pair in [[leg_l, swing], [leg_r, -swing], [arm_l, -swing * 0.8], [arm_r, swing * 0.8]]:
		var limb: Node3D = pair[0]
		if limb:
			limb.rotation.x = lerpf(limb.rotation.x, pair[1], 0.4)

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
var slots := {"demolish": [null, null], "skate": [null, null]}
var next_uid := 1
var item_rolls := 0
var dash_left := 0.0
var dash_timer := 0.0
var dash_dir := Vector3.ZERO
var iframe_left := 0.0
var dash_extra := 0
var dash_extra_time := 0.0
var dash_hit: Array = []
var trail_accum := 0.0
var attack_timer := 0.0
var attack_swing := 0.0
@export var attack_cooldown := 0.55
@export var attack_damage := 9
@export var attack_radius := 2.2

@onready var model: Node3D = $Model
@onready var leg_l: Node3D = model.find_child("LegL", true, false)
@onready var leg_r: Node3D = model.find_child("LegR", true, false)
@onready var arm_l: Node3D = model.find_child("ArmL", true, false)
@onready var arm_r: Node3D = model.find_child("ArmR", true, false)

const PROGRESS := preload("res://game/scripts/progress.gd")

func _ready() -> void:
	add_to_group("player")
	_load_progress()
	hp = max_hp

# 死咗保留等級、背包、已裝配件；單據損失一半。
func save_progress(lose_half_receipts := true) -> void:
	var equipped := {}
	for cart in slots:
		equipped[cart] = slots[cart].map(func(it: Variant) -> int: return -1 if it == null else it["uid"])
	PROGRESS.data = {
		"level": level, "xp": xp, "max_hp": max_hp, "skill_damage": skill_damage,
		"receipts": int(receipts * 0.5) if lose_half_receipts else receipts,
		"inventory": inventory.duplicate(true), "equipped": equipped,
		"next_uid": next_uid, "item_rolls": item_rolls,
	}

func _load_progress() -> void:
	var d: Dictionary = PROGRESS.data
	if d.is_empty():
		return
	level = d["level"]
	xp = d["xp"]
	max_hp = d["max_hp"]
	skill_damage = d["skill_damage"]
	receipts = d["receipts"]
	inventory = d["inventory"].duplicate(true)
	next_uid = d["next_uid"]
	item_rolls = d["item_rolls"]
	for cart in slots:
		for i in slots[cart].size():
			var uid: int = d["equipped"][cart][i]
			slots[cart][i] = find_item(uid) if uid >= 0 else null

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
		flash_text = "升級！"
		levelup_flash = 1.5

const ZONE := preload("res://game/scripts/zone.gd")

# --- Cartridge attachments: random drops with rarity, equipped into 2 slots ---

const ITEM_TYPES := {
	"heavy": {"name": "重踏", "desc": "傷害提升，蓄力較慢", "cart": "demolish"},
	"burst": {"name": "迴響震擊", "desc": "連續多下攻擊", "cart": "demolish"},
	"linger": {"name": "焦土", "desc": "留下持續傷害區", "cart": "demolish"},
	"delay": {"name": "定時炸彈", "desc": "延遲爆發，範圍更闊", "cart": "demolish"},
	"knock": {"name": "重拳", "desc": "大幅擊飛", "cart": "demolish"},
	"vacuum": {"name": "黑洞", "desc": "先吸住敵人再爆", "cart": "demolish"},
	"chain": {"name": "連鎖反應", "desc": "擊殺敵人會爆炸", "cart": "demolish"},
	"frenzy": {"name": "腎上腺素", "desc": "每次命中縮短冷卻", "cart": "demolish"},
	"trail": {"name": "火焰軌跡", "desc": "衝刺後留下火焰", "cart": "skate"},
	"grind": {"name": "磨擦衝撞", "desc": "衝刺穿過敵人造成傷害", "cart": "skate"},
	"double": {"name": "雙重衝刺", "desc": "可以即刻再衝一次", "cart": "skate"},
	"ghost": {"name": "殘影", "desc": "衝刺後無敵時間更長", "cart": "skate"},
}
const RARITY_NAMES := ["普通", "魔法", "稀有"]
const RARITY_WEIGHTS := [70, 25, 5]
const AFFIXES := {
	"dmg": {"min": 8.0, "max": 18.0, "text": "傷害 +%d%%"},
	"range": {"min": 0.3, "max": 0.8, "text": "範圍 +%.1f米"},
	"cd": {"min": 5.0, "max": 12.0, "text": "冷卻 -%d%%"},
}
const INVENTORY_LIMIT := 10
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
	if item_rolls == 2:
		# 第 2 件必定係衝刺配件，方便新手發現第二張卡匣。
		types = types.filter(func(t: String) -> bool: return ITEM_TYPES[t]["cart"] == "skate")
	return make_item(types[randi() % types.size()], rarity)

func should_drop_item(from_ranged: bool) -> bool:
	item_rolls += 1
	if item_rolls <= 2:
		return true
	return randf() < (0.45 if from_ranged else 0.3)

func item_name(item: Dictionary) -> String:
	return "%s・%s" % [RARITY_NAMES[item["rarity"]], ITEM_TYPES[item["type"]]["name"]]

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

# Returns {"cart": ..., "idx": ...} for an equipped item, or an empty dictionary.
func slot_info(uid: int) -> Dictionary:
	for cart in slots:
		for i in slots[cart].size():
			var it: Variant = slots[cart][i]
			if it != null and it["uid"] == uid:
				return {"cart": cart, "idx": i}
	return {}

func item_in_slots(type: String) -> Variant:
	for cart in slots:
		for it in slots[cart]:
			if it != null and it["type"] == type:
				return it
	return null

func affix_total(kind: String, cart: String) -> float:
	var total := 0.0
	for it in slots[cart]:
		if it != null:
			for a in it["affixes"]:
				if a["kind"] == kind:
					total += a["value"]
	return total

func slot_names(cart: String) -> String:
	var names: Array[String] = []
	for it in slots[cart]:
		if it != null:
			names.append(item_name(it).to_upper())
	return " + ".join(names)

func add_item(item: Dictionary) -> bool:
	if inventory.size() >= INVENTORY_LIMIT:
		flash_text = "背包已滿"
		levelup_flash = 1.0
		return false
	inventory.append(item)
	flash_text = "獲得：%s" % item_name(item)
	levelup_flash = 1.5
	return true

# Bench actions return an empty string on success, or a message for the player.
func toggle_equip(uid: int) -> String:
	var info := slot_info(uid)
	if not info.is_empty():
		slots[info["cart"]][info["idx"]] = null
		return ""
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	var cart: String = ITEM_TYPES[item["type"]]["cart"]
	var free: int = slots[cart].find(null)
	if free < 0:
		return "此卡匣兩個槽已滿，請先拆下一個。"
	slots[cart][free] = item
	return ""

func reroll_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null or item["rarity"] == 0:
		return "普通配件沒有詞綴可重擲。"
	if receipts < REROLL_COST:
		return "單據不足。"
	receipts -= REROLL_COST
	item["affixes"] = _roll_affixes(item["rarity"])
	return ""

func upgrade_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	if item["rarity"] >= 2:
		return "已是稀有，無法再升級。"
	var cost: int = UPGRADE_COSTS[item["rarity"]]
	if receipts < cost:
		return "單據不足。"
	receipts -= cost
	item["rarity"] += 1
	item["affixes"] = _roll_affixes(item["rarity"])
	return ""

func scrap_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	var info := slot_info(uid)
	if not info.is_empty():
		slots[info["cart"]][info["idx"]] = null
	inventory.erase(item)
	receipts += 1
	return ""

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

func take_damage(amount: int) -> void:
	if dead or iframe_left > 0.0:
		return
	hp = maxi(hp - amount, 0)
	if hp == 0:
		dead = true
		save_progress()
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
	if dead or windup_left >= 0.0 or dash_left > 0.0:
		return
	var extra_ok := dash_extra > 0 and dash_extra_time > 0.0
	if dash_timer > 0.0 and not extra_ok:
		return
	var dir := -global_transform.basis.z
	if toward != null:
		var d: Vector3 = toward - global_position
		d.y = 0.0
		if d.length() > 0.1:
			dir = d.normalized()
	dir.y = 0.0
	dash_dir = dir.normalized()
	dash_left = dash_time + affix_total("range", "skate") / dash_speed
	iframe_left = dash_left
	var ghost: Variant = item_in_slots("ghost")
	if ghost != null:
		iframe_left += 0.5 * item_power(ghost)
	dash_hit.clear()
	trail_accum = 0.0
	if extra_ok:
		dash_extra -= 1
	else:
		dash_timer = dash_cooldown * (1.0 - affix_total("cd", "skate") / 100.0)
		if item_in_slots("double") != null:
			dash_extra = 1
			dash_extra_time = 0.8
	dashed.emit()
	has_target = false
	look_at(global_position + dash_dir, Vector3.UP)

# Riding effects while the dash is active (Grind Strike, Flame Trail).
func _dash_effects(delta: float) -> void:
	var grind: Variant = item_in_slots("grind")
	if grind != null:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if dash_hit.has(enemy):
				continue
			var d: Vector3 = enemy.global_position - global_position
			d.y = 0.0
			if d.length() < 1.3:
				dash_hit.append(enemy)
				var dmg := skill_damage * 0.7 * item_power(grind) * (1.0 + affix_total("dmg", "skate") / 100.0)
				enemy.take_damage(int(dmg), global_position, 9.0)
				slammed.emit(1)
				_hit_stop(0.05)
				var cam := get_viewport().get_camera_3d()
				if cam and cam.has_method("add_shake"):
					cam.add_shake(0.2)
	var trail: Variant = item_in_slots("trail")
	if trail != null:
		trail_accum += dash_speed * delta
		if trail_accum >= 1.0:
			trail_accum -= 1.0
			_spawn_zone(global_position, 1.2, 2.5, int(6 * item_power(trail) * (1.0 + affix_total("dmg", "skate") / 100.0)), Color("CC6657"))

# 拆場: short windup, then a shockwave that hits every enemy in range.
func use_skill() -> void:
	if dead or skill_timer > 0.0 or windup_left >= 0.0 or dash_left > 0.0:
		return
	has_target = false
	windup_left = skill_windup + (0.2 if item_in_slots("heavy") != null else 0.0)
	skill_cast.emit("拆場", slot_names("demolish"))
	skill_timer = skill_cooldown * (1.0 - affix_total("cd", "demolish") / 100.0)

func _slam() -> void:
	var dmg := float(skill_damage) * (1.0 + affix_total("dmg", "demolish") / 100.0)
	var radius := skill_radius + affix_total("range", "demolish")
	var hits := 1
	var delay := 0.0
	var opts := {"knock": 6.0, "vacuum": 0.0, "chain": 0.0, "frenzy": 0.0}
	var heavy: Variant = item_in_slots("heavy")
	var delayed: Variant = item_in_slots("delay")
	var burst: Variant = item_in_slots("burst")
	var linger: Variant = item_in_slots("linger")
	var knock: Variant = item_in_slots("knock")
	var vacuum: Variant = item_in_slots("vacuum")
	var chain: Variant = item_in_slots("chain")
	var frenzy: Variant = item_in_slots("frenzy")
	if heavy != null:
		dmg *= 1.0 + 0.5 * item_power(heavy)
	if delayed != null:
		dmg *= 1.0 + 0.4 * item_power(delayed)
		radius += 1.0 * item_power(delayed)
		delay = 0.8 if delayed["rarity"] < 2 else 0.6
	if burst != null:
		hits = 3 if burst["rarity"] == 2 else 2
		dmg *= (0.6 if hits == 2 else 0.5) * item_power(burst)
	if knock != null:
		opts["knock"] = 15.0 * item_power(knock)
	if vacuum != null:
		opts["vacuum"] = 2.0 * item_power(vacuum)
	if chain != null:
		opts["chain"] = dmg * 0.5 * item_power(chain)
	if frenzy != null:
		opts["frenzy"] = 0.25 * item_power(frenzy)
	var center := global_position
	for h in hits:
		var t := delay + h * 0.35
		if t <= 0.0:
			_impact(center, int(dmg), radius, opts)
		else:
			get_tree().create_timer(t, false).timeout.connect(_impact.bind(center, int(dmg), radius, opts))
	if delay > 0.0:
		_spawn_zone(center, radius, delay, 0, Color("D6D573"))
	if linger != null:
		_spawn_zone(center, 2.0, 3.0 + 0.5 * linger["rarity"], int(8 * item_power(linger)), Color("CC6657"))

func _impact(center: Vector3, dmg: int, radius: float, opts: Dictionary) -> void:
	var hit_count := 0
	var kills: Array[Vector3] = []
	var pull: float = opts["vacuum"]
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var away: Vector3 = enemy.global_position - center
		away.y = 0.0
		var dist := away.length()
		if pull > 0.0 and dist > 1.0 and dist <= radius + pull:
			enemy.global_position = Vector3(center.x, enemy.global_position.y, center.z) + away.normalized() * 1.0
			dist = 1.0
		if dist <= radius:
			enemy.take_damage(dmg, center, opts["knock"])
			hit_count += 1
			if enemy.hp <= 0:
				kills.append(enemy.global_position)
	if opts["chain"] > 0.0:
		for pos in kills:
			_explode(pos, 2.5, int(opts["chain"]))
	if opts["frenzy"] > 0.0 and hit_count > 0:
		skill_timer = maxf(skill_timer - opts["frenzy"] * hit_count, 0.0)
	if hit_count > 0:
		slammed.emit(hit_count)
		_hit_stop(0.07)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("add_shake"):
			cam.add_shake(minf(0.15 + hit_count * 0.05, 0.4))
	_spawn_shockwave(center, radius)

func _explode(pos: Vector3, radius: float, dmg: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - pos
		d.y = 0.0
		if d.length() <= radius:
			enemy.take_damage(dmg, pos, 6.0)
	_spawn_shockwave(pos, radius)

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

func _spawn_shockwave(center: Vector3, radius: float, color := Color("CC6657"), duration := 0.4) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.9
	torus.outer_radius = 1.0
	ring.mesh = torus
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring.material_override = m
	get_parent().add_child(ring)
	ring.global_position = Vector3(center.x, 0.1, center.z)
	ring.scale = Vector3(0.3, 0.3, 0.3)
	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(radius, 1.0, radius), duration)
	tween.tween_callback(ring.queue_free)

func _physics_process(delta: float) -> void:
	skill_timer = maxf(skill_timer - delta, 0.0)
	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_swing = maxf(attack_swing - delta * 5.0, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	iframe_left = maxf(iframe_left - delta, 0.0)
	dash_extra_time = maxf(dash_extra_time - delta, 0.0)
	if dash_extra_time <= 0.0:
		dash_extra = 0
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
		_dash_effects(delta)
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
	if windup_left < 0.0 and dash_left <= 0.0:
		_auto_attack()
	if windup_left < 0.0:
		model.rotation.x = lerpf(model.rotation.x, -0.25 if dash_left > 0.0 else 0.0, 0.3)
	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_animate_limbs(delta, move.length() > 0.1 and dash_left <= 0.0)

# 普通攻擊：附近有敵人就自動揮擊，細傷害、冇字卡，邊行邊打。
func _auto_attack() -> void:
	if attack_timer > 0.0:
		return
	var hit := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - global_position
		d.y = 0.0
		if d.length() <= attack_radius:
			enemy.take_damage(attack_damage, global_position, 3.0)
			hit += 1
	if hit == 0:
		return
	attack_timer = attack_cooldown
	attack_swing = 1.0
	_spawn_shockwave(global_position, attack_radius, Color("E7DFC9"), 0.18)

func _animate_limbs(delta: float, moving: bool) -> void:
	var swing := 0.0
	if moving:
		anim_time += delta * speed * 1.8
		swing = sin(anim_time) * 0.6
	for pair in [[leg_l, swing], [leg_r, -swing], [arm_l, -swing * 0.8], [arm_r, swing * 0.8 - 1.6 * attack_swing]]:
		var limb: Node3D = pair[0]
		if limb:
			limb.rotation.x = lerpf(limb.rotation.x, pair[1], 0.4)

extends CharacterBody3D

@export var speed := 6.0
@export var gravity := 20.0
@export var skill_cooldown := 1.5
@export var skill_windup := 0.3
@export var skill_radius := 3.5
@export var skill_damage := 25
@export var max_hp := 120
@export var dash_speed := 12.5
@export var dash_time := 0.3
@export var dash_cooldown := 0.25

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
var slots := {"demolish": [null, null], "skill_e": [null, null], "skill_r": [null, null], "skill_f": [null, null], "skate": [null, null], "weapon": [null], "head": [null], "body": [null], "feet": [null], "trinket": [null]}
var base_speed := 6.0
var gear_hp_bonus := 0
var next_uid := 1
const TALENTS := preload("res://game/scripts/talents.gd")
const PAINTER := preload("res://game/scripts/painter.gd")
var talents: Array = []
var talent_bonus := 0
var item_rolls := 0
var dash_left := 0.0
var dash_timer := 0.0
var dash_dir := Vector3.ZERO
var iframe_left := 0.0
var dash_hit: Array = []
var trail_accum := 0.0
var attack_timer := 0.0
var attack_swing := 0.0
# --- 手感：手動連擊（左鍵，可按住）。第 3 下為重擊。---
const COMBO_DMG := [0.7, 0.7, 1.6]
const COMBO_KNOCK := [3.0, 3.0, 10.0]
const COMBO_STOP := [0.02, 0.02, 0.07]
const COMBO_CD := [0.65, 0.65, 1.2]
const COMBO_LUNGE := [6.0, 6.0, 9.0]
const COMBO_RESET := 0.5
const ATTACK_ARC_COS := 0.17
const INPUT_BUFFER := 0.18
var atk_held := false
var atk_buffer := 0.0
var combo_step := 0
var combo_idle := 0.0
var lunge_left := 0.0
var lunge_dir := Vector3.ZERO
var lunge_speed := 0.0
var swing_left_arm := 0.0  # 1.0＝這一下用左手揮（連擊左右手交替）
var last_dash_ms := -100000
var hitstop_until := 0
var last_stop_ms := -100000
const DASH_STRIKE_WINDOW_MS := 600

@onready var model: Node3D = $Model
@onready var leg_l: Node3D = model.find_child("LegL", true, false)
@onready var leg_r: Node3D = model.find_child("LegR", true, false)
@onready var arm_l: Node3D = model.find_child("ArmL", true, false)
@onready var arm_r: Node3D = model.find_child("ArmR", true, false)

const PROGRESS := preload("res://game/scripts/progress.gd")
const SFX := preload("res://game/scripts/sfx.gd")
const FLOATY := preload("res://game/scripts/floaty.gd")
const FISHEYE := preload("res://game/scripts/fisheye.gd")
const HITFX := preload("res://game/scripts/hitfx.gd")
const GS := preload("res://game/scripts/game_settings.gd")
const SKYE_MODEL := preload("res://assets/characters/skye.glb")

var char_id := "jax"
var skill_name := "拆場"
var skill_desc := "身邊範圍震擊"
var skill_center := Vector3.ZERO
## 技能列：Q 是角色招牌技，E／R／F 是通用技，達到等級解鎖。每個技能有自己的 2 個配件槽。
const SKILL_CARTS := ["demolish", "skill_e", "skill_r", "skill_f"]
const SKILL_KEYS := {"demolish": "Q", "skill_e": "E", "skill_r": "R", "skill_f": "F"}
const EXTRA_SKILLS := {
	"skill_e": {"name": "鐵鍊旋風", "desc": "在身邊揮舞鐵鍊，連續三下範圍打擊", "unlock": 2, "cd": 4.0},
	"skill_r": {"name": "衝擊線", "desc": "朝滑鼠方向依序炸出一排爆炸", "unlock": 3, "cd": 5.0},
	"skill_f": {"name": "油門全開", "desc": "短時間大幅加快移動與普通攻擊", "unlock": 4, "cd": 14.0},
}
var extra_timers := {"skill_e": 0.0, "skill_r": 0.0, "skill_f": 0.0}
var buff_left := 0.0
var hurt_flash := 0.0
## 翻滾：資源制。2 段充能，0.3 秒無敵，每段回充 3 秒；用來救命，不是用來趕路。
const ROLL_BASE_CHARGES := 2
const ROLL_RECHARGE := 3.0
var roll_charges := ROLL_BASE_CHARGES
var roll_recharge := 0.0
## 韌性：被連續打中會踉蹌（短硬直），之後有一段免疫期，不會被無限連鎖。
const POISE_MAX := 50.0
const STAGGER_TIME := 0.5
const STAGGER_IMMUNE := 3.0
var poise := POISE_MAX
var poise_wait := 0.0
var stagger_left := 0.0
var stagger_immune := 0.0
## 格擋：按住 Shift。剛按下的 0.25 秒內被打中＝完美格擋，完全擋下並反擊。
const PERFECT_WINDOW := 0.25
var guarding := false
var guard_age := 999.0
var guard_visual := MeshInstance3D.new()
## 補給：汽水（即時回血）與便當（持續回血），擊殺敵人回充。
const FLASKS := {
	"soda": {"name": "汽水", "max": 3, "kills": 4, "desc": "即時回復 45% 生命"},
	"bento": {"name": "便當", "max": 2, "kills": 6, "desc": "6 秒內回復 40% 生命"},
}
var flask_charges := {"soda": 3, "bento": 2}
var flask_progress := {"soda": 0, "bento": 0}
var bento_left := 0.0
var regen_accum := 0.0

func _ready() -> void:
	var gbox := BoxMesh.new()
	gbox.size = Vector3(1.7, 1.5, 0.08)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.6, 0.78, 0.95, 0.35)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	guard_visual.mesh = gbox
	guard_visual.material_override = gmat
	guard_visual.position = Vector3(0, 0.9, -0.95)
	guard_visual.visible = false
	add_child(guard_visual)
	add_to_group("player")
	char_id = PROGRESS.character
	if char_id == "skye":
		_become_skye()
	PAINTER.paint(model)
	_load_progress()
	if PROGRESS.data.is_empty():
		_give_starter_weapon()
	recalc_gear()
	hp = max_hp

# 起始武器：Jax 鐵管（近戰）、Skye 手槍（遠程）；之後可以隨意換。
func _give_starter_weapon() -> void:
	var w := make_item("pipe" if char_id == "jax" else "pistol", 0)
	inventory.append(w)
	slots["weapon"][0] = w

# Skye：遠程射擊、惡作劇彈（投向滑鼠位置的範圍攻擊）。
func _become_skye() -> void:
	skill_name = "惡作劇彈"
	skill_desc = "投向滑鼠位置的範圍爆炸"
	max_hp = 90
	base_speed = 6.4
	skill_windup = 0.2
	var fresh: Node3D = SKYE_MODEL.instantiate()
	fresh.transform = model.transform
	remove_child(model)
	model.queue_free()
	add_child(fresh)
	model = fresh
	leg_l = model.find_child("LegL", true, false)
	leg_r = model.find_child("LegR", true, false)
	arm_l = model.find_child("ArmL", true, false)
	arm_r = model.find_child("ArmR", true, false)

# 死亡後保留等級、背包、已裝配件；單據損失一半。
func save_progress(lose_half_receipts := true) -> void:
	var equipped := {}
	for cart in slots:
		equipped[cart] = slots[cart].map(func(it: Variant) -> int: return -1 if it == null else it["uid"])
	PROGRESS.data = {
		"level": level, "xp": xp, "max_hp": max_hp - gear_hp_bonus, "skill_damage": skill_damage,
		"receipts": int(receipts * 0.5) if lose_half_receipts else receipts,
		"inventory": inventory.duplicate(true), "equipped": equipped,
		"next_uid": next_uid, "item_rolls": item_rolls,
		"talents": talents.duplicate(), "talent_bonus": talent_bonus,
	}
	PROGRESS.write()

func _load_progress() -> void:
	var d: Dictionary = PROGRESS.data
	if d.is_empty():
		return
	level = d["level"]
	xp = d["xp"]
	max_hp = d["max_hp"]
	gear_hp_bonus = 0
	skill_damage = d["skill_damage"]
	receipts = d["receipts"]
	inventory = d["inventory"].duplicate(true)
	next_uid = d["next_uid"]
	item_rolls = d["item_rolls"]
	talents = d.get("talents", []).duplicate()
	talent_bonus = d.get("talent_bonus", 0)
	for cart in slots:
		for i in slots[cart].size():
			var uid: int = d["equipped"].get(cart, [-1, -1])[i]
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
		SFX.play(self, "levelup")

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
	"track": {"name": "核准・追蹤", "desc": "技能會輕微追向最近的敵人", "cart": "demolish"},
	"link": {"name": "核准・連線", "desc": "標記兩個敵人，傷害部分傳導", "cart": "demolish"},
	"overload": {"name": "核准・超載", "desc": "消耗標記，對最近的敵人造成破防爆發", "cart": "demolish"},
	"trail": {"name": "火焰軌跡", "desc": "翻滾後留下火焰", "cart": "skate"},
	"grind": {"name": "磨擦衝撞", "desc": "翻滾穿過敵人造成傷害", "cart": "skate"},
	"double": {"name": "雙重翻滾", "desc": "多一段翻滾充能", "cart": "skate"},
	"ghost": {"name": "殘影", "desc": "翻滾後無敵時間更長", "cart": "skate"},
	# 裝備：任何角色都可以穿。武器決定普通攻擊的方式，其餘提供屬性。
	"pipe": {"name": "鐵管", "cart": "weapon", "kind": "melee", "dmg": 10, "cd": 0.55, "reach": 2.2},
	"gloves": {"name": "拳套", "cart": "weapon", "kind": "melee", "dmg": 6, "cd": 0.32, "reach": 1.8},
	"pistol": {"name": "手槍", "cart": "weapon", "kind": "ranged", "dmg": 7, "cd": 0.4, "reach": 9.0},
	"rifle": {"name": "步槍", "cart": "weapon", "kind": "ranged", "dmg": 13, "cd": 0.75, "reach": 11.0},
	"shotgun": {"name": "散彈槍", "cart": "weapon", "kind": "ranged", "dmg": 6, "cd": 0.9, "reach": 6.0, "pellets": 3},
	"cap": {"name": "冷帽", "cart": "head", "base": {"hp": 15, "armor": 10}},
	"goggles": {"name": "護目鏡", "cart": "head", "base": {"aspd": 10}},
	"jacket": {"name": "工裝外套", "cart": "body", "base": {"hp": 30, "armor": 20}},
	"vest": {"name": "帆布背心", "cart": "body", "base": {"sdmg": 8, "armor": 15}},
	"sneakers": {"name": "厚底板鞋", "cart": "feet", "base": {"speed": 6, "rcold": 8}},
	"springs": {"name": "彈跳鞋", "cart": "feet", "base": {"scd": 8}},
	"ironchain": {"name": "粗鎖鏈", "cart": "trinket", "base": {"sdmg": 10, "armor": 12}},
	"watch": {"name": "懷錶", "cart": "trinket", "base": {"scd": 8, "rfire": 8}},
	"charm": {"name": "幸運符", "cart": "trinket", "base": {"atk": 10, "rlight": 8}},
}
const GEAR_SLOTS := ["weapon", "head", "body", "feet", "trinket"]
const RARITY_NAMES := ["普通", "魔法", "稀有"]
const RARITY_WEIGHTS := [70, 25, 5]
const AFFIXES := {
	"dmg": {"min": 8.0, "max": 18.0, "text": "傷害 +%d%%"},
	"range": {"min": 0.3, "max": 0.8, "text": "範圍 +%.1f米"},
	"cd": {"min": 5.0, "max": 12.0, "text": "冷卻 -%d%%"},
	"hp": {"min": 8.0, "max": 20.0, "text": "生命 +%d"},
	"speed": {"min": 3.0, "max": 8.0, "text": "移速 +%d%%"},
	"atk": {"min": 8.0, "max": 20.0, "text": "普攻傷害 +%d%%"},
	"aspd": {"min": 6.0, "max": 15.0, "text": "普攻速度 +%d%%"},
	"wrange": {"min": 0.3, "max": 0.8, "text": "射程 +%.1f米"},
	"sdmg": {"min": 6.0, "max": 14.0, "text": "技能傷害 +%d%%"},
	"scd": {"min": 4.0, "max": 10.0, "text": "技能冷卻 -%d%%"},
	"armor": {"min": 10.0, "max": 28.0, "text": "護甲 +%d"},
	"rfire": {"min": 6.0, "max": 16.0, "text": "火焰抗性 +%d%%"},
	"rcold": {"min": 6.0, "max": 16.0, "text": "冰凍抗性 +%d%%"},
	"rlight": {"min": 6.0, "max": 16.0, "text": "閃電抗性 +%d%%"},
}
const POOL_ATTACH := ["dmg", "range", "cd"]
const POOL_WEAPON := ["atk", "aspd", "wrange"]
const POOL_GEAR := ["hp", "speed", "sdmg", "scd", "atk", "aspd", "armor", "rfire", "rcold", "rlight"]
const INVENTORY_LIMIT := 12
const REROLL_COST := 2
const UPGRADE_COSTS := [3, 6]

func _roll_affix(kind: String) -> Dictionary:
	var def: Dictionary = AFFIXES[kind]
	var v := randf_range(def["min"], def["max"])
	v = snappedf(v, 0.1) if kind in ["range", "wrange"] else float(roundi(v))
	return {"kind": kind, "value": v}

func is_gear(type: String) -> bool:
	return ITEM_TYPES[type]["cart"] in GEAR_SLOTS

func _roll_affixes(type: String, count: int) -> Array:
	var kinds: Array = POOL_ATTACH.duplicate()
	if is_gear(type):
		kinds = (POOL_WEAPON if ITEM_TYPES[type]["cart"] == "weapon" else POOL_GEAR).duplicate()
	kinds.shuffle()
	var out: Array = []
	for i in count:
		out.append(_roll_affix(kinds[i]))
	return out

func make_item(type: String, rarity: int) -> Dictionary:
	var item := {"uid": next_uid, "type": type, "rarity": rarity, "affixes": _roll_affixes(type, rarity)}
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
		# 第 2 件必定是翻滾配件，第 3 件必定是裝備，方便新手發現各系統。
		types = types.filter(func(t: String) -> bool: return ITEM_TYPES[t]["cart"] == "skate")
	else:
		var want_gear := item_rolls == 3 or (item_rolls != 2 and randf() < 0.4)
		types = types.filter(func(t: String) -> bool: return is_gear(t) == want_gear)
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
	var def: Dictionary = ITEM_TYPES[item["type"]]
	if def["cart"] == "weapon":
		var w := weapon_stats_of(item)
		parts.append("%s・傷害 %d・%.2f秒" % ["近戰" if def["kind"] == "melee" else "遠程", roundi(w["dmg"]), w["cd"]])
	elif def.has("base"):
		for k in def["base"]:
			var v: float = def["base"][k] * item_power(item)
			parts.append(AFFIXES[k]["text"] % (v if k == "wrange" else float(roundi(v))))
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

func item_in_slots(type: String, only_cart := "") -> Variant:
	for cart in slots:
		if only_cart != "" and cart != only_cart:
			continue
		for it in slots[cart]:
			if it != null and it["type"] == type:
				return it
	return null

# 裝備提供嘅屬性總和（基礎屬性＋詞綴）。
func gear_total(kind: String) -> float:
	var total := 0.0
	for slot in GEAR_SLOTS:
		var it: Variant = slots[slot][0]
		if it == null:
			continue
		var def: Dictionary = ITEM_TYPES[it["type"]]
		if def.has("base") and def["base"].has(kind):
			total += def["base"][kind] * item_power(it)
		for a in it["affixes"]:
			if a["kind"] == kind:
				total += a["value"]
	return total + talent_total(kind)

# --- 天賦 ---

func talent_total(kind: String) -> float:
	var total := 0.0
	for id in talents:
		var n: Dictionary = TALENTS.info(id)
		if n["stat"] == kind:
			total += n["value"]
	return total

func talent_points_total() -> int:
	return (level - 1) + talent_bonus

func talent_points_free() -> int:
	return talent_points_total() - talents.size()

func can_alloc(id: String) -> bool:
	if talents.has(id) or talent_points_free() <= 0:
		return false
	var p: String = TALENTS.parent_of(id)
	return p == "" or talents.has(p)

func alloc_talent(id: String) -> bool:
	if not can_alloc(id):
		return false
	talents.append(id)
	recalc_gear()
	return true

func respec_talents() -> bool:
	var cost: int = TALENTS.respec_cost(level)
	if talents.is_empty() or receipts < cost:
		return false
	receipts -= cost
	talents.clear()
	recalc_gear()
	return true

func poise_cap() -> float:
	return POISE_MAX + talent_total("poise")

func roll_recharge_time() -> float:
	return ROLL_RECHARGE * (1.0 - clampf((affix_total("cd", "skate") + talent_total("roll_cd")) / 100.0, 0.0, 0.8))

func weapon_stats_of(item: Variant) -> Dictionary:
	var s := {"kind": "melee", "dmg": 5.0, "cd": 0.6, "reach": 1.6, "pellets": 1}
	if item != null:
		var d: Dictionary = ITEM_TYPES[item["type"]]
		s = {"kind": d["kind"], "dmg": d["dmg"] * item_power(item), "cd": d["cd"], "reach": d["reach"], "pellets": d.get("pellets", 1)}
	return s

# 目前武器（含裝備詞綴、等級加成）。
func weapon_stats() -> Dictionary:
	var s := weapon_stats_of(slots["weapon"][0])
	s["dmg"] *= (1.0 + gear_total("atk") / 100.0) * (1.0 + 0.04 * (level - 1))
	s["cd"] /= 1.0 + gear_total("aspd") / 100.0
	s["reach"] += gear_total("wrange")
	return s

func recalc_gear() -> void:
	var bonus := roundi(gear_total("hp"))
	max_hp += bonus - gear_hp_bonus
	gear_hp_bonus = bonus
	hp = mini(hp, max_hp)
	speed = base_speed * (1.0 + gear_total("speed") / 100.0)

func affix_total(kind: String, cart: String) -> float:
	var total := 0.0
	if kind == "dmg":
		total += gear_total("sdmg")
	elif kind == "cd":
		total += gear_total("scd")
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

# 已裝上嘅裝備同技能配件不佔背包格，背包只計算未裝上的。
func bag_items() -> Array:
	return inventory.filter(func(it: Dictionary) -> bool: return slot_info(it["uid"]).is_empty())

func bag_count() -> int:
	return bag_items().size()

func add_item(item: Dictionary) -> bool:
	if bag_count() >= INVENTORY_LIMIT:
		flash_text = "背包已滿"
		levelup_flash = 1.0
		return false
	inventory.append(item)
	flash_text = "獲得：%s" % item_name(item)
	levelup_flash = 1.5
	return true

# Bench actions return an empty string on success, or a message for the player.
func toggle_equip(uid: int, skill_target := "") -> String:
	var info := slot_info(uid)
	if not info.is_empty():
		if bag_count() >= INVENTORY_LIMIT:
			return "背包已滿，先騰出空位才能拆下。"
		slots[info["cart"]][info["idx"]] = null
		SFX.play(self, "ui_click", -6.0)
		recalc_gear()
		return ""
	var item: Variant = find_item(uid)
	if item == null:
		return ""
	var cart: String = ITEM_TYPES[item["type"]]["cart"]
	if cart in GEAR_SLOTS:
		slots[cart][0] = item
		recalc_gear()
		SFX.play(self, "ui_click", -6.0)
		return ""
	# 技能配件：優先裝進指定的技能，否則裝進第一個有空槽的已解鎖技能。
	var order: Array = SKILL_CARTS if cart == "demolish" else [cart]
	if cart == "demolish" and skill_target in SKILL_CARTS:
		order = [skill_target]
	for c in order:
		if not skill_unlocked(c):
			continue
		var free: int = slots[c].find(null)
		if free >= 0:
			slots[c][free] = item
			return ""
	return "選定的技能兩個槽已滿，請先拆下一個。" if order.size() == 1 else "所有已解鎖技能的槽都滿了。"

func reroll_item(uid: int) -> String:
	var item: Variant = find_item(uid)
	if item == null or item["rarity"] == 0:
		return "普通配件沒有詞綴可重擲。"
	if receipts < REROLL_COST:
		return "單據不足。"
	receipts -= REROLL_COST
	item["affixes"] = _roll_affixes(item["type"], item["rarity"])
	recalc_gear()
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
	item["affixes"] = _roll_affixes(item["type"], item["rarity"])
	recalc_gear()
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
	recalc_gear()
	return ""

func on_kill() -> void:
	for k in FLASKS:
		if flask_charges[k] < FLASKS[k]["max"]:
			flask_progress[k] += 1
			if flask_progress[k] >= maxf(1.0, FLASKS[k]["kills"] * (1.0 - talent_total("flask_fast") / 100.0)):
				flask_progress[k] = 0
				flask_charges[k] += 1

func use_flask(kind: String) -> void:
	if dead or flask_charges[kind] <= 0 or hp >= max_hp:
		return
	flask_charges[kind] -= 1
	SFX.play(self, "pickup_hp", -4.0)
	if kind == "soda":
		heal(int(max_hp * (0.45 + talent_total("soda") / 100.0)))
	else:
		bento_left = 6.0

func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)

## 防禦：物理傷害靠護甲（減傷 = 護甲／(護甲＋10×傷害)，上限 80%），元素傷害靠對應抗性（上限 75%）。
const ELEMENT_RESIST := {"fire": "rfire", "cold": "rcold", "lightning": "rlight"}
const ELEMENT_COLORS := {"phys": Color("CC6657"), "fire": Color("E0833A"), "cold": Color("75B7E0"), "lightning": Color("E6D26A")}

func armor_value() -> float:
	return gear_total("armor")

func armor_reduction(amount: float) -> float:
	var a := armor_value()
	return clampf(a / (a + 10.0 * maxf(amount, 1.0)), 0.0, 0.8)

func resist_of(element: String) -> float:
	return clampf(gear_total(ELEMENT_RESIST[element]), 0.0, 75.0) if ELEMENT_RESIST.has(element) else 0.0

func take_damage(amount: int, element := "phys", source: Node = null) -> void:
	if dead or iframe_left > 0.0:
		return
	var raw := float(amount)
	var blocked := false
	if guarding and _guard_covers(source):
		if guard_age <= PERFECT_WINDOW + talent_total("perfect"):
			_perfect_block(source)
			return
		blocked = true
	if element == "phys":
		amount = maxi(1, roundi(amount * (1.0 - armor_reduction(amount))))
	else:
		amount = maxi(1, roundi(amount * (1.0 - resist_of(element) / 100.0)))
	if blocked:
		amount = maxi(1, roundi(amount * 0.3))
	hp = maxi(hp - amount, 0)
	var col: Color = ELEMENT_COLORS.get(element, Color("CC6657"))
	FLOATY.spawn(get_parent(), global_position + Vector3(0, 2.0, 0), ("擋 " if blocked else "") + str(amount), Color("9AA3AD") if blocked else col, not blocked)
	hurt_flash = 0.2 if blocked else 0.4
	HITFX.sparks(get_parent(), global_position + Vector3(0, 1.0, 0), Color("9FB6E8") if blocked else col, 6 if blocked else 10, 1.0 if blocked else 1.2)
	HITFX.shake(self, 0.12 if blocked else 0.3)
	SFX.play(self, "death" if hp == 0 else ("hit" if blocked else "hurt"), -3.0)
	_take_poise(raw * (0.4 if blocked else 1.0))
	if hp == 0:
		dead = true
		save_progress()
		has_target = false
		windup_left = -1.0
		model.rotation.x = -1.4

# 韌性：累積到 0 就踉蹌一下（短硬直），之後 3 秒內不會再被打到踉蹌。
func _take_poise(amount: float) -> void:
	poise_wait = 1.5
	if stagger_immune > 0.0 or stagger_left > 0.0:
		return
	poise -= amount
	if poise <= 0.0:
		poise = poise_cap()
		stagger_left = STAGGER_TIME
		stagger_immune = STAGGER_TIME + STAGGER_IMMUNE + talent_total("stagger_immune")
		windup_left = -1.0
		FLOATY.spawn(get_parent(), global_position + Vector3(0, 2.6, 0), "踉蹌", Color("E6D26A"), true)

# 格擋只擋前方；沒有來源（例如飛彈）一律擋得到。
func _guard_covers(source: Node) -> bool:
	if source == null or not (source is Node3D):
		return true
	var to: Vector3 = (source as Node3D).global_position - global_position
	to.y = 0.0
	if to.length() < 0.01:
		return true
	return (-global_transform.basis.z).angle_to(to.normalized()) <= deg_to_rad(80.0)

func _perfect_block(source: Node) -> void:
	FLOATY.spawn(get_parent(), global_position + Vector3(0, 2.4, 0), "完美格擋", Color("E6D26A"), true)
	HITFX.sparks(get_parent(), global_position + Vector3(0, 1.2, 0) - global_transform.basis.z * 0.8, Color("E6D26A"), 16, 1.6)
	HITFX.shake(self, 0.2)
	HITFX.hit_stop(get_tree(), 0.06)
	SFX.play(self, "slam", -4.0)
	if source != null and is_instance_valid(source) and source.has_method("take_damage"):
		source.take_damage(int(skill_damage * 0.6), global_position, 8.0, true)
		if source.has_method("poise_damage"):
			source.poise_damage(60.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		atk_held = false

func _unhandled_input(event: InputEvent) -> void:
	if dead:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			atk_held = true
			atk_buffer = INPUT_BUFFER
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			use_skill()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			use_skill()
		elif event.keycode == KEY_E:
			use_extra("skill_e")
		elif event.keycode == KEY_R:
			use_extra("skill_r")
		elif event.keycode == KEY_F:
			use_extra("skill_f")
		elif event.keycode == KEY_F3:
			_toggle_debug()
		elif event.keycode == KEY_1:
			use_flask("soda")
		elif event.keycode == KEY_2:
			use_flask("bento")
		elif event.keycode == KEY_SPACE:
			# 有按方向鍵就朝該方向翻滾，否則朝滑鼠位置。
			var wasd := _move_input()
			if wasd != Vector3.ZERO:
				dash(global_position + wasd)
			else:
				dash(_pick_point(get_viewport().get_mouse_position()))

# WASD（或方向鍵）移動：W＝畫面上方（鏡頭斜 45 度，所以世界方向跟鏡頭轉）。
func _move_input() -> Vector3:
	var v := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		v.z -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		v.z += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		v.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		v.x += 1.0
	var cam := get_viewport().get_camera_3d()
	if cam:
		v = Basis(Vector3.UP, cam.global_rotation.y) * v
	return v.normalized()

func _pick_point(screen_pos: Vector2) -> Variant:
	screen_pos = FISHEYE.warp_pos(screen_pos, get_viewport().get_visible_rect().size)
	var camera := get_viewport().get_camera_3d()
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if hit else null

# Skateboard dash: a quick burst toward the cursor, invulnerable while it lasts.
func dash(toward: Variant = null) -> void:
	if dead or windup_left >= 0.0 or dash_left > 0.0 or roll_charges <= 0 or dash_timer > 0.0:
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
	iframe_left = maxf(dash_left, 0.3)
	var ghost: Variant = item_in_slots("ghost")
	if ghost != null:
		iframe_left += 0.4 * item_power(ghost)
	dash_hit.clear()
	trail_accum = 0.0
	if roll_charges >= roll_max():
		roll_recharge = roll_recharge_time()
	roll_charges -= 1
	dash_timer = dash_cooldown
	stagger_left = 0.0
	last_dash_ms = Time.get_ticks_msec()
	dashed.emit()
	SFX.play(self, "dash", -4.0)
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
				enemy.take_damage(int(dmg), global_position, 9.0, true)
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
func roll_max() -> int:
	var extra := 0
	for it in slots["skate"]:
		if it != null and it["type"] == "double":
			extra += 1
	return ROLL_BASE_CHARGES + extra + int(talent_total("roll_charge"))

func skill_unlocked(cart: String) -> bool:
	return not EXTRA_SKILLS.has(cart) or level >= EXTRA_SKILLS[cart]["unlock"]

func skill_name_of(cart: String) -> String:
	return skill_name if cart == "demolish" else EXTRA_SKILLS[cart]["name"]

func skill_timer_of(cart: String) -> float:
	return skill_timer if cart == "demolish" else extra_timers[cart]

func _reduce_cd(cart: String, amount: float) -> void:
	if cart == "demolish":
		skill_timer = maxf(skill_timer - amount, 0.0)
	else:
		extra_timers[cart] = maxf(extra_timers[cart] - amount, 0.0)

# E／R／F：通用技能，即時施放。
func use_extra(cart: String) -> void:
	var def: Dictionary = EXTRA_SKILLS[cart]
	if dead or not skill_unlocked(cart) or extra_timers[cart] > 0.0 or dash_left > 0.0 or windup_left >= 0.0 or stagger_left > 0.0 or guarding:
		return
	var cd: float = def["cd"] * (1.0 - affix_total("cd", cart) / 100.0)
	extra_timers[cart] = cd
	match cart:
		"skill_e":
			SFX.play(self, "slam", -3.0)
			_run_skill(cart, [global_position], 0.5, 3.0, 3, 0.3)
		"skill_r":
			var p: Variant = _pick_point(get_viewport().get_mouse_position())
			var aim: Vector3 = p if p != null else global_position - global_transform.basis.z * 6.0
			var dir := aim - global_position
			dir.y = 0.0
			dir = dir.normalized() if dir.length() > 0.1 else -global_transform.basis.z
			look_at(global_position + dir, Vector3.UP)
			var centers: Array = []
			for i in 4:
				centers.append(global_position + dir * (2.0 + 2.2 * i))
			SFX.play(self, "slam", -3.0)
			_run_skill(cart, centers, 0.9, 1.6, 1, 0.0)
		"skill_f":
			buff_left = 5.0 + affix_total("range", cart) * 3.0
			SFX.play(self, "pickup_item", -2.0)
			flash_text = "油門全開！"
			levelup_flash = 1.2

func use_skill() -> void:
	if dead or skill_timer > 0.0 or windup_left >= 0.0 or dash_left > 0.0 or stagger_left > 0.0 or guarding:
		return
	has_target = false
	if char_id == "skye":
		var p: Variant = _pick_point(get_viewport().get_mouse_position())
		var aim: Vector3 = p if p != null else global_position - global_transform.basis.z * 6.0
		var off := aim - global_position
		off.y = 0.0
		if off.length() > 9.0:
			off = off.normalized() * 9.0
		skill_center = global_position + off
		if off.length() > 0.1:
			look_at(global_position + off, Vector3.UP)
	windup_left = skill_windup + (0.2 if item_in_slots("heavy", "demolish") != null else 0.0)
	skill_cast.emit(skill_name, slot_names("demolish"))
	SFX.play(self, "windup", -6.0)
	skill_timer = skill_cooldown * (1.0 - affix_total("cd", "demolish") / 100.0)

func _slam() -> void:
	SFX.play(self, "slam")
	var center := skill_center if char_id == "skye" else global_position
	_run_skill("demolish", [center], 1.0, skill_radius, 1, 0.35)

# 通用的傷害技能：依該技能槽內的配件決定傷害、範圍、連擊、延遲與附加效果。
func _run_skill(cart: String, centers: Array, dmg_mult: float, radius_base: float, hits_base: int, tick: float) -> void:
	var dmg := float(skill_damage) * dmg_mult * (1.0 + affix_total("dmg", cart) / 100.0)
	var radius := radius_base + affix_total("range", cart)
	var hits := hits_base
	var delay := 0.0
	var opts := {"knock": 6.0, "vacuum": 0.0, "chain": 0.0, "frenzy": 0.0, "cd_key": cart, "link": 0.0, "overload": 0.0}
	var heavy: Variant = item_in_slots("heavy", cart)
	var delayed: Variant = item_in_slots("delay", cart)
	var burst: Variant = item_in_slots("burst", cart)
	var linger: Variant = item_in_slots("linger", cart)
	var knock: Variant = item_in_slots("knock", cart)
	var vacuum: Variant = item_in_slots("vacuum", cart)
	var chain: Variant = item_in_slots("chain", cart)
	var frenzy: Variant = item_in_slots("frenzy", cart)
	var track: Variant = item_in_slots("track", cart)
	var link: Variant = item_in_slots("link", cart)
	var overload: Variant = item_in_slots("overload", cart)
	if heavy != null:
		dmg *= 1.0 + 0.5 * item_power(heavy)
	if delayed != null:
		dmg *= 1.0 + 0.4 * item_power(delayed)
		radius += 1.0 * item_power(delayed)
		delay = 0.8 if delayed["rarity"] < 2 else 0.6
	if burst != null:
		var extra := 3 if burst["rarity"] == 2 else 2
		hits = hits_base * extra
		dmg *= (0.6 if extra == 2 else 0.5) * item_power(burst)
	if knock != null:
		opts["knock"] = 15.0 * item_power(knock)
	if vacuum != null:
		opts["vacuum"] = 2.0 * item_power(vacuum)
	if chain != null:
		opts["chain"] = dmg * 0.5 * item_power(chain)
	if frenzy != null:
		opts["frenzy"] = 0.25 * item_power(frenzy)
	if link != null:
		opts["link"] = 0.5 * item_power(link)
	if overload != null:
		opts["overload"] = 0.6 * item_power(overload)
	for ci in centers.size():
		var center: Vector3 = centers[ci]
		if track != null:
			# 核准模組・追蹤：技能中心向最近的敵人偏移一小段
			var nearest := _nearest_enemy(center, radius + 4.0)
			if nearest != null:
				var pull: Vector3 = nearest.global_position - center
				pull.y = 0.0
				center += pull.limit_length(1.5 * item_power(track))
		for h in hits:
			var t := delay + h * maxf(tick, 0.2 if hits > 1 else 0.0) + ci * 0.09
			if t <= 0.0:
				_impact(center, int(dmg), radius, opts)
			else:
				get_tree().create_timer(t, false).timeout.connect(_impact.bind(center, int(dmg), radius, opts))
		if delay > 0.0:
			_spawn_zone(center, radius, delay, 0, Color("D6D573"))
		if linger != null:
			_spawn_zone(center, 2.0, 3.0 + 0.5 * linger["rarity"], int(8 * item_power(linger)), Color("CC6657"))

func _nearest_enemy(from: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - from
		d.y = 0.0
		if d.length() < best_d:
			best_d = d.length()
			best = enemy
	return best

func _impact(center: Vector3, dmg: int, radius: float, opts: Dictionary) -> void:
	var hit_count := 0
	var kills: Array[Vector3] = []
	var pull: float = opts["vacuum"]
	# 核准模組：連線標記離中心最近的兩個敵人；超載對最近的敵人造成破防爆發。
	var marked: Array = []
	if opts["link"] > 0.0 or opts["overload"] > 0.0:
		var near: Array = get_tree().get_nodes_in_group("enemies").filter(func(e: Node3D) -> bool: return e.global_position.distance_to(center) <= radius + 3.0)
		near.sort_custom(func(a: Node3D, b: Node3D) -> bool: return a.global_position.distance_to(center) < b.global_position.distance_to(center))
		marked = near.slice(0, 2)
	if opts["overload"] > 0.0 and not marked.is_empty():
		var focus: Node3D = marked[0]
		focus.take_damage(int(dmg * opts["overload"]), center, 12.0, true)
		if "cooldown" in focus:
			focus.cooldown = 2.0
	if opts["link"] > 0.0 and marked.size() == 2:
		marked[0].take_damage(int(dmg * opts["link"]), center, 2.0)
		marked[1].take_damage(int(dmg * opts["link"]), center, 2.0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var away: Vector3 = enemy.global_position - center
		away.y = 0.0
		var dist := away.length()
		if pull > 0.0 and dist > 1.0 and dist <= radius + pull:
			enemy.global_position = Vector3(center.x, enemy.global_position.y, center.z) + away.normalized() * 1.0
			dist = 1.0
		if dist <= radius:
			enemy.take_damage(dmg, center, opts["knock"], true)
			hit_count += 1
			if enemy.hp <= 0:
				kills.append(enemy.global_position)
	if opts["chain"] > 0.0:
		for pos in kills:
			_explode(pos, 2.5, int(opts["chain"]))
	if opts["frenzy"] > 0.0 and hit_count > 0:
		_reduce_cd(opts["cd_key"], opts["frenzy"] * hit_count)
	if hit_count > 0:
		slammed.emit(hit_count)
		_hit_stop(0.07)
		var cam := get_viewport().get_camera_3d()
		if cam and cam.has_method("add_shake"):
			cam.add_shake(minf(0.15 + hit_count * 0.05, 0.4))
	HITFX.sparks(get_parent(), center + Vector3(0, 0.3, 0), Color("E6D26A"), 14 + mini(hit_count * 2, 14), 1.8)
	_spawn_shockwave(center, radius)

func _explode(pos: Vector3, radius: float, dmg: int) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - pos
		d.y = 0.0
		if d.length() <= radius:
			enemy.take_damage(dmg, pos, 6.0, true)
	_spawn_shockwave(pos, radius)

# Brief freeze on impact: the cheap trick that makes hits feel heavy.
func _hit_stop(duration: float) -> void:
	if GS.v["hit_stop"] == 0:
		return  # 設定頁關閉頓幀
	# 頓幀太密會變成「慢動作」：兩次頓幀之間至少相隔 0.25 秒，並避免與敵人自身的頓幀重疊。
	var now := Time.get_ticks_msec()
	if HITFX.stopping or now - last_stop_ms < 250:
		return
	last_stop_ms = now
	hitstop_until = now + int(duration * 1000.0)
	Engine.time_scale = 0.12
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if Time.get_ticks_msec() >= hitstop_until and not HITFX.stopping:
			Engine.time_scale = 1.0)

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

# 安全網：任何頓幀都不應持續超過 0.5 秒；若時間縮放卡在慢速，強制還原。
func _watch_time_scale() -> void:
	if Engine.time_scale >= 1.0:
		return
	var now := Time.get_ticks_msec()
	if now > hitstop_until + 400 and now > HITFX.last_stop + 600:
		Engine.time_scale = 1.0

# F3：顯示 FPS 與時間縮放，用來分辨「慢動作」是掉幀還是時間縮放。
var _dbg_layer: CanvasLayer = null
var _dbg_label: Label = null

func _toggle_debug() -> void:
	if _dbg_layer != null:
		_dbg_layer.queue_free()
		_dbg_layer = null
		_dbg_label = null
		return
	_dbg_layer = CanvasLayer.new()
	_dbg_label = Label.new()
	_dbg_label.position = Vector2(8, 8)
	_dbg_label.add_theme_font_size_override("font_size", 18)
	_dbg_label.add_theme_color_override("font_color", Color("E6D26A"))
	_dbg_layer.add_child(_dbg_label)
	add_child(_dbg_layer)

func _update_debug() -> void:
	if _dbg_label != null:
		_dbg_label.text = "FPS %d　時間縮放 %.2f　敵人 %d" % [Engine.get_frames_per_second(), Engine.time_scale, get_tree().get_nodes_in_group("enemies").size()]

func _physics_process(delta: float) -> void:
	_watch_time_scale()
	_update_debug()
	skill_timer = maxf(skill_timer - delta, 0.0)
	for k in extra_timers:
		extra_timers[k] = maxf(extra_timers[k] - delta, 0.0)
	buff_left = maxf(buff_left - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)
	if bento_left > 0.0 and not dead:
		bento_left -= delta
		regen_accum += max_hp * 0.4 / 6.0 * delta
		if regen_accum >= 1.0:
			heal(int(regen_accum))
			regen_accum -= int(regen_accum)
	attack_timer = maxf(attack_timer - delta * (1.3 if buff_left > 0.0 else 1.0), 0.0)
	attack_swing = maxf(attack_swing - delta * 5.0, 0.0)
	dash_timer = maxf(dash_timer - delta, 0.0)
	iframe_left = maxf(iframe_left - delta, 0.0)
	var rmax := roll_max()
	if roll_charges < rmax:
		roll_recharge -= delta
		if roll_recharge <= 0.0:
			roll_charges += 1
			roll_recharge = roll_recharge_time() if roll_charges < rmax else 0.0
	roll_charges = mini(roll_charges, rmax)
	poise_wait = maxf(poise_wait - delta, 0.0)
	if poise_wait <= 0.0 and poise < poise_cap():
		poise = minf(poise + 15.0 * delta, poise_cap())
	stagger_left = maxf(stagger_left - delta, 0.0)
	stagger_immune = maxf(stagger_immune - delta, 0.0)
	levelup_flash = maxf(levelup_flash - delta, 0.0)
	if dead:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return
	var move := Vector3.ZERO
	var want_guard := Input.is_key_pressed(KEY_SHIFT) and dash_left <= 0.0 and windup_left < 0.0 and stagger_left <= 0.0
	if want_guard and not guarding:
		guard_age = 0.0
	guarding = want_guard
	guard_age = guard_age + delta if guarding else 999.0
	guard_visual.visible = guarding
	if guarding:
		var gp: Variant = _pick_point(get_viewport().get_mouse_position())
		if gp != null:
			var gd: Vector3 = gp - global_position
			gd.y = 0.0
			if gd.length() > 0.2:
				look_at(global_position + gd, Vector3.UP)
	atk_buffer = maxf(atk_buffer - delta, 0.0)
	lunge_left = maxf(lunge_left - delta, 0.0)
	combo_idle += delta
	if combo_idle > COMBO_RESET:
		combo_step = 0
	if dash_left > 0.0:
		dash_left -= delta
		move = dash_dir * dash_speed
		lunge_left = 0.0
		_dash_effects(delta)
	elif stagger_left > 0.0:
		model.rotation.x = lerpf(model.rotation.x, 0.5, 0.4)
	elif windup_left >= 0.0:
		windup_left -= delta
		model.rotation.x = lerpf(model.rotation.x, -0.4, 0.4)
		if windup_left < 0.0:
			_slam()
	else:
		var dir := _move_input()
		if dir != Vector3.ZERO:
			move = dir * speed * (1.4 if buff_left > 0.0 else 1.0) * (0.4 if guarding else 1.0)
			if not guarding:
				look_at(global_position + dir, Vector3.UP)
		if atk_held or atk_buffer > 0.0:
			move *= 0.65  # 出手時略微減速，增加重量感
			if not guarding:
				look_at(global_position + _aim_dir(), Vector3.UP)  # 出手時面向滑鼠
		if lunge_left > 0.0:
			move += lunge_dir * lunge_speed
	if windup_left < 0.0 and dash_left <= 0.0 and stagger_left <= 0.0 and not guarding:
		_manual_attack()
	if windup_left < 0.0:
		# 揮擊時身體向前傾，收招後彈回
		model.rotation.x = lerpf(model.rotation.x, -0.25 if dash_left > 0.0 else -0.3 * attack_swing, 0.3)
	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
	_animate_limbs(delta, move.length() > 0.1 and dash_left <= 0.0)

# 滑鼠所指方向（水平）。
func _aim_dir() -> Vector3:
	var p: Variant = _pick_point(get_viewport().get_mouse_position())
	if p != null:
		var d: Vector3 = p - global_position
		d.y = 0.0
		if d.length() > 0.2:
			return d.normalized()
	var f := -global_transform.basis.z
	f.y = 0.0
	return f.normalized()

# 普通攻擊：手動（左鍵可按住），朝滑鼠方向；有緩衝，收招後立即接下一下。
func _manual_attack() -> void:
	if attack_timer > 0.0 or not (atk_held or atk_buffer > 0.0):
		return
	atk_buffer = 0.0
	var aim := _aim_dir()
	look_at(global_position + aim, Vector3.UP)
	var w := weapon_stats()
	if w["kind"] == "ranged":
		_shoot_aimed(w, aim)
	else:
		aim = _assist_aim(aim, w["reach"])
		look_at(global_position + aim, Vector3.UP)
		_melee_swing(w, aim)

# 輕度瞄準輔助（《哈迪斯》式）：滑鼠方向約 45 度內有敵人，就把出手方向拉向最近的那個。
func _assist_aim(aim: Vector3, reach: float) -> Vector3:
	var best: Node3D = null
	var best_dist := reach * 1.5
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - global_position
		d.y = 0.0
		var dist := d.length()
		if dist < 0.3 or dist > best_dist:
			continue
		if aim.dot(d / dist) < 0.7:
			continue
		best = enemy
		best_dist = dist
	if best == null:
		return aim
	var toward: Vector3 = best.global_position - global_position
	toward.y = 0.0
	return (aim * 0.35 + toward.normalized() * 0.65).normalized()

# 揮擊弧光：扇形白光，標示實際判定範圍；重擊與衝刺斬為暖黃色。
var _arc_mesh: ArrayMesh = null

func _get_arc_mesh() -> ArrayMesh:
	if _arc_mesh != null:
		return _arc_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 14
	var half := deg_to_rad(52.0)
	for i in n:
		var a0 := lerpf(-half, half, float(i) / n)
		var a1 := lerpf(-half, half, float(i + 1) / n)
		st.add_vertex(Vector3.ZERO)
		st.add_vertex(Vector3(sin(a0), 0.0, -cos(a0)))
		st.add_vertex(Vector3(sin(a1), 0.0, -cos(a1)))
	_arc_mesh = st.commit()
	return _arc_mesh

# 弧光節點用「物件池」重複使用，不再每下攻擊新建節點與材質（減少卡頓）。
var _slash_pool: Array = []
var _slash_next := 0
const SLASH_POOL_SIZE := 4

func _make_slash_node() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _get_arc_mesh()
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.55)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.visible = false
	get_parent().add_child(mi)
	return mi

func _spawn_slash(aim: Vector3, reach: float, heavy: bool) -> void:
	if _slash_pool.is_empty():
		for k in SLASH_POOL_SIZE:
			_slash_pool.append(_make_slash_node())
	var mi: MeshInstance3D = _slash_pool[_slash_next]
	_slash_next = (_slash_next + 1) % SLASH_POOL_SIZE
	var m: StandardMaterial3D = mi.material_override
	var col := Color("E6D26A") if heavy else Color("F4F0E4")
	col.a = 0.55
	m.albedo_color = col
	mi.global_position = global_position + Vector3(0, 0.5, 0)
	mi.look_at(mi.global_position + aim, Vector3.UP)
	mi.scale = Vector3(reach * 0.6, 1.0, reach * 0.6)
	mi.visible = true
	if mi.has_meta("tw"):
		var old: Variant = mi.get_meta("tw")
		if old is Tween and old.is_valid():
			old.kill()
	var tw := mi.create_tween().set_parallel(true)
	mi.set_meta("tw", tw)
	tw.tween_property(mi, "scale", Vector3(reach, 1.0, reach), 0.14)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.14)
	tw.chain().tween_callback(func() -> void: mi.visible = false)

func _melee_swing(w: Dictionary, aim: Vector3) -> void:
	var step := combo_step
	var hit := 0
	var kills := 0
	# 衝刺後立即出手＝衝刺斬：更遠前衝、傷害 +30%。
	var dash_strike := Time.get_ticks_msec() - last_dash_ms < DASH_STRIKE_WINDOW_MS
	var dmg := roundi(w["dmg"] * COMBO_DMG[step] * (1.3 if dash_strike else 1.0))
	var reach: float = w["reach"] * (1.25 if step == 2 else 1.0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - global_position
		d.y = 0.0
		var dist := d.length()
		if dist > reach:
			continue
		if dist > 0.6 and aim.dot(d / dist) < ATTACK_ARC_COS:
			continue
		enemy.take_damage(dmg, global_position, COMBO_KNOCK[step], step == 2)  # 第 3 下為重擊：破甲、削韌性
		hit += 1
		if enemy.hp <= 0:
			kills += 1
	attack_timer = w["cd"] * COMBO_CD[step]
	attack_swing = 1.0
	swing_left_arm = 1.0 if step == 1 else 0.0
	lunge_dir = aim
	lunge_speed = COMBO_LUNGE[step] * (1.8 if dash_strike else 1.0)
	lunge_left = 0.12 if dash_strike else 0.08
	combo_idle = 0.0
	SFX.play(self, "hit" if hit > 0 else "dash", -8.0, 0.12)
	_spawn_slash(aim, reach, step == 2 or dash_strike)
	if hit > 0:
		_hit_stop(COMBO_STOP[step] + 0.02 * kills)
		# 每個命中的敵人本身已有火花與輕震；這裡只為重擊與衝刺斬額外加強，並遵從設定頁的震動倍率。
		if step == 2 or dash_strike:
			HITFX.shake(self, 0.14)
			var cam := get_viewport().get_camera_3d()
			if cam and cam.has_method("add_kick"):
				cam.add_kick(aim, 0.3 * GS.SHAKE_MULT[GS.v["shake"]])
	combo_step = (step + 1) % COMBO_DMG.size()

func _shoot_aimed(w: Dictionary, aim: Vector3) -> void:
	var targets: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var d: Vector3 = enemy.global_position - global_position
		d.y = 0.0
		var dist := d.length()
		if dist <= w["reach"] and dist > 0.1 and aim.dot(d / dist) > 0.9:
			targets.append([dist, enemy])
	targets.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	attack_timer = w["cd"]
	attack_swing = 1.0
	swing_left_arm = 0.0
	SFX.play(self, "shoot", -8.0, 0.1)
	var origin := global_position + Vector3(0, 0.9, 0)
	if targets.is_empty():
		_tracer(origin, origin + aim * w["reach"])
		return
	for i in mini(w["pellets"], targets.size()):
		var enemy: Node3D = targets[i][1]
		enemy.take_damage(roundi(w["dmg"]), global_position, 2.0)
		_tracer(origin, enemy.global_position + Vector3(0, 0.8, 0))
	_hit_stop(0.03)

func _tracer(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.05, 0.05, a.distance_to(b))
	mi.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("D6D573")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	get_parent().add_child(mi)
	mi.global_position = (a + b) / 2.0
	mi.look_at(b, Vector3.UP)
	get_tree().create_timer(0.07).timeout.connect(mi.queue_free)
	HITFX.sparks(get_parent(), a, Color("F4E27A"), 4, 0.8)
	HITFX.shake(self, 0.03)

func _animate_limbs(delta: float, moving: bool) -> void:
	var swing := 0.0
	if moving:
		anim_time += delta * speed * 1.8
		swing = sin(anim_time) * 0.6
	for pair in [[leg_l, swing], [leg_r, -swing], [arm_l, -swing * 0.8 - 1.6 * attack_swing * swing_left_arm], [arm_r, swing * 0.8 - 1.6 * attack_swing * (1.0 - swing_left_arm)]]:
		var limb: Node3D = pair[0]
		if limb:
			limb.rotation.x = lerpf(limb.rotation.x, pair[1], 0.4)

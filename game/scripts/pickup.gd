extends Node3D
## Loot dropped by enemies. kind: "xp" (mint), "hp" (coral) or "receipt" (chalk white, the currency) or "item" (a random cartridge attachment, coloured by rarity). Walk close to collect.

const SFX := preload("res://game/scripts/sfx.gd")

var kind := "xp"
var item := {}
var value := 10
var age := 0.0
var full_msg_timer := 0.0
var blocked_now := false
var pulled := false

const MAGNET_RANGE := 4.0
const COLLECT_RANGE := 0.9

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.35, 0.35)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = {"xp": Color("75C7B0"), "hp": Color("CC6657"), "receipt": Color("E7DFC9")}.get(kind, Color("F4F0E4"))
	if kind == "item":
		# 物品：地上一根光柱加小菱形，名稱由 loot_labels.gd 顯示成名牌。
		var col: Color = [Color("F4F0E4"), Color("9FB6E8"), Color("D6D573")][item["rarity"]]
		m.albedo_color = col
		bm.size = Vector3(0.3, 0.3, 0.3)
		var beam := MeshInstance3D.new()
		var bb := BoxMesh.new()
		bb.size = Vector3(0.07, 3.0, 0.07)
		beam.mesh = bb
		var bm2 := StandardMaterial3D.new()
		bm2.albedo_color = Color(col.r, col.g, col.b, 0.55)
		bm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		beam.material_override = bm2
		beam.position.y = 1.5
		add_child(beam)
		add_to_group("item_pickups")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)
	rotation.y = randf() * TAU

func _process(delta: float) -> void:
	age += delta
	rotation.y += delta * 2.0
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var to: Vector3 = player.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	# 背包已滿時，物品留在原地，不會追著玩家；騰出空位再撿。
	var blocked: bool = kind == "item" and player.bag_count() >= player.INVENTORY_LIMIT
	blocked_now = blocked
	if blocked:
		full_msg_timer = maxf(full_msg_timer - delta, 0.0)
		if dist < COLLECT_RANGE and full_msg_timer <= 0.0:
			full_msg_timer = 2.0
			player.flash_text = "背包已滿，請先在工作枱（C）拆解物品"
			player.levelup_flash = 1.5
		return
	if dist < COLLECT_RANGE:
		match kind:
			"xp":
				player.gain_xp(value)
				SFX.play(self, "pickup_xp", -10.0, 0.15)
			"hp":
				player.heal(value)
				SFX.play(self, "pickup_hp", -4.0)
			"receipt":
				player.receipts += value
				SFX.play(self, "pickup_receipt", -6.0)
			"item":
				if not player.add_item(item):
					return
				SFX.play(self, "pickup_item")
		queue_free()
	elif (dist < MAGNET_RANGE and age > 0.4) or pulled:
		global_position += to.normalized() * (14.0 if pulled else 9.0) * delta

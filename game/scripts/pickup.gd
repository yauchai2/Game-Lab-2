extends Node3D
## Loot dropped by enemies. kind: "xp" (mint), "hp" (coral) or "receipt" (chalk white, the currency) or "item" (a random cartridge attachment, coloured by rarity). Walk close to collect.

var kind := "xp"
var item := {}
var value := 10
var age := 0.0

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
		m.albedo_color = [Color("F4F0E4"), Color("9FB6E8"), Color("D6D573")][item["rarity"]]
		bm.size = Vector3(0.55, 0.55, 0.55)
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
	if dist < COLLECT_RANGE:
		match kind:
			"xp":
				player.gain_xp(value)
			"hp":
				player.heal(value)
			"receipt":
				player.receipts += value
			"item":
				if not player.add_item(item):
					return
		queue_free()
	elif dist < MAGNET_RANGE and age > 0.4:
		global_position += to.normalized() * 9.0 * delta

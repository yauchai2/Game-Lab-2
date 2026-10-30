extends Node3D
## Loot dropped by enemies. kind: "xp" (mint gem) or "hp" (coral orb). Walk close to collect.

var kind := "xp"
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
	m.albedo_color = Color("75C7B0") if kind == "xp" else Color("CC6657")
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
		if kind == "xp":
			player.gain_xp(value)
		else:
			player.heal(value)
		queue_free()
	elif dist < MAGNET_RANGE and age > 0.4:
		global_position += to.normalized() * 9.0 * delta

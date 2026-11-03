extends Node3D
## Simple enemy bolt: flies straight, hurts the player on contact.

var direction := Vector3.FORWARD
var speed := 10.0
var damage := 6
var life := 3.0
var element := "phys"
const COLORS := {"phys": Color("F2F2F2"), "fire": Color("F2F2F2"), "cold": Color("F2F2F2"), "lightning": Color("F2F2F2")}

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.3, 0.3)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = COLORS.get(element, Color("F2F2F2"))
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	global_position += direction * speed * delta
	rotation.y += delta * 8.0
	var player := get_tree().get_first_node_in_group("player")
	if player and not player.dead:
		var d: Vector3 = player.global_position - global_position
		d.y = 0.0
		if d.length() < 0.8:
			player.take_damage(damage, element)
			queue_free()

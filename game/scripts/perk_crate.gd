extends Node3D
## One of three perk crates offered on a style rank-up. Touch one to take it; the others vanish.

var perk_id := "damage"
var label_text := ""
var life := 10.0

func _ready() -> void:
	add_to_group("perk_crates")
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 0.6, 0.6)
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("D6D573")
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	add_child(mi)
	var label := Label3D.new()
	label.text = label_text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 24
	label.pixel_size = 0.022
	label.outline_size = 8
	label.outline_modulate = Color("292D3B")
	label.position = Vector3(0, 1.0, 0)
	add_child(label)

func _process(delta: float) -> void:
	life -= delta
	rotation.y += delta * 2.5
	if life <= 0.0:
		queue_free()
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	var d: Vector3 = player.global_position - global_position
	d.y = 0.0
	if d.length() < 1.1:
		player.apply_perk(perk_id)
		for crate in get_tree().get_nodes_in_group("perk_crates"):
			if crate != self:
				crate.queue_free()
		queue_free()

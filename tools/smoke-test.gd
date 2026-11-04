extends SceneTree
## godot --headless --path . --script tools/smoke-test.gd
const ART := preload("res://game/scripts/art-palette.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Node3D = load("res://game/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	var player: Node = scene.get_node("Jax")
	for actor in get_nodes_in_group("enemies") + get_nodes_in_group("player"):
		actor.set_physics_process(false)
	assert(player.hp == 120)
	assert(scene.boss.max_hp == 520)
	assert(scene.camps_cleared() == 0)
	assert(get_nodes_in_group("enemies").size() == 18) # 17 camp enemies + boss
	for i in 4:
		assert(get_nodes_in_group("camp_%d" % i).size() == [3, 4, 5, 5][i])
	for enemy in get_nodes_in_group("enemies"):
		assert(not enemy.awake)
		assert(enemy.get_node("Mesh").get_child_count() >= 9)
		if enemy.ranged:
			assert(enemy.base_color == ART.CORAL)
	var material_count := 0
	for mesh in player.model.find_children("*", "MeshInstance3D", true, false):
		for surface in mesh.mesh.get_surface_count():
			var material: StandardMaterial3D = mesh.get_active_material(surface)
			assert(material.roughness == 1.0)
			assert(material.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON)
			material_count += 1
	assert(material_count > 0)
	var hud: CanvasLayer = scene.get_node("HUD")
	assert(hud.RARITY_COLORS == ART.RARITY)
	# Bench lifecycle and palette should work with a real item, not just an empty view.
	var item: Dictionary = player.make_item("heavy", 1)
	assert(player.add_item(item))
	hud.toggle_bench()
	assert(paused and hud.bench.visible)
	hud._on_select(item["uid"])
	hud._act("toggle_equip")
	assert(player.item_in_slots("heavy") != null)
	hud.toggle_bench()
	assert(not paused and not hud.bench.visible)
	# Damage still wakes a camp, removes defeated enemies and creates loot.
	var enemy: Node = get_nodes_in_group("camp_0")[0]
	enemy.take_damage(999, player.global_position)
	assert(get_nodes_in_group("camp_0").size() == 2)
	assert(get_nodes_in_group("camp_0")[0].awake)
	assert(scene.boss.hp == 520)
	player.use_skill()
	assert(player.skill_timer > 0 and player.windup_left > 0)
	# Progress remains in memory after an art-only change.
	player.receipts = 10
	player.save_progress()
	assert(player.PROGRESS.data["receipts"] == 5)
	assert(player.PROGRESS.data["inventory"].size() == 1)
	print("PASS: 17 camp enemies + boss, toon Jax, new palette, bench/equip, aggro/damage/loot, skill, progress")
	# Allow queued old bench controls and death tweens to finish before teardown.
	await create_timer(0.3).timeout
	scene.queue_free()
	for i in 4:
		await process_frame
	quit()

extends Node
## 劇情管理：處理互動（E 鍵）、載入當前場景的關卡腳本。由 Main 底下的 "Story" 節點使用。

const CHAPTER := preload("res://game/scripts/story_state.gd")
const HUD_SCRIPT := preload("res://game/scripts/story_hud.gd")

var hud: CanvasLayer
var player: Node3D
var near: Node3D = null

func _ready() -> void:
	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	get_parent().add_child.call_deferred(hud)
	player = get_parent().get_node("Jax")

func _process(_delta: float) -> void:
	near = null
	if player == null or player.dead:
		_set_prompt("")
		return
	var best := 9999.0
	for it in get_tree().get_nodes_in_group("interactables"):
		if not it.enabled:
			continue
		var d: Vector3 = it.global_position - player.global_position
		d.y = 0.0
		if d.length() <= it.radius and d.length() < best:
			best = d.length()
			near = it
	_set_prompt("［G］" + near.prompt if near != null else "")

func _set_prompt(text: String) -> void:
	if hud != null and hud.is_inside_tree():
		hud.set_prompt(text)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_G and near != null:
		near.activate()

extends Node3D
## 可互動物件：玩家走近會顯示提示，按 E 觸發。

var prompt := "互動"
var radius := 2.0
var enabled := true
var once := true
var action: Callable

func _ready() -> void:
	add_to_group("interactables")

func activate() -> void:
	if not enabled:
		return
	if once:
		enabled = false
	if action.is_valid():
		action.call()

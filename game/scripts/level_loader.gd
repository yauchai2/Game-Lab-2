extends Node3D
## 依 Chapter.level 載入對應的關卡腳本（掛在 Main 底下的 "Street" 節點）。

const CHAPTER := preload("res://game/scripts/chapter.gd")
const LEVELS := {
	"home": preload("res://game/scripts/levels/level_home.gd"),
	"street": preload("res://game/scripts/levels/level_street.gd"),
	"yard": preload("res://game/scripts/levels/level_yard.gd"),
	"roof": preload("res://game/scripts/levels/level_roof.gd"),
	"station": preload("res://game/scripts/levels/level_station.gd"),
	"arena": preload("res://game/scripts/street.gd"),
}

func _ready() -> void:
	var node := Node3D.new()
	node.set_script(LEVELS[CHAPTER.level])
	add_child(node)

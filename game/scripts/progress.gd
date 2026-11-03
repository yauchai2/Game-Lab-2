extends RefCounted
## 長期成長：死亡或通關後重開場景，等級、背包、配件都保留；同時存到硬碟（user://save.dat）。

const SAVE_PATH := "user://save.dat"
const STORY := preload("res://game/scripts/story_state.gd")

static var data := {}
static var character := "jax"
static var intro_seen := false
static var talked := false
static var chapter_done := false
static var choice := ""

static func reset() -> void:
	data = {}
	intro_seen = false
	talked = false
	chapter_done = false
	choice = ""
	STORY.reset()

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func write() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({"data": data, "character": character, "intro_seen": intro_seen, "talked": talked,
		"chapter_done": chapter_done, "choice": choice,
		"story_level": STORY.level, "story_flags": STORY.flags})

static func load_from_disk() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var d: Variant = f.get_var()
	if typeof(d) != TYPE_DICTIONARY or not d.has("data"):
		return false
	data = d["data"]
	character = d.get("character", "jax")
	intro_seen = d.get("intro_seen", true)
	talked = d.get("talked", true)
	chapter_done = d.get("chapter_done", false)
	choice = d.get("choice", "")
	STORY.level = d.get("story_level", "home")
	STORY.flags = d.get("story_flags", {})
	return true

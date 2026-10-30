extends RefCounted
## 第一章（《街外有事》）的進度：目前所在場景與劇情旗標。存檔時由 progress.gd 一併寫入。

## "home"（合租單位）、"street"（街道）、"yard"、"roof"、"station"、"chase"、"convoy"，
## 另有 "arena"（舊試玩場與舊版第一區流程，自由練習）。
static var level := "home"
static var flags := {}

static func has(flag: String) -> bool:
	return flags.get(flag, false)

static func set_flag(flag: String) -> void:
	flags[flag] = true

static func reset() -> void:
	level = "home"
	flags = {}

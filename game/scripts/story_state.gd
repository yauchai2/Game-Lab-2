extends RefCounted
## 第一章（《街外有事》）的進度：目前所在場景與劇情旗標。存檔時由 progress.gd 一併寫入。

## "home"（合租單位）、"street"（街道）、"yard"、"roof"、"station"、"chase"、"convoy"，
## 另有 "arena"（舊試玩場與舊版第一區流程，自由練習）。
## 戰鬥優先（Alan 2026-11-01）：選角後直接進練習場（arena）並略過第一章劇情與章節流程。改為 false 即恢復原有劇情。
const COMBAT_FIRST := true
static var level := "home"
static var flags := {}

static func has(flag: String) -> bool:
	return flags.get(flag, false)

static func set_flag(flag: String) -> void:
	flags[flag] = true

static func reset() -> void:
	level = "home"
	flags = {}

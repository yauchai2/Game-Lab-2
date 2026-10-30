extends RefCounted
## 第一章的進度（只在程式運行期間有效，存檔之後再做）：目前所在場景與劇情旗標。

## "select"（選角）、"home"（合租單位）、"street"（街道）、"arena"（舊試玩場，自由練習）。
static var level := "select"
static var flags := {}

static func has(flag: String) -> bool:
	return flags.get(flag, false)

static func set_flag(flag: String) -> void:
	flags[flag] = true

static func reset() -> void:
	level = "select"
	flags = {}

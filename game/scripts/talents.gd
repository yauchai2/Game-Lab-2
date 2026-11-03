extends RefCounted
## 天賦樹：四條路線，每條 12 點。每升一級得 1 點天賦點，擊敗頭目再得 2 點。
## 只能從路線起點開始，沿相連的點往外點。完整樹隨時可看，每條路線標出幾個值得探索的點。

const FREE_RESPEC_LEVEL := 10
const RESPEC_COST := 5
const BOSS_BONUS := 2

# 每條路線共用同一個形狀：[父點序號, 深度, 橫向位置]
const SHAPE := [
	[-1, 1, 0.0], [0, 2, -1.0], [0, 2, 1.0], [1, 3, -1.5], [1, 3, -0.5], [2, 3, 1.0],
	[3, 4, -1.5], [4, 4, -0.5], [3, 4, -2.5], [5, 4, 1.0], [6, 5, -1.5], [9, 5, 1.0],
]

const STAT_LABELS := {
	"atk": "普攻傷害 +%d%%", "aspd": "攻速 +%d%%", "sdmg": "技能傷害 +%d%%", "scd": "技能冷卻 +%d%%",
	"hp": "生命 +%d", "speed": "移速 +%d%%", "armor": "護甲 +%d",
	"rfire": "火抗 +%d%%", "rcold": "冷抗 +%d%%", "rlight": "電抗 +%d%%",
	"poise": "韌性 +%d", "perfect": "完美格擋判定 +%.2f 秒", "stagger_immune": "踉蹌後免疫 +%.1f 秒",
	"roll_charge": "翻滾充能 +%d", "roll_cd": "翻滾回復 +%d%%",
	"soda": "汽水回血 +%d%%", "flask_fast": "補給充能 +%d%%", "heavy": "重擊破防 +%d%%",
}

const ROUTES := {
	"a": {"name": "爆發", "hint": "傷害、攻速、重擊破防", "dir": Vector2(0, -1), "color": Color("CC6657"), "nodes": [
		["重手", "atk", 6], ["拆家", "sdmg", 8], ["快手", "aspd", 8], ["狠勁", "atk", 8], ["熟練", "scd", 6], ["連打", "aspd", 10],
		["破壞狂", "sdmg", 12], ["調校", "scd", 8], ["重擊手", "heavy", 30], ["收數", "atk", 12], ["暴徒", "sdmg", 16], ["無底洞", "aspd", 12]]},
	"d": {"name": "硬撐", "hint": "生命、護甲、韌性、格擋", "dir": Vector2(1, 0), "color": Color("8FA8E8"), "nodes": [
		["皮厚", "hp", 20], ["硬骨", "armor", 10], ["站穩", "poise", 10], ["厚衣", "armor", 12], ["耐火", "rfire", 8], ["穩如山", "poise", 14],
		["鐵皮", "hp", 40], ["耐凍", "rcold", 8], ["絕緣", "rlight", 8], ["看準", "perfect", 0.06], ["不倒", "stagger_immune", 1.5], ["見招拆招", "perfect", 0.06]]},
	"m": {"name": "遊走", "hint": "移速、翻滾充能與回復", "dir": Vector2(0, 1), "color": Color("7FC49A"), "nodes": [
		["腳快", "speed", 5], ["輕身", "roll_cd", 8], ["加油", "speed", 6], ["多一次", "roll_charge", 1], ["順勢", "roll_cd", 10], ["熟路", "speed", 8],
		["驚險", "roll_cd", 12], ["餘勢", "aspd", 8], ["底子", "hp", 20], ["無影", "speed", 10], ["閃身", "roll_cd", 15], ["追風", "aspd", 10]]},
	"s": {"name": "補給", "hint": "汽水、便當、生命與抗性", "dir": Vector2(-1, 0), "color": Color("E6D26A"), "nodes": [
		["汽水", "soda", 10], ["快充", "flask_fast", 15], ["底子", "hp", 20], ["加量", "soda", 12], ["搶補", "flask_fast", 20], ["吃飽", "hp", 30],
		["滿杯", "soda", 15], ["流水線", "flask_fast", 25], ["冰涼", "rcold", 8], ["結實", "armor", 10], ["暖胃", "rfire", 8], ["吃到飽", "hp", 40]]},
}

static func route_ids() -> Array:
	return ROUTES.keys()

static func node_id(route: String, idx: int) -> String:
	return "%s%d" % [route, idx]

static func parent_of(id: String) -> String:
	var p: int = SHAPE[int(id.substr(1))][0]
	return "" if p < 0 else node_id(id.substr(0, 1), p)

static func info(id: String) -> Dictionary:
	var r: Dictionary = ROUTES[id.substr(0, 1)]
	var idx := int(id.substr(1))
	var n: Array = r["nodes"][idx]
	return {"name": n[0], "stat": n[1], "value": n[2], "route": id.substr(0, 1), "idx": idx}

static func describe(id: String) -> String:
	var n := info(id)
	return STAT_LABELS[n["stat"]] % n["value"]

## 節點在路線內的座標（單位：格；x 橫向，y 往外延伸）。
static func local_pos(id: String) -> Vector2:
	var s: Array = SHAPE[int(id.substr(1))]
	return Vector2(s[2], s[1] - 1)

static func all_ids() -> Array:
	var out: Array = []
	for r in ROUTES:
		for i in SHAPE.size():
			out.append(node_id(r, i))
	return out

## 每條路線標出幾個值得探索的點（序號），介面用亮色標記。
const HIGHLIGHTS := {"a": [8, 6, 10], "d": [3, 10, 9], "m": [3, 6, 10], "s": [0, 4, 6]}

static func is_highlight(id: String) -> bool:
	return HIGHLIGHTS[id.substr(0, 1)].has(int(id.substr(1)))

## 10 級前重置免費，之後要單據。
static func respec_cost(level: int) -> int:
	return 0 if level < FREE_RESPEC_LEVEL else RESPEC_COST

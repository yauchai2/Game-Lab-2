# 開啟 Jax 試玩版（Godot）

專案已經建好，你**唔需要自己砌場景**，只要安裝 Godot 同打開。

## 1. 安裝 Godot

1. 去 https://godotengine.org/download ，下載 **Godot 4.4 或以上嘅標準版（Standard，唔係 .NET）**。
2. 解壓縮 zip，入面一個 `.exe`，**唔使安裝**，雙擊就開。放喺 repo 以外（例如 `C:\Godot\`）。

## 2. 取得專案

用 Git 或 GitHub Desktop 將 `Game-Lab-2` repo 下載到電腦（切換到 PR #1 嘅 branch `claude/project-thread-0f5oar`，合併後用 `main`）。

## 3. 打開同玩

1. Godot 啟動後按 **Import**，選 repo 根目錄嘅 `project.godot`，按 **Import & Edit**。（第一次會自動匯入 Jax 模型，等幾秒。）
2. 按右上角 **▶**（`F5`）。
3. 滑鼠**左鍵**點地板，Jax 行過去；**按住左鍵**會一直跟住游標行（鏡頭跟住，有走路動作）。
4. 綠色方塊敵人會一波波由四周追過嚟（每波多一隻），按 **Q** 或滑鼠**右鍵**放「拆場」重擊：彎身蓄力後放衝擊環，3.5 米內敵人受傷同擊退（敵人 2 下打死；第 2 波起出現紫色遠程敵人，會保持距離射飛彈，冷卻 1.5 秒）。
5. 按 **空白鍵** 向滑鼠方向滑板衝刺（約 5 米，衝刺期間無敵，冷卻 1 秒）。
6. 敵人死後會掉薄荷綠方塊（經驗）同珊瑚色方塊（回血），行近自動吸收；經驗滿升級，自動回滿血、最大血量同技能傷害小幅提升（唔會彈選單）。
7. 左上角顯示等級、血量、波數同技能冷卻。血量歸零會倒地，按 **R** 重新開始。

如果有紅色錯誤，截圖或複製底部紅字畀我。

## 專案結構

| 檔案 | 用途 |
|---|---|
| `project.godot` | Godot 專案設定（喺 repo 根目錄，咁 Godot 先讀到 `assets/`） |
| `game/main.tscn` | 主場景：地板、Jax、鏡頭、燈 |
| `game/scripts/jax.gd` | Jax 移動、走路動畫、「拆場」技能 |
| `game/scripts/camera_follow.gd` | 鏡頭跟隨 |
| `game/enemy.tscn`、`game/scripts/enemy.gd` | 敵人：追人、近身攻擊、受擊閃白同擊退（40 血） |
| `game/scripts/projectile.gd` | 遠程敵人嘅飛彈 |
| `game/scripts/perk_crate.gd` | 型格升級時出現嘅三選一獎勵箱 |
| `game/scripts/zone.gd` | 地面範圍（預警圈、殘留區） |
| `game/scripts/pickup.gd` | 掉落物（經驗／回血） |
| `game/scripts/main.gd` | 一波波生成敵人 |
| `game/scripts/street.gd` | 用方塊程式生成街道、建築、路燈、樹、車（色票見 style-guide） |
| `game/scripts/hud.gd` | 左上角血條、波數、技能冷卻 |
| `assets/characters/jax.glb` | Jax 低多邊形模型（由 Blender 腳本生成） |
| `tools/blender/make_jax.py` | 生成 Jax 模型嘅腳本 |

`.godot/` 係 Godot 自動產生嘅快取，已被 `.gitignore` 擋走。

## 修改 Jax 模型（之後先需要）

模型用腳本生成，改顏色或尺寸就改 `tools/blender/make_jax.py` 再執行；你亦可以直接喺 Blender 打開 `assets/characters/jax.glb`（File → Import → glTF）睇。預覽圖：`docs/art/jax-preview.png`。


## 畫面風格設定

專案用 640×360 低解析度渲染再放大 2 倍（`project.godot` 內 `display/window/stretch`），所以畫面有像素階梯感，對應參考影片嘅復古低解析風格。最新畫面預覽：`docs/art/gameplay-preview.png`。

## 卡匣配件（灰盒）

按 **C** 打開卡匣工作枱（遊戲暫停）：技能「拆場」有 2 個配件槽。敵人掉落**單據**（米白色方塊，貨幣），用單據買配件再裝入槽：

| 配件 | 價錢 | 效果 |
|---|---|---|
| Heavy Stamp | 3 | 傷害 x1.5，蓄力慢 0.2 秒 |
| Echo Slam | 4 | 連擊兩下（各 x0.6） |
| Scorch Zone | 5 | 留下 3 秒持續傷害區 |
| Time Bomb | 6 | 0.8 秒後爆發，範圍 +1 米，傷害 x1.4 |

點槽可以拆走配件，點配件可以買／裝。兩個配件可以疊加（例如 Echo Slam + Time Bomb）。命中敵人時有短暫頓幀同鏡頭震動。

## 型格值（Style）

右上角顯示評級 **C → B → A → S**。命中敵人（+6）、擊殺（+5）、喺敵人或飛彈附近用滑板衝刺閃避（+10）會累積；被打中 -30，唔打約 3 秒後會慢慢跌。評級愈高，「拆場」傷害愈高（B x1.1、A x1.25、S x1.5），S 級頓幀同鏡頭震動更強。

**升到更高評級時**（每 15 秒最多一次），Jax 面前會出現 **3 個黃色獎勵箱**，頭上寫住隨機獎勵（傷害、範圍、冷卻、移速、衝刺冷卻、最大血量、單據）。**行入其中一個**就拎到，其餘消失；10 秒冇拎都會消失。冇選單，唔會暫停遊戲。

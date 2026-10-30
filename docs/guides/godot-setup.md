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
| `game/scripts/speed_lines.gd` | 衝刺同重擊時嘅放射速度線 |
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

## 卡匣配件（隨機掉落 + 砌 build）

現時有 2 張卡匣，每張 2 個配件槽：**拆場 Demolish**（Q／右鍵）同 **滑板衝刺 Skate**（Space）。**配件係敵人隨機掉落**（大方塊，顏色代表稀有度：白 Normal、藍 Magic、黃 Rare），行近自動拾取入背包（上限 10 件）。頭 2 隻敵人必掉一件。

**拆場配件（8 款）**

| 配件 | 效果 |
|---|---|
| 重踏 Heavy Stamp | 傷害提升，蓄力慢 0.2 秒 |
| 迴響震擊 Echo Slam | 連擊（Rare 連 3 下） |
| 焦土 Scorch Zone | 留下持續傷害區 |
| 定時炸彈 Time Bomb | 延遲爆發，範圍更闊、傷害更高 |
| 重拳 Gut Punch | 擊飛敵人 |
| 黑洞 Black Hole | 先將敵人吸向中心再爆 |
| 連鎖反應 Chain Reaction | 被打中嘅敵人再爆炸，波及附近 |
| 腎上腺素 Adrenaline | 每擊中一隻敵人縮短冷卻 |

**衝刺配件（4 款）**

| 配件 | 效果 |
|---|---|
| 火焰軌跡 Flame Trail | 衝刺路上留下火焰區 |
| 磨擦衝撞 Grind Strike | 衝刺穿過敵人造成傷害 |
| 雙重衝刺 Double Dash | 多衝一次 |
| 殘影 Afterimage | 無敵時間加長 |

稀有度愈高，效果愈強（Magic +15%、Rare +30%），而且帶隨機詞綴：Magic 1 條、Rare 2 條（+傷害%、+範圍、-冷卻%）。

按 **C** 打開工作枱（遊戲暫停）：
- 點背包配件選取，按 **Equip／Unequip** 裝上或拆下（自動裝入對應卡匣）；點上面嘅槽可以直接拆走。
- **單據**用途：**Reroll（2）** 重擲詞綴（Magic／Rare）、**Upgrade（3／6）** 升稀有度（Normal→Magic→Rare，詞綴重新抽）、**Scrap（+1）** 拆解配件換 1 單據。
- 配件可以疊加，例如 Echo Slam + Time Bomb、Flame Trail + Double Dash。

**語言：** 遊戲內文字暫時全部係中文（字體用系統字體，Windows／Mac 直接顯示；日後出 Web 版要另外放中文字型檔）。

## 頭目同通關

打完第 3 波，頭目「收數大佬」登場（畫面底部有血條）：
- 追住你近身打（12 傷害）。
- 每幾秒向你嘅位置**預警重擊**：地面先出現黃圈，1 秒後爆開（22 傷害），要及時衝刺走開。
- 血量剩一半時召喚 3 隻小弟。
- 打敗後掉 3 件配件同 10 單據，畫面顯示「通關！」，按 **R** 再玩一次。

## 打擊演出

- **技能字卡：** 放「拆場」或衝刺時，畫面中間彈出橫幅字卡（DEMOLISH／SKATE DASH），拆場字卡下面會列出已裝嘅配件名。
- **速度線：** 衝刺同重擊命中敵人時，畫面射出放射狀白色速度線（命中愈多愈強）。
- 另外有頓幀同鏡頭震動。

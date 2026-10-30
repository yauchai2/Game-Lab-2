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
3. 滑鼠**左鍵**點地板，Jax 行過去（鏡頭跟住，有走路動作）。
4. 綠色方塊敵人會一波波由四周追過嚟（每波多一隻），按 **Q** 或滑鼠**右鍵**放「拆場」重擊：彎身蓄力後放衝擊環，3.5 米內敵人受傷同擊退（敵人 2 下打死，冷卻 1.5 秒）。
5. 左上角顯示血量、波數同技能冷卻。血量歸零會倒地，按 **R** 重新開始。

如果有紅色錯誤，截圖或複製底部紅字畀我。

## 專案結構

| 檔案 | 用途 |
|---|---|
| `project.godot` | Godot 專案設定（喺 repo 根目錄，咁 Godot 先讀到 `assets/`） |
| `game/main.tscn` | 主場景：地板、Jax、鏡頭、燈 |
| `game/scripts/jax.gd` | Jax 移動、走路動畫、「拆場」技能 |
| `game/scripts/camera_follow.gd` | 鏡頭跟隨 |
| `game/enemy.tscn`、`game/scripts/enemy.gd` | 敵人：追人、近身攻擊、受擊閃白同擊退（40 血） |
| `game/scripts/main.gd` | 一波波生成敵人 |
| `game/scripts/hud.gd` | 左上角血條、波數、技能冷卻 |
| `assets/characters/jax.glb` | Jax 低多邊形模型（由 Blender 腳本生成） |
| `tools/blender/make_jax.py` | 生成 Jax 模型嘅腳本 |

`.godot/` 係 Godot 自動產生嘅快取，已被 `.gitignore` 擋走。

## 修改 Jax 模型（之後先需要）

模型用腳本生成，改顏色或尺寸就改 `tools/blender/make_jax.py` 再執行；你亦可以直接喺 Blender 打開 `assets/characters/jax.glb`（File → Import → glTF）睇。預覽圖：`docs/art/jax-preview.png`。

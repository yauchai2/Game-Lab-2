# 資產規格（換模型／場景時必讀）

目標：任何人（你、我、外部美術）做出符合呢份規格嘅模型，**直接覆蓋同名檔案就可以換入遊戲，唔使改程式**。

## 通用

| 項目 | 規定 |
|---|---|
| 格式 | `.glb`（Blender：File → Export → glTF 2.0，揀 glb） |
| 單位 | 1 單位 = 1 米 |
| 原點 | 腳底中心（角色）／底面中心（建築、道具） |
| 朝向 | 角色正面 = Blender 嘅 **+Y**（匯入 Godot 後面向 −Z） |
| 面數 | 角色 ≤ 3,000 三角面；道具 ≤ 500；建築 ≤ 1,500 |
| 貼圖 | 優先純色材質；有貼圖就 ≤ 128×128，Godot 用 Nearest（已設定） |
| 顏色 | 用 `docs/art/style-guide.md` 同 `docs/design/characters.md` 嘅色票 |
| 風格 | 平塗、霧面、無金屬反光、少量大面，保留完整 3D 厚度 |

## 角色（`assets/characters/<名>.glb`）

- 檔名：`jax.glb`、`vee.glb`、`skye.glb`、`niko.glb`。
- 身高：Jax 1.74m、Niko 1.68m、Vee 1.66m、Skye 1.62m。
- 肢體節點名（程式用嚟做走路／攻擊動作）：`LegL`、`LegR`、`ArmL`、`ArmR`、`Head`，樞軸喺髖／肩／頸。
- 如果改用骨架動畫：動畫名用 `idle`、`run`、`attack`、`hit`、`die`，並告訴我，我會接入。

## 場景（`assets/environment/`）

- 以 1 米格為基礎，建議模組：建築 6×6 米底、路燈、樹、車、販賣機。
- 碰撞盒由我喺 Godot 加，模型唔使做碰撞。
- 現時街景由 `game/scripts/street.gd` 用方塊生成；有模型後會逐件改成載入 `.glb`。

## 點樣換

1. 做好 `.glb`，放入對應資料夾（同名覆蓋舊檔）。
2. GitHub Desktop Commit → Push，話我知。
3. 我檢查比例、朝向同肢體節點，必要時微調腳本。

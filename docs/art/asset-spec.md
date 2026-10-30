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

## 用現成素材（建議路線之一）

**揀素材：**
1. 優先揀授權係 **CC0（公共領域）** 嘅，可商用、無需署名。常見來源：Kenney（kenney.nl）、Quaternius（quaternius.com）、OpenGameArt（揀 CC0 篩選）、Poly Pizza（逐個睇授權）、itch.io 嘅 free assets（逐個睇授權）。
2. **授權睇法：** CC0 最安心；CC-BY 可用但要署名；有 NC（非商用）、ND（禁改）、只限某引擎、或者冇寫授權嘅，**唔要用**。
3. 風格揀**低多邊形、平塗、純色或細貼圖**嘅，避免寫實貼圖、PBR 金屬材質、太多面。
4. 每用一件素材，喺下面「素材來源」表記錄：檔名、來源網址、作者、授權。

**改成符合規格（Blender，逐步）：**
1. File → Import 匯入（glb／fbx／obj 皆可）。
2. 檢查比例：按 `N` 睇 Dimensions，角色高度改到規格身高（按 `S` 縮放，再 `Ctrl+A` → Scale 套用）。
3. 檢查朝向：正面要向 **+Y**；用 `R` `Z` 旋轉後 `Ctrl+A` → Rotation 套用。
4. 原點：Object → Set Origin → Origin to 3D Cursor（游標先放腳底中心）。
5. 面數太多：加 Modifier **Decimate**（Ratio 調低），再 Apply。
6. 貼圖／顏色：貼圖縮到 128×128 以下；或者改用純色材質，顏色用色票。
7. 角色分件：手腳頭分開物件，改名 `LegL`、`LegR`、`ArmL`、`ArmR`、`Head`，樞軸放髖／肩／頸（見上面角色規格）。
8. 匯出：見下面「匯出 glb」。

## 自己用 Blender 做（最小路線）

1. 刪除預設方塊以外所有物件；用方塊起形：`Shift+A` → Mesh → Cube。
2. 編輯模式（`Tab`）：`G` 移動、`S` 縮放、`E` 擠出，用大面砌出身體、頭、手腳（參考 `tools/blender/make_jax.py` 嘅尺寸）。
3. 上色：Material 面板新增材質，Base Color 填色票嘅 HEX，Roughness 設 1。
4. 檢查比例：`N` → Item → Dimensions。
5. 一個部件一個物件，並按規格改名同設樞軸。

## 匯出 glb

File → Export → glTF 2.0 (.glb)。設定：Format 揀 **glTF Binary (.glb)**；Include 只揀要用嘅物件（Limit to → Selected Objects）；Transform 勾 **+Y Up**；Mesh 勾 Apply Modifiers。檔名按規格，放入 `assets/` 對應資料夾，然後 Commit → Push 並話我知。

## 素材來源紀錄

| 檔案 | 來源網址 | 作者 | 授權 |
|---|---|---|---|
| `assets/characters/jax.glb` | 本專案自製（`tools/blender/make_jax.py`） | Game Lab 2 | 自有 |

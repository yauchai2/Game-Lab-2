# 資產規格（更換模型與場景時必讀）

目標：任何人（你、我、外部美術）做出符合這份規格的模型，**直接覆蓋同名檔案就可以換入遊戲，不需要修改程式**。

## 通用

| 項目 | 規定 |
|---|---|
| 格式 | `.glb`（Blender：File → Export → glTF 2.0，選擇 glb） |
| 單位 | 1 單位 = 1 米 |
| 原點 | 腳底中心（角色）／底面中心（建築、道具） |
| 朝向 | 角色正面 = Blender 的 **+Y**（匯入 Godot 後面向 −Z） |
| 面數 | 角色 ≤ 3,000 三角面；道具 ≤ 500；建築 ≤ 1,500 |
| 貼圖 | 優先使用純色材質；有貼圖則 ≤ 128×128，Godot 使用 Nearest（已設定） |
| 顏色 | 使用 `docs/art/style-guide.md` 與 `docs/design/characters.md` 的色票 |
| 風格 | 平塗、霧面、無金屬反光、少量大面，保留完整 3D 厚度 |

## 角色（`assets/characters/<名>.glb`）

- 檔名：`jax.glb`、`vee.glb`、`skye.glb`、`niko.glb`。
- 身高：Jax 1.74m、Niko 1.68m、Vee 1.66m、Skye 1.62m。
- 肢體節點名（程式用來做走路與攻擊動作）：`LegL`、`LegR`、`ArmL`、`ArmR`、`Head`，樞軸在髖、肩、頸。
- 如果改用骨架動畫：動畫名使用 `idle`、`run`、`attack`、`hit`、`die`，並告知我，我會接入。

## 場景（`assets/environment/`）

- 以 1 米格為基礎，建議模組：建築 6×6 米底、路燈、樹、車、販賣機。
- 碰撞盒由我在 Godot 中加入，模型不需要做碰撞。
- 目前街景由 `game/scripts/street.gd` 用方塊生成；有模型後會逐件改為載入 `.glb`。

## 如何更換

1. 做好 `.glb`，放入對應資料夾（同名覆蓋舊檔）。
2. 用 GitHub Desktop 提交（Commit）並推送（Push），然後告知我。
3. 我檢查比例、朝向與肢體節點，必要時微調腳本。

## 使用現成素材（建議路線之一）

**挑選素材：**
1. 優先選擇授權為 **CC0（公共領域）** 的素材，可商用、無需署名。常見來源：Kenney（kenney.nl）、Quaternius（quaternius.com）、OpenGameArt（篩選 CC0）、Poly Pizza（逐個查看授權）、itch.io 的免費素材（逐個查看授權）。
2. **授權判斷：** CC0 最安心；CC-BY 可用但要署名；含 NC（非商用）、ND（禁止修改）、限定某引擎、或沒有標明授權的，**不要使用**。
3. 風格選擇**低多邊形、平塗、純色或小貼圖**的，避免寫實貼圖、PBR 金屬材質、面數過多。
4. 每使用一件素材，在下面「素材來源紀錄」中記錄：檔名、來源網址、作者、授權。

**改成符合規格（Blender，逐步）：**
1. File → Import 匯入（glb、fbx、obj 皆可）。
2. 檢查比例：按 `N` 查看 Dimensions，把角色高度改為規格身高（按 `S` 縮放，再 `Ctrl+A` → Scale 套用）。
3. 檢查朝向：正面要朝向 **+Y**；用 `R` `Z` 旋轉後 `Ctrl+A` → Rotation 套用。
4. 原點：Object → Set Origin → Origin to 3D Cursor（游標先放在腳底中心）。
5. 面數太多：加入 Modifier **Decimate**（Ratio 調低），再 Apply。
6. 貼圖與顏色：貼圖縮到 128×128 以下；或者改用純色材質，顏色取自色票。
7. 角色分件：手、腳、頭分開成物件，改名為 `LegL`、`LegR`、`ArmL`、`ArmR`、`Head`，樞軸放在髖、肩、頸（見上面的角色規格）。
8. 匯出：見下面「匯出 glb」。

## 自己用 Blender 製作（最小路線）

1. 刪除預設方塊以外的所有物件；用方塊起形：`Shift+A` → Mesh → Cube。
2. 編輯模式（`Tab`）：`G` 移動、`S` 縮放、`E` 擠出，用大面砌出身體、頭、手腳（參考 `tools/blender/make_jax.py` 的尺寸）。
3. 上色：在 Material 面板新增材質，Base Color 填入色票的 HEX，Roughness 設為 1。
4. 檢查比例：`N` → Item → Dimensions。
5. 一個部件一個物件，並按規格改名與設定樞軸。

## 匯出 glb

File → Export → glTF 2.0 (.glb)。設定：Format 選擇 **glTF Binary (.glb)**；Include 只選要用的物件（Limit to → Selected Objects）；Transform 勾選 **+Y Up**；Mesh 勾選 Apply Modifiers。檔名依規格命名，放入 `assets/` 對應資料夾，然後提交並推送，再告知我。

## 素材來源紀錄

| 檔案 | 來源網址 | 作者 | 授權 |
|---|---|---|---|
| `assets/characters/jax.glb` | 本專案自製（`tools/blender/make_jax.py`） | Game Lab 2 | 自有 |

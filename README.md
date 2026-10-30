# Game Lab 2

低多邊形（Low-poly）四人街頭遊戲。個人開發項目。

## 資料夾結構（固定，唔好隨便加新層）

| 資料夾 | 放咩 |
|---|---|
| `docs/design/` | 企劃、角色設定、玩法、劇情（文字文件） |
| `docs/art/` | 美術風格指南、參考分析、三視圖/表情稿說明 |
| `docs/guides/` | 逐步教學（安裝工具、做第一個場景等） |
| `assets/characters/` | 角色模型、貼圖、動畫（Blender 出嘅檔案） |
| `assets/environment/` | 街道、建築、道具模型 |
| `assets/audio/` | 音效、音樂 |
| `game/` | 遊戲場景同腳本（Godot） |
| 根目錄 `project.godot` | Godot 專案檔（放根目錄先讀到 `assets/`） |
| `tools/` | 小腳本、輔助工具（例如 `tools/blender/` 模型生成腳本） |

## 現有文件

- `docs/art/style-guide.md` — 美術風格（由兩條參考影片整理）
- `docs/art/asset-spec.md` — 換模型／場景嘅資產規格
- `docs/design/characters.md` — 四人角色設定（唯一來源）
- `docs/design/game-plan.md` — 企劃草案、待決定問題、工具路線
- `docs/guides/godot-setup.md` — 安裝 Godot、打開同玩 Jax 試玩版

## 規則

1. **一個主題一個檔案**，更新舊檔，唔好開新版本（版本記錄交畀 git）。
2. 新增檔案前，先睇呢個表，放入對應資料夾。
3. 檔名全部細楷英文、用 `-` 連接，例如 `jax-idle.blend`、`street-lamp.glb`。角色檔名前綴用角色名：`jax-`、`vee-`、`skye-`、`niko-`。
4. 大型參考影片（mp4）唔放入 repo，留喺 Google Drive `Game Lab 2` 資料夾。
5. 決定咗嘅重要事項，記喺對應 docs 檔案頂部。

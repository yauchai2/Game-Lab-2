# 城市場景工作檔

本場景參考 `Video Project 1.mp4` 的日間藍天、賽璐璐色塊、深色輪廓和多層城市結構。這是持續製作的原創環境，尚未證明與影片完全一致；不包含人物或玩法。

## 檔案與使用

- `assets/environment/city-scene.blend`：可編輯的主場景，包含廣場、分層高架、南北及東西街道、南側背街環路、圓形地標、壁畫、天空和英文及日文招牌。
- `assets/environment/city-scene-lightweight.blend`：按材質與空間區域合併靜態小物件的候選版本；可編輯版仍是源檔。此版本的實際效能須在目標引擎測試。
- `assets/environment/city-modules/`：可獨立載入的手工資訊牌、音響、廣場圓環和圓角塔樓。
- `assets/environment/city-textures/`：生成天空和無文字圖案的來源圖片；場景使用中的圖片和日文字型也已打包在 Blender 檔內。
- `docs/art/city-preview-main.png`、`docs/art/city-preview-east.png`、`docs/art/city-preview-south-loop.png`：主視角、東街和南側背街預覽。
- `docs/art/city-image-provenance.md`：本輪生成圖片的來源和提示詞。
- `tools/blender/verify-city-scene.py`：檢查場景集合、日文、字型與圖片依賴。
- `tools/blender/batch-city-scene.py`：由可編輯版重新產生靜態合併版。

以 Blender 4.3 或相容版本開啟，使用 Eevee 渲染。主鏡頭為 `MainCamera`，另有橋底、北街、東西側街與圓塔檢查鏡頭。原列車模型保留但在新版中隱藏，方便比較。

建築色階使用 Blender 的 Shader to RGB，深色輪廓使用合成器深度資訊；這些效果一般不能完整直接匯出至 GLB 或其他引擎，須在目標引擎重建並驗證。生成的 `pixel-concrete-source.png` 來源為 1254 × 1254 像素；材質以每 10 米 128 個取樣步階及最近鄰呈現低解像外觀，來源圖本身不是 128 × 128。日文可以包含有意義的日式漢字。

修改可編輯版後，可在專案根目錄執行 `blender -b --python-exit-code 1 --python tools/blender/batch-city-scene.py` 重新產生合併版。指令會覆寫預設的 `city-scene-lightweight.blend`；可用 `-- --output 其他路徑.blend` 指定另一個輸出檔。源場景和輸出路徑必須不同。合併後仍應重新渲染檢查。

場景內打包 Noto Sans CJK 字型，授權文字見 `docs/art/noto-cjk-license.txt`。

## 碰撞與檢查限制

街道核心以廣場和南北、東西街為主；外圍遠景建築較簡化，場景尚未設定可行走範圍的遊戲引擎邊界。

隱藏的 `COLLISION_PROXIES` 包含地面、部分建築、圓塔及候車亭的近似碰撞來源網格；它們並非已配置好的遊戲引擎碰撞，覆蓋亦未完整。以 1 米間距對地面作粗略抽樣，所列的廣場、南街、東西外街、南側背街、北面過路處及圓塔旁檢查點在抽樣網格中相連，結果見 `docs/art/city-clearance-check.json`。南面遠景缺口已以同一視角重新渲染確認；另有少量近距離水平射線抽查。這些檢查可漏掉細小障礙，不能證明完整行走路線、坡面、碰撞或角色物理可用。

此提交不包含原參考影片、過程中的大量渲染、暫存檔或 Blender 自動備份。

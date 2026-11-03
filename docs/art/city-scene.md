# 城市場景工作檔

本場景參考 `Video Project 1.mp4` 的明亮日間、賽璐璐色塊、深青色陰影和城市建築風格。場景仍在製作中，尚未完成全部建築與各視角的精修。

## 檔案

- `assets/environment/city-scene.blend`：最新可編輯的 Blender 場景，包含廣場、天橋、列車、南側與側街、圓角建築、壁畫、天空、材質和日文招牌。
- `assets/environment/city-modules/`：可獨立載入的手工資訊牌、音響、廣場圓環和圓角塔樓。
- `assets/environment/city-textures/`：生成的天空與無文字圖案原圖。使用中的圖片和日文字型亦已打包進場景檔。
- `docs/art/city-sign-preview.png`：日文招牌預覽。
- `tools/blender/verify-city-scene.py`：檢查場景集合、文字與打包資源的腳本。

以 Blender 4.3 或相容版本開啟場景。主鏡頭為 `MainCamera`，另有橋底、後街及側街檢查鏡頭。以 Eevee 渲染；卡通色階使用 Blender 材質節點，深度輪廓使用合成器，並非所有效果都能直接匯出至 GLB 或其他引擎。

日文及英文招牌均可使用，包括有意義的日式漢字。場景不包括人物或玩法。

本提交只保留可用工作檔、手工模組及必要素材，不包含過程中的大量渲染、暫存檔和 Blender 自動備份。原參考影片不包含在此提交中。

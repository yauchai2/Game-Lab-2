# AI 工作指引（Game Lab 2）

本檔只放入口規則；細節一律看下列文件，不在此重複。

## 開始前必讀

1. `README.md`（資料夾結構與規則）
2. `docs/art/style-guide.md`（美術規格；做場景、角色、著色、描邊前必讀「JSR 目標規格」與「叫 AI 做出完整 JSR 風格場景的方法」）
3. `docs/art/asset-spec.md`、`docs/design/characters.md`、`docs/design/world.md`

## 美術目標（Alan 2026-11-05 已確認）

《Jet Set Radio》式風格：高飽和重點色、純黑粗描邊、三段硬邊卡通明暗、塗鴉；固定 45 度等角鏡頭、不可旋轉；沿用暖白／青綠／珊瑚／亮黃色票，不使用藍紫。

## 做事規則

- **分階段**：一次只做 style-guide 指定的一個階段，完成後擷取畫面、列出數據與已知問題，等 Alan 驗收再做下一階段。
- **只做被要求的事**：Alan 討論想法時只給意見；明確說「做」才寫程式或開 PR。
- **不改 `game/main.tscn`**，JSR 實驗放在 `game/scenes/jsr-test.tscn`。
- **區分**已驗證、未驗證、建議；沒有在 Godot 實測的數值不得寫成已確認。雲端環境只能軟體渲染，也沒有 Blender，實機觀感與 Blender 資產要 Alan 在本機做。
- **一個主題一個檔案**，更新舊檔，不另開平行版本。
- **語言**：文檔與遊戲內中文一律書面語，不用粵語或港式用字；與 Alan 對話用廣東話。Alan 零基礎，說明要白話。有問題或不妥直接講，不要附和。

## 常用指令

- 匯入檢查：`godot --headless --path . --editor --import --quit`
- 冒煙測試：`godot --headless --path . --script tools/smoke-test.gd`
- JSR 驗收畫面：`xvfb-run -a godot --path . --rendering-method gl_compatibility --script tools/capture-jsr.gd`（輸出 `docs/art/jsr/`）

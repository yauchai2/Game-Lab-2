# AGENTS.md（給 Codex 與其他協作代理）

本檔案說明專案背景與協作規則。使用者是 Alan，零基礎個人開發者。

## 專案簡介

- Godot 4.4 低多邊形（Low-poly）街頭動作 ARPG，四名可選角色：Jax、Vee、Skye、Niko。
- 長期成長型 ARPG，參考 PoE2 但要做出差異化。
- 世界名為「疊域」，國際混搭都市。
- 語氣為「日常但反社會」，NPC 可有粗俗語言；遊戲內與文件中的中文一律使用書面語，不用港式或粵語口語字。主角幾乎不說話，以動作表達。

## 文件位置

- `README.md`：資料夾結構規則與現有文件清單（新檔案先照此放置，不要隨便新增層級）。
- `docs/design/world.md`：世界觀、基調、命名規則。
- `docs/design/characters.md`：角色設定唯一來源。
- `docs/design/game-plan.md`：企劃與待決定問題。
- `docs/guides/godot-setup.md`：安裝與開啟 Godot。
- `docs/design/poe2-research.md`：目前不在 main，位於 PR #8（`claude/gear-system`）。

## 協作規則

1. 每個任務使用獨立分支 `codex/<topic>`，完成後開 PR 指向 `main`。
2. 不要直接推送到 `main`，也不要推送到任何 `claude/*` 分支。
3. 每個 PR 保持小而聚焦；PR 描述需寫明改了什麼、如何測試。
4. 不要修改其他工作線正在處理的檔案。目前 Claude 在 `claude/gear-system`（PR #8）處理：配件介面、鏡頭、第一章流程、掉落。需要碰這些範圍前先問 Alan。
5. 建議 Codex 負責：獨立素材，以及新增且彼此隔離的系統。
6. 不要執行或假設試玩結果；試玩由 Alan 進行。
7. 不提交大型影片或二進位檔案。

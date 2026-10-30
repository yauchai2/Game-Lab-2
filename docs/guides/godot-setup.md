# Godot 安裝同第一個灰盒場景（Jax 試玩版第 1 步）

目標：喺空白街道上，按滑鼠左鍵，一個方塊／膠囊「Jax」跑去你點嘅位置。用 Godot 4，唔需要 Blender。

## 1. 安裝 Godot

1. 去 https://godotengine.org/download ，下載 **Godot 4.x 標準版（Standard，唔係 .NET）**。
2. 解壓縮 zip，裡面一個 `.exe`，**唔使安裝**，雙擊就開。建議放喺 `Game Lab 2/tools/` 以外嘅位置（例如 `C:\Godot\`），唔好放入 repo。

## 2. 建立專案

1. 開 Godot → **Create** 。
2. **Project Name：** `Game Lab 2`。**Project Path：** 揀 repo 入面嘅 `game` 資料夾（即 `Game-Lab-2/game`）。
3. **Renderer 揀 Compatibility**（日後出 Web 版需要，低多邊形風格完全夠用）。
4. 按 **Create & Edit**。

## 3. 砌場景（全部用內建方塊）

右上角 Scene 面板，**Add Child Node** 係按 `+` 或右鍵。

1. 根節點揀 **3D Scene**，改名 `Main`。
2. **地板：** 加 `StaticBody3D`，改名 `Floor`。
   - 子節點 `MeshInstance3D`：Mesh 揀 `New BoxMesh`，點入去，Size 設 `40, 1, 40`。
   - 子節點 `CollisionShape3D`：Shape 揀 `New BoxShape3D`，Size 同樣設 `40, 1, 40`。
   - 選 `Floor`，Transform → Position 設 `0, -0.5, 0`（令地面頂部剛好喺 y=0）。
3. **Jax：** 加 `CharacterBody3D`，改名 `Jax`，Position 設 `0, 1, 0`。
   - 子節點 `MeshInstance3D`：Mesh 揀 `New CapsuleMesh`。
   - 子節點 `CollisionShape3D`：Shape 揀 `New CapsuleShape3D`。
4. **鏡頭：** 喺 `Main` 下加 `Camera3D`，Position `0, 12, 10`，Rotation `-50, 0, 0`（度）。
5. **燈：** 加 `DirectionalLight3D`，Rotation `-50, -30, 0`。
6. 按 `Ctrl+S` 存檔，名叫 `main.tscn`（放喺 `game/` 入面）。

## 4. 加移動腳本

1. 右鍵 `Jax` → **Attach Script**，Language 揀 GDScript，路徑 `game/scripts/jax.gd`，Create。
2. 將下面成段貼入去，取代原有內容：

```gdscript
extends CharacterBody3D

@export var speed := 6.0
@export var gravity := 20.0

var target := Vector3.ZERO
var has_target := false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var camera := get_viewport().get_camera_3d()
		var from := camera.project_ray_origin(event.position)
		var to := from + camera.project_ray_normal(event.position) * 100.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit:
			target = hit.position
			has_target = true

func _physics_process(delta: float) -> void:
	var move := Vector3.ZERO
	if has_target:
		var dir := target - global_position
		dir.y = 0.0
		if dir.length() < 0.2:
			has_target = false
		else:
			move = dir.normalized() * speed
			look_at(global_position + dir, Vector3.UP)
	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= gravity * delta
	move_and_slide()
```

3. `Ctrl+S` 存檔。

## 5. 執行

右上角按 **▶ Play**（或 `F5`），第一次問主場景就揀 `main.tscn`。按滑鼠左鍵，膠囊會跑去你點嘅位置。

## 做到咁就成功

- 如果有錯誤訊息，截圖或者複製底部紅字畀我。
- 完成後下一步：鏡頭跟住 Jax、加第一個敵人方塊、加「拆場」重擊技能。

## 檔案放邊

- `game/main.tscn`、`game/scripts/jax.gd`、`game/project.godot`：全部入 `game/`。
- `.godot/` 資料夾係 Godot 自動產生，唔使上傳（已加入 `.gitignore`）。

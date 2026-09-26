extends Area2D
## LevelExit
## ステージクリア地点。プレイヤーが触れるとドアが左右にスライドして開き、
## 開き終わってからnext_scene_pathのシーンに遷移する。
## lockedがtrueの間は反応しない（ステージ固有のパズルクリアが必要な場合に使う）。

@export_file("*.tscn") var next_scene_path: String = ""
@export var slide_distance: float = 40.0 ## 各パネルが開く際にスライドする距離
@export var slide_duration: float = 0.35 ## スライドにかかる時間（秒）
@export var locked: bool = false ## trueの間はインタラクトしても開かない

var _triggered: bool = false

@onready var _door_left: Polygon2D = $DoorLeft
@onready var _door_right: Polygon2D = $DoorRight
@onready var _status_bar: Polygon2D = $StatusBar
@onready var _status_dot: Polygon2D = $StatusDot

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_state_visual()

func _on_body_entered(body: Node) -> void:
	if _triggered or locked:
		return
	if next_scene_path == "":
		push_warning("LevelExit: next_scene_pathが未設定です")
		return
	if body.is_in_group("player"):
		_triggered = true
		_open_door()

func unlock() -> void:
	locked = false
	_update_state_visual()

func _update_state_visual() -> void:
	var color := Color(1.0, 0.38, 0.16, 1.0) if locked else Color(0.3, 1.0, 0.72, 1.0)
	_status_bar.color = color
	_status_dot.color = color

func _open_door() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_door_left, "position:x", -slide_distance, slide_duration)
	tween.tween_property(_door_right, "position:x", slide_distance, slide_duration)
	tween.chain().tween_callback(_change_scene)

func _change_scene() -> void:
	get_tree().change_scene_to_file(next_scene_path)

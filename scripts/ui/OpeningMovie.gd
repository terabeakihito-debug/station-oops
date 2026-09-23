extends Control
## OpeningMovie
## 名前入力の直後（リリース時のみ）に再生する、5シーン連続のオープニングムービー。
## 終了後はチュートリアル整備室へ進む。
## 何かキー/クリックで全体をスキップして先に進む。
## （各シーンごとのスキップではなく、オープニング全体のスキップという想定）

const CLIP_PATHS: Array[String] = [
	"res://assets/videos/opening_01.ogv",
	"res://assets/videos/opening_02.ogv",
	"res://assets/videos/opening_03.ogv",
	"res://assets/videos/opening_04.ogv",
	"res://assets/videos/opening_05.ogv",
]
const NEXT_SCENE_PATH := "res://scenes/levels/Level_01_Tutorial.tscn"

var _clip_index: int = 0
var _advanced: bool = false

@onready var _video: VideoStreamPlayer = $VideoStreamPlayer
@onready var _skip_label: Label = $SkipLabel

func _ready() -> void:
	MusicManager.play_track("tutorial")

	_video.finished.connect(_on_video_finished)
	_play_clip(0)

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_skip_label, "modulate:a", 0.3, 0.6)
	tween.tween_property(_skip_label, "modulate:a", 1.0, 0.6)

func _play_clip(index: int) -> void:
	_clip_index = index
	_video.stream = load(CLIP_PATHS[index])
	_video.play()

func _on_video_finished() -> void:
	if _clip_index + 1 < CLIP_PATHS.size():
		_play_clip(_clip_index + 1)
	else:
		_advance()

func _unhandled_input(event: InputEvent) -> void:
	if _advanced:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_advance()

func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)

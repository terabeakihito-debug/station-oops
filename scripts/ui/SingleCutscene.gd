extends Control
## SingleCutscene
## 各ステージ導入・エンディング用の汎用カットシーン再生画面。
## 動画再生後、または何かキー/クリックでスキップした場合に
## next_scene_pathへ遷移する。

@export_file("*.ogv") var video_path: String = ""
@export_file("*.tscn") var next_scene_path: String = ""

## trueの場合、カットシーン開始時にそれまでのBGMを止める（ステージ間カットシーン用）。
@export var stop_bgm_on_start: bool = false
## 空でなければ、カットシーン開始時にこのtrack_keyのBGMへ切り替える
## （MusicManagerのTRACKSに登録済みのキーを指定。エンディング開始などに使う）。
@export var play_track_on_start: String = ""

var _advanced: bool = false

@onready var _video: VideoStreamPlayer = $VideoStreamPlayer
@onready var _skip_label: Label = $SkipLabel

func _ready() -> void:
	if play_track_on_start != "":
		MusicManager.play_track(play_track_on_start)
	elif stop_bgm_on_start:
		MusicManager.stop_bgm()

	if video_path != "":
		_video.stream = load(video_path)
	_video.finished.connect(_on_video_finished)
	_video.play()

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_skip_label, "modulate:a", 0.3, 0.6)
	tween.tween_property(_skip_label, "modulate:a", 1.0, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if _advanced:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_advance()

func _on_video_finished() -> void:
	_advance()

func _advance() -> void:
	if _advanced:
		return
	_advanced = true
	if next_scene_path == "":
		push_warning("SingleCutscene: next_scene_pathが未設定です")
		return
	get_tree().change_scene_to_file(next_scene_path)

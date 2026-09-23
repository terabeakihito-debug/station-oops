extends Control
## EndingScreen
## OOPS core撃破後に表示するエンディング画面。
## 何か入力でタイトル画面に戻る（ゲーム状態はリセットする）。

@onready var _prompt_label: Label = $PromptLabel
@onready var _message_label: Label = $MessageLabel

var _returned: bool = false

func _ready() -> void:
	MusicManager.play_track("ending")

	var player_name: String = GameManager.player_name_input
	if player_name == "":
		player_name = "プレイヤー"
	_message_label.text = "STATION OOPS - CLEAR!\n\n%s さん、おつかれさまでした" % player_name

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_prompt_label, "modulate:a", 0.2, 0.6)
	tween.tween_property(_prompt_label, "modulate:a", 1.0, 0.6)

func _unhandled_input(event: InputEvent) -> void:
	if _returned:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_returned = true
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")

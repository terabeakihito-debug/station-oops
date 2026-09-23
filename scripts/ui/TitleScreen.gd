extends Control
## TitleScreen
## ゲーム最初に表示するタイトル画面。
## キー入力またはクリックでプレイヤー名前入力画面へ進む。

@onready var _prompt_label: Label = $PromptLabel
@onready var _logo: TextureRect = $Logo

var _started: bool = false

func _ready() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(_prompt_label, "modulate:a", 0.2, 0.6)
	tween.tween_property(_prompt_label, "modulate:a", 1.0, 0.6)

	# ロゴ明滅：アルファ値1.0⇄0.4、周期2秒程度、sine系イージングで常時ループ。
	var logo_tween := create_tween()
	logo_tween.set_loops()
	logo_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	logo_tween.tween_property(_logo, "modulate:a", 0.4, 1.0)
	logo_tween.tween_property(_logo, "modulate:a", 1.0, 1.0)

func _unhandled_input(event: InputEvent) -> void:
	if _started:
		return
	if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
		_started = true
		get_tree().change_scene_to_file("res://scenes/ui/NameInput.tscn")

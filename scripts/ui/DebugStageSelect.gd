extends Control
## DebugStageSelect
## デバッグ用のステージ選択画面。名前入力の直後、デバッグ実行時のみ表示される
## （NameInput.gdがOS.has_feature("debug")で分岐している）。
## リリースエクスポートではこの画面自体は残っていても呼び出されないため
## プレイヤーの目に触れることはないが、念のためシーンごと削除しても構わない。

const STAGES := [
	{"label": "チュートリアル整備室", "path": "res://scenes/levels/Level_01_Tutorial.tscn"},
	{"label": "FLIP LAB", "path": "res://scenes/levels/Level_02_FlipLab.tscn"},
	{"label": "WIRE BAY", "path": "res://scenes/levels/Level_03_WireBay.tscn"},
	{"label": "SIZE DOCK", "path": "res://scenes/levels/Level_04_SizeDock.tscn"},
	{"label": "OOPS core", "path": "res://scenes/levels/Level_05_OOPSCore.tscn"},
	{"label": "エンディング", "path": "res://scenes/ui/EndingScreen.tscn"},
	{"label": "タイトルへ戻る", "path": "res://scenes/ui/TitleScreen.tscn"},
	{"label": "── ムービー確認 ──", "path": ""},
	{"label": "オープニングムービー", "path": "res://scenes/ui/OpeningMovie.tscn"},
	{"label": "カットシーン：FLIP LAB導入", "path": "res://scenes/ui/Cutscene_FlipLab.tscn"},
	{"label": "カットシーン：WIRE BAY導入", "path": "res://scenes/ui/Cutscene_WireBay.tscn"},
	{"label": "カットシーン：SIZE DOCK導入", "path": "res://scenes/ui/Cutscene_SizeDock.tscn"},
	{"label": "カットシーン：OOPS core導入", "path": "res://scenes/ui/Cutscene_OOPSCore.tscn"},
	{"label": "カットシーン：エンディング前半", "path": "res://scenes/ui/Cutscene_EndingPart1.tscn"},
	{"label": "カットシーン：エンディング後半", "path": "res://scenes/ui/Cutscene_EndingPart2.tscn"},
	{"label": "カットシーン：エンディング最終", "path": "res://scenes/ui/Cutscene_EndingPart3.tscn"},
]

@onready var _button_container: VBoxContainer = $CenterContainer/VBoxContainer/ButtonContainer

func _ready() -> void:
	for stage in STAGES:
		if stage["path"] == "":
			# 見出し代わりの区切り（押せないラベル）
			var label := Label.new()
			label.text = stage["label"]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_button_container.add_child(label)
			continue
		var btn := Button.new()
		btn.text = stage["label"]
		btn.custom_minimum_size = Vector2(320, 48)
		btn.pressed.connect(_on_stage_pressed.bind(stage["path"]))
		_button_container.add_child(btn)

func _on_stage_pressed(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

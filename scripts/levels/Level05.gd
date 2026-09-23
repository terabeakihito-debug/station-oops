extends Node2D
## Level_05_OOPSCore
## 最終ボス戦アリーナ。ヒント（HintObject×4、N-A-M-Eのおまけ）はあくまで
## 任意収集で、対決の開始条件ではない。プレイヤーがNOAにインタラクトすると
## フェーズ2（クイズ）が始まり、以降フェーズ3（クロスワード）→撃破と進む。

const SOURCE_STAGE0 := 0
const QUIZ_UI_SCENE := preload("res://scenes/ui/QuizUI.tscn")
const CROSSWORD_UI_SCENE := preload("res://scenes/ui/CrosswordUI.tscn")
const ENDING_DELAY: float = 2.0

@onready var _ground: TileMapLayer = $Ground
@onready var _noa: CharacterBody2D = $NOA

func _ready() -> void:
	MusicManager.play_track("oops_core")
	_build_ground()
	_noa.confrontation_requested.connect(_on_confrontation_requested)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	_show_boss_intro()

func _show_boss_intro() -> void:
	## 「これがラスボス戦だ」と一目で分かるよう、開始時に警告バナーを
	## 一時的に表示する（黒背景＋赤文字、フェードイン→保持→フェードアウト）。
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	layer.add_child(bg)

	var label := Label.new()
	label.text = "警告：最終防衛システム『NOA』起動"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.modulate = Color(1.0, 0.25, 0.25)
	var label_settings := LabelSettings.new()
	label_settings.font_size = 40
	label_settings.outline_size = 8
	label_settings.outline_color = Color(0.05, 0.02, 0.02)
	label.label_settings = label_settings
	label.modulate.a = 0.0
	layer.add_child(label)

	var tween := create_tween()
	tween.tween_property(bg, "color:a", 0.6, 0.4)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.4)
	tween.tween_interval(1.8)
	tween.tween_property(bg, "color:a", 0.0, 0.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)

func _build_ground() -> void:
	for x in range(10):
		_ground.set_cell(Vector2i(x, 5), SOURCE_STAGE0, Vector2i(0, 0))
	# 対決中に動き回れる余地を増やすための小さな足場（横幅は広げず、縦の
	# 移動先を追加する）。背景が非スクロール仕様のため部屋の横幅は変えない。
	# ※NOAの位置（x=950, y=500）と重ならないよう、左側のみに配置している。
	for x in range(1, 3):
		_ground.set_cell(Vector2i(x, 4), SOURCE_STAGE0, Vector2i(0, 0))

func _on_confrontation_requested() -> void:
	_noa.enter_phase_2()
	_start_quiz()

func _start_quiz() -> void:
	var quiz := QUIZ_UI_SCENE.instantiate()
	quiz.noa_ref = _noa
	add_child(quiz)
	quiz.quiz_completed.connect(_on_quiz_completed)

func _on_quiz_completed() -> void:
	_noa.enter_phase_3()
	_start_crossword()

func _start_crossword() -> void:
	var crossword := CROSSWORD_UI_SCENE.instantiate()
	add_child(crossword)
	crossword.crossword_completed.connect(_on_crossword_completed)

func _on_crossword_completed() -> void:
	_noa.defeat()

func _on_boss_defeated() -> void:
	# defeatアニメーションを少し見せてからエンディングカットシーン（前半→後半）へ
	await get_tree().create_timer(ENDING_DELAY).timeout
	get_tree().change_scene_to_file("res://scenes/ui/Cutscene_EndingPart1.tscn")


extends CanvasLayer
## QuizUI
## OOPS core フェーズ2：バズァークイズ（雑学3問、制限時間内の早押し選択式）。
## 全問終了後にquiz_completedシグナルを発火して自身を消滅させる。
## 正解/不正解にかかわらず3問終われば次フェーズへ進む（テンポ重視の設計）。

signal quiz_completed

const TIME_LIMIT: float = 8.0
const RESULT_PAUSE: float = 1.2

const QUESTIONS := [
	{
		"question": "1年は何日？（うるう年を除く）",
		"choices": ["364日", "365日", "366日", "360日"],
		"correct": 1,
	},
	{
		"question": "水の化学式は？",
		"choices": ["CO2", "H2O", "O2", "NaCl"],
		"correct": 1,
	},
	{
		"question": "日本の首都は？",
		"choices": ["大阪", "京都", "東京", "名古屋"],
		"correct": 2,
	},
]

var noa_ref: Node = null

@onready var _question_label: Label = $CenterContainer/Panel/VBoxContainer/QuestionLabel
@onready var _choices_container: VBoxContainer = $CenterContainer/Panel/VBoxContainer/ChoicesContainer
@onready var _timer_bar: ProgressBar = $CenterContainer/Panel/VBoxContainer/TimerBar
@onready var _result_label: Label = $CenterContainer/Panel/VBoxContainer/ResultLabel

var _current_index: int = 0
var _time_left: float = 0.0
var _answered: bool = false
var _choice_buttons: Array[Button] = []

func _ready() -> void:
	_show_question(0)

func _process(delta: float) -> void:
	if _answered:
		return
	_time_left -= delta
	_timer_bar.value = max(_time_left, 0.0)
	if _time_left <= 0.0:
		_on_answer_selected(-1) # 時間切れ＝不正解扱い

func _show_question(index: int) -> void:
	_current_index = index
	_answered = false
	_result_label.text = ""
	var q: Dictionary = QUESTIONS[index]
	_question_label.text = "Q%d. %s" % [index + 1, q["question"]]
	_time_left = TIME_LIMIT
	_timer_bar.max_value = TIME_LIMIT
	_timer_bar.value = TIME_LIMIT

	for child in _choices_container.get_children():
		child.queue_free()
	_choice_buttons.clear()

	var choices: Array = q["choices"]
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i]
		btn.custom_minimum_size = Vector2(500, 56)
		btn.focus_mode = Control.FOCUS_ALL
		btn.add_theme_font_size_override("font_size", 22)
		btn.add_theme_color_override("font_color", Color(0.9, 0.98, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.08, 0.1))
		btn.add_theme_color_override("font_disabled_color", Color(0.75, 0.85, 0.86))
		btn.add_theme_stylebox_override("normal", _choice_style(Color(0.08, 0.18, 0.21, 0.98), Color(0.25, 0.48, 0.5, 0.9)))
		btn.add_theme_stylebox_override("hover", _choice_style(Color(0.12, 0.34, 0.35, 1.0), Color(0.45, 0.95, 0.86, 1.0)))
		btn.add_theme_stylebox_override("pressed", _choice_style(Color(0.4, 0.88, 0.78, 1.0), Color(0.7, 1.0, 0.94, 1.0)))
		btn.add_theme_stylebox_override("focus", _choice_style(Color(0.12, 0.34, 0.35, 1.0), Color(1.0, 0.86, 0.36, 1.0)))
		btn.add_theme_stylebox_override("disabled", _choice_style(Color(0.12, 0.17, 0.18, 0.98), Color(0.25, 0.35, 0.36, 0.9)))
		btn.pressed.connect(_on_answer_selected.bind(i))
		_choices_container.add_child(btn)
		_choice_buttons.append(btn)

	# マウスを使わなくても、最初の選択肢から上下キーで移動できるようにする。
	if not _choice_buttons.is_empty():
		_choice_buttons[0].call_deferred("grab_focus")

func _choice_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	return style

func _on_answer_selected(choice_index: int) -> void:
	if _answered:
		return
	_answered = true
	for btn in _choice_buttons:
		btn.disabled = true
	var q: Dictionary = QUESTIONS[_current_index]
	var is_correct: bool = choice_index == q["correct"]
	_result_label.text = "正解！" if is_correct else ("時間切れ…" if choice_index < 0 else "不正解…")
	if noa_ref and noa_ref.has_method("play_quiz_reaction"):
		noa_ref.play_quiz_reaction(is_correct)
	await get_tree().create_timer(RESULT_PAUSE).timeout
	if _current_index + 1 < QUESTIONS.size():
		_show_question(_current_index + 1)
	else:
		quiz_completed.emit()
		queue_free()

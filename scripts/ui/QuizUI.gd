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

@onready var _question_label: Label = $CenterContainer/VBoxContainer/QuestionLabel
@onready var _choices_container: VBoxContainer = $CenterContainer/VBoxContainer/ChoicesContainer
@onready var _timer_bar: ProgressBar = $CenterContainer/VBoxContainer/TimerBar
@onready var _result_label: Label = $CenterContainer/VBoxContainer/ResultLabel

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
		btn.custom_minimum_size = Vector2(320, 48)
		btn.pressed.connect(_on_answer_selected.bind(i))
		_choices_container.add_child(btn)
		_choice_buttons.append(btn)

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

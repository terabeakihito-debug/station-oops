extends CanvasLayer
## TimerHUD
## 画面固定のタイマー表示。EventBus.puzzle_timer_started/stoppedを購読し、
## どのオブジェクト（配線盤面・ワイヤー足場・スイッチ等）のタイマーが動いていても
## プレイヤーの現在位置に関係なく常に見えるようにする。
## 複数のタイマーが重なった場合は、最後に開始されたものを表示する。

@onready var _label: Label = $Panel/VBoxContainer/Label
@onready var _progress: ProgressBar = $Panel/VBoxContainer/ProgressBar
@onready var _panel: Control = $Panel

var _duration: float = 0.0
var _remaining: float = 0.0
var _running: bool = false

func _ready() -> void:
	_panel.visible = false
	EventBus.puzzle_timer_started.connect(_on_timer_started)
	EventBus.puzzle_timer_stopped.connect(_on_timer_stopped)

func _process(delta: float) -> void:
	if not _running:
		return
	_remaining = max(_remaining - delta, 0.0)
	_progress.value = _remaining
	_label.text = "%s  %.1f" % [_label_text, _remaining]
	if _remaining <= 0.0:
		_running = false

var _label_text: String = ""

func _on_timer_started(label_text: String, duration: float) -> void:
	_label_text = label_text
	_duration = duration
	_remaining = duration
	_progress.max_value = duration
	_progress.value = duration
	_panel.visible = true
	_running = true

func _on_timer_stopped() -> void:
	_running = false
	_panel.visible = false

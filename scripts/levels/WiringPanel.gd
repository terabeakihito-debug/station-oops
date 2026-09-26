extends Area2D
## WiringPanel
## WIRE BAYのパズルの起点。アイコン＋色（modulate）とグローで状態を表現する
## （未通電=暗い青、通電中=明るい黄色、ミス時=赤い点滅）。インタラクトすると
## 数秒間「通電中」になり、残り秒数をカウントダウン表示。その間にPowerSwitchを
## オンにできれば成功。時間切れになるとミス演出（赤い点滅）を再生して元に戻る。
## プレイヤーが近づくと「E」プロンプトを表示する。

signal power_state_changed(powered: bool)

@export var power_duration: float = 9.0 ## 通電が持続する秒数
@export var miss_display_duration: float = 2.0 ## ミス演出を見せる秒数

const COLOR_IDLE := Color(0.45, 0.55, 0.75)
const COLOR_POWERED := Color(1.2, 1.05, 0.35)
const COLOR_MISS := Color(1.1, 0.25, 0.25)
const LIGHT_IDLE := Color(0.3, 0.4, 0.6)
const LIGHT_POWERED := Color(1.0, 0.9, 0.3)
const LIGHT_MISS := Color(1.0, 0.2, 0.2)

var is_powered: bool = false

@onready var _icon: Sprite2D = $Icon
@onready var _prompt_label: Label = $PromptLabel
@onready var _light: PointLight2D = $Light
@onready var _power_timer: Timer = $PowerTimer
@onready var _status_bar: Polygon2D = $StatusBar

func _ready() -> void:
	_icon.modulate = COLOR_IDLE
	_status_bar.color = COLOR_IDLE
	_prompt_label.visible = false
	_light.color = LIGHT_IDLE
	_light.energy = 0.2
	_power_timer.one_shot = true
	_power_timer.timeout.connect(_on_power_timeout)

func show_prompt() -> void:
	if not is_powered:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func get_remaining() -> float:
	return _power_timer.time_left if is_powered else 0.0

func on_interact() -> void:
	if is_powered:
		return
	_start_power()

func _start_power() -> void:
	is_powered = true
	_prompt_label.visible = false
	_icon.modulate = COLOR_POWERED
	_status_bar.color = COLOR_POWERED
	_light.color = LIGHT_POWERED
	_light.energy = 1.4
	power_state_changed.emit(true)
	_power_timer.start(power_duration)
	EventBus.puzzle_timer_started.emit("配線盤面：通電中", power_duration)

func _on_power_timeout() -> void:
	if is_powered:
		_fail()

func consume_power() -> bool:
	## PowerSwitch側から呼ばれる。通電中であればtrueを返し、消費して非通電に戻す。
	if not is_powered:
		return false
	is_powered = false
	_power_timer.stop()
	_icon.modulate = COLOR_IDLE
	_status_bar.color = COLOR_IDLE
	_light.color = LIGHT_IDLE
	_light.energy = 0.2
	power_state_changed.emit(false)
	EventBus.puzzle_timer_stopped.emit()
	return true

func _fail() -> void:
	is_powered = false
	power_state_changed.emit(false)
	EventBus.puzzle_timer_stopped.emit()
	_icon.modulate = COLOR_MISS
	_status_bar.color = COLOR_MISS
	_light.color = LIGHT_MISS
	_light.energy = 1.0
	var tween := create_tween()
	tween.set_loops(4)
	tween.tween_property(_light, "energy", 0.2, 0.25)
	tween.tween_property(_light, "energy", 1.0, 0.25)
	await get_tree().create_timer(miss_display_duration).timeout
	_icon.modulate = COLOR_IDLE
	_status_bar.color = COLOR_IDLE
	_light.color = LIGHT_IDLE
	_light.energy = 0.2

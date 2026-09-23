extends Area2D
## PowerSwitch
## WIRE BAY等に置く電力復旧スイッチ。アイコン＋色（modulate）とグローで
## 状態を表現する（OFF=グレー、ON=明るい緑）。
## wiring_panel_pathで指定したWiringPanelが「通電中」でなければ反応しない
## （配線盤面のパズルと連動させるため）。通電していない時にインタラクトすると
## 赤い点滅＋「NOT POWERED」表示で、失敗したことが分かるようにしている。
## プレイヤーが近づくと「E」プロンプトを表示し、ON成功時は一瞬強く光る。
##
## ONになった瞬間、door_open_duration秒のカウントダウンが新たに始まる
## （表示はスイッチ上のラベルを流用）。この間にドアへ辿り着けなければ
## door_timeoutを発する。レベル側でこれを受けてドアを再施錠し、
## スイッチもreset()でOFFに戻す想定（＝配線盤面からやり直し）。

signal switched_on
signal door_timeout

@export var wiring_panel_path: NodePath
@export var door_open_duration: float = 8.0 ## ON後、ドアに辿り着くまでの猶予秒数

const COLOR_OFF := Color(0.55, 0.58, 0.55)
const COLOR_ON := Color(0.35, 1.1, 0.55)
const LIGHT_OFF := Color(0.4, 0.4, 0.4)
const LIGHT_ON := Color(0.4, 1.0, 0.6)

var _is_on: bool = false
var _wiring_panel: Node = null

@onready var _icon: Sprite2D = $Icon
@onready var _denied_label: Label = $DeniedLabel
@onready var _prompt_label: Label = $PromptLabel
@onready var _light: PointLight2D = $Light
@onready var _flash: Sprite2D = $Flash
@onready var _door_timer: Timer = $DoorTimer

func _ready() -> void:
	_icon.modulate = COLOR_OFF
	_denied_label.visible = false
	_prompt_label.visible = false
	_light.color = LIGHT_OFF
	_light.energy = 0.2
	_flash.modulate.a = 0.0
	_door_timer.one_shot = true
	_door_timer.timeout.connect(_on_door_timeout)
	if wiring_panel_path != NodePath():
		_wiring_panel = get_node(wiring_panel_path)

func show_prompt() -> void:
	if not _is_on:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func on_interact() -> void:
	if _is_on:
		return
	if _wiring_panel and _wiring_panel.has_method("consume_power"):
		if not _wiring_panel.consume_power():
			_show_denied()
			return
	_is_on = true
	_prompt_label.visible = false
	var tween := create_tween()
	tween.tween_property(_icon, "modulate", COLOR_ON, 0.3)
	tween.tween_callback(_on_switched_on)

func _on_switched_on() -> void:
	_light.color = LIGHT_ON
	_light.energy = 1.5
	_play_success_flash()
	_door_timer.start(door_open_duration)
	EventBus.puzzle_timer_started.emit("ドアへ急げ", door_open_duration)
	switched_on.emit()

func _on_door_timeout() -> void:
	## ドアに間に合わなかった。スイッチをOFFに戻し、レベル側にも知らせる
	## （ドアの再施錠はレベル側で行う）。
	EventBus.puzzle_timer_stopped.emit()
	reset()
	door_timeout.emit()

func _show_denied() -> void:
	_denied_label.visible = true
	var tween := create_tween()
	tween.tween_property(_icon, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(_icon, "modulate", COLOR_OFF, 0.1)
	tween.tween_property(_icon, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(_icon, "modulate", COLOR_OFF, 0.1)
	await get_tree().create_timer(1.0).timeout
	_denied_label.visible = false

func _play_success_flash() -> void:
	## 成功した瞬間に一度だけ強く光ってから落ち着く演出。
	_flash.modulate.a = 1.0
	_flash.scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_flash, "scale", Vector2(1.6, 1.6), 0.4)
	tween.tween_property(_flash, "modulate:a", 0.0, 0.4)

func reset() -> void:
	## デバッグ・再挑戦用。ONの状態を強制的にOFFへ戻す。
	_is_on = false
	_door_timer.stop()
	_icon.modulate = COLOR_OFF
	_light.color = LIGHT_OFF
	_light.energy = 0.2

extends Area2D
## WireHook
## WIRE BAYのコアギミック。プレイヤーがインタラクトすると、
## ワイヤーで繋がった WirePlatform を引き寄せる。
## 引き寄せ中はプレイヤーの`pull`アニメーションを一時ロックする。
## 引き寄せてからreturn_delay秒後、自動的に元の位置へ戻り、再度引き寄せ可能になる。
## 使用中はアイコンを少し暗くして「今は使えない」を表現する。

@export var platform_path: NodePath
@export var pull_duration: float = 1.0
@export var pull_offset: Vector2 = Vector2(-300, 0) ## 足場の移動量（フック基準の相対座標）
@export var return_delay: float = 6.0 ## 引き寄せてから自動で元に戻るまでの秒数

const COLOR_READY := Color(1, 1, 1)
const COLOR_BUSY := Color(0.45, 0.45, 0.45)

var _pulled: bool = false
var _platform: Node2D

@onready var _wire_line: Line2D = $WireLine
@onready var _prompt_label: Label = $PromptLabel
@onready var _icon: Sprite2D = $Icon

func _ready() -> void:
	if platform_path != NodePath():
		_platform = get_node(platform_path)
	_update_wire()
	_prompt_label.visible = false
	_icon.modulate = COLOR_READY

func _process(_delta: float) -> void:
	_update_wire()

func show_prompt() -> void:
	if not _pulled:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func on_interact() -> void:
	if _pulled or _platform == null:
		return
	_pulled = true
	_prompt_label.visible = false
	_icon.modulate = COLOR_BUSY
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("lock_animation"):
		player.lock_animation("pull_pixel", pull_duration)
	var start_pos: Vector2 = _platform.position
	var end_pos: Vector2 = start_pos + pull_offset
	var tween := create_tween()
	tween.tween_method(_set_platform_position, start_pos, end_pos, pull_duration)
	tween.tween_callback(_start_auto_return.bind(start_pos, end_pos))

func _start_auto_return(start_pos: Vector2, end_pos: Vector2) -> void:
	EventBus.puzzle_timer_started.emit("足場：自動で戻るまで", return_delay)
	await get_tree().create_timer(return_delay).timeout
	EventBus.puzzle_timer_stopped.emit()
	var tween := create_tween()
	tween.tween_method(_set_platform_position, end_pos, start_pos, pull_duration)
	tween.tween_callback(func():
		_pulled = false
		_icon.modulate = COLOR_READY
	)

func _set_platform_position(pos: Vector2) -> void:
	_platform.position = pos

func _update_wire() -> void:
	if _platform == null:
		return
	_wire_line.points = PackedVector2Array([Vector2.ZERO, to_local(_platform.global_position)])

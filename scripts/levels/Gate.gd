extends StaticBody2D
## Gate
## 通路を塞ぐバリア。unlock_modeが"scan"ならECHOのスキャン（Qキー）で、
## "interact"ならインタラクト（Eキー）で、"big"なら巨大化した状態で
## 触れると開く。開くまでは物理的に通れないため、プレイヤーは必ずその
## 条件を満たすことになる。
## ロック中は脈動するエネルギーフィールドの演出、解除時は白く光って
## 弾けるように消える演出＋「OPEN」表示で、解除が起きたことを明確にする。

signal opened

@export_enum("scan", "interact", "small", "big") var unlock_mode: String = "scan"
@export var barrier_scan_tex: Texture2D
@export var barrier_interact_tex: Texture2D
@export var barrier_big_tex: Texture2D

var _opened: bool = false
var _idle_tween: Tween

@onready var _visual: Sprite2D = $Visual
@onready var _label: Label = $Label
@onready var _prompt_label: Label = $PromptLabel
@onready var _flash: Sprite2D = $Flash
@onready var _size_detector: Area2D = $SizeDetector

func _ready() -> void:
	_prompt_label.visible = false
	match unlock_mode:
		"scan":
			_label.text = "スキャンでしか開かない（Qキー）"
			_visual.texture = barrier_scan_tex
		"interact":
			_label.text = "インタラクトしないと開かない（Eキー）"
			_visual.texture = barrier_interact_tex
		"small":
			_label.text = "縮小しないと開かない"
			_visual.texture = barrier_big_tex
			_size_detector.body_entered.connect(_on_size_body_entered)
		"big":
			_label.text = "巨大化しないと開かない"
			_visual.texture = barrier_big_tex
			_size_detector.body_entered.connect(_on_size_body_entered)
	_flash.modulate.a = 0.0
	_start_idle_pulse()

func _on_size_body_entered(body: Node) -> void:
	if _opened:
		return
	if "size_mode" in body and ((unlock_mode == "small" and body.size_mode == "small") or (unlock_mode == "big" and body.size_mode == "big")):
		_open()

func _start_idle_pulse() -> void:
	## ロック中は明滅させて「作動中のエネルギーフィールド」に見せる。
	_idle_tween = create_tween()
	_idle_tween.set_loops()
	_idle_tween.tween_property(_visual, "modulate:a", 0.55, 0.6)
	_idle_tween.tween_property(_visual, "modulate:a", 1.0, 0.6)

func on_scanned() -> void:
	if _opened:
		return
	if unlock_mode != "scan":
		_show_wrong_method_hint()
		return
	_open()

func on_interact() -> void:
	if _opened:
		return
	if unlock_mode != "interact":
		_show_wrong_method_hint()
		return
	_open()

func _show_wrong_method_hint() -> void:
	## 間違った操作（scanゲートにEを押した等）をした時、無反応にせず
	## 「必要な操作」を一瞬強調して示す。
	var original_color := _label.modulate
	var tween := create_tween()
	tween.tween_property(_label, "modulate", Color(1.0, 0.4, 0.4), 0.1)
	tween.tween_property(_label, "modulate", Color(1.0, 1.0, 0.3), 0.1)
	tween.tween_property(_label, "modulate", Color(1.0, 0.4, 0.4), 0.1)
	tween.tween_property(_label, "modulate", original_color, 0.1)

func show_prompt() -> void:
	if unlock_mode == "interact" and not _opened:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func _open() -> void:
	_opened = true
	_prompt_label.visible = false
	if _idle_tween:
		_idle_tween.kill()

	# 解除が起きたことをはっきり示すための一連の演出：
	# 1. バリア全体が白く強く光る
	# 2. 「OPEN」の文字に切り替えて明るく表示
	# 3. バリアが弾けるように縮小・拡散して消える
	_label.text = "OPEN"
	_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))

	var flash_tween := create_tween()
	flash_tween.tween_property(_visual, "modulate", Color(2.5, 2.5, 2.5, 1.0), 0.12)
	await flash_tween.finished

	# 収集した位置に光の破裂エフェクト（Flashスプライトを利用）
	_flash.modulate.a = 1.0
	_flash.scale = Vector2(0.4, 0.4)
	var burst_tween := create_tween()
	burst_tween.set_parallel(true)
	burst_tween.tween_property(_flash, "scale", Vector2(2.2, 2.2), 0.4)
	burst_tween.tween_property(_flash, "modulate:a", 0.0, 0.4)
	burst_tween.tween_property(_visual, "scale", Vector2(0.05, 1.0), 0.3)
	burst_tween.tween_property(_visual, "modulate:a", 0.0, 0.3)
	burst_tween.tween_property(_label, "modulate:a", 0.0, 0.5)
	await burst_tween.finished

	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	_label.visible = false
	opened.emit()

extends Area2D
## InfoTerminal
## チュートリアル用の「隠れた端末」。最初は起動しておらず見た目も控えめで、
## ECHOでスキャン（Qキー）すると起動して初めてインタラクト（Eキー）できる
## ようになる。ジャンプ以外の操作（スキャン・インタラクト）を実際に
##使う場面がチュートリアルに無かったため、導入区画に配置している。

@export var message: String = "ECHOのスキャンでインタラクト可能なものが見つかることがある。"

var _revealed: bool = false
var _shown: bool = false

@onready var _icon: Sprite2D = $Icon
@onready var _prompt_label: Label = $PromptLabel
@onready var _message_label: Label = $MessageLabel
@onready var _light: PointLight2D = $Light

func _ready() -> void:
	_icon.modulate = Color(0.4, 0.4, 0.4, 0.5)
	_prompt_label.visible = false
	_message_label.visible = false
	_light.energy = 0.0

func on_scanned() -> void:
	if _revealed:
		return
	_revealed = true
	var tween := create_tween()
	tween.tween_property(_icon, "modulate", Color(0.5, 0.9, 1.0, 1.0), 0.4)
	tween.parallel().tween_property(_light, "energy", 1.0, 0.4)

func show_prompt() -> void:
	if _revealed and not _shown:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func on_interact() -> void:
	if not _revealed or _shown:
		return
	_shown = true
	_prompt_label.visible = false
	_message_label.visible = true
	_message_label.text = message

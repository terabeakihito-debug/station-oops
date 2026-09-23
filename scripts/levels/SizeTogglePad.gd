extends Area2D
## SizeTogglePad
## SIZE DOCKのコアギミック。触れたキャラクターの大きさをtarget_modeで
## 指定した大きさに変更する（`set_size_mode()`を持つノードに対して呼び出す）。
## 見た目は3種類の専用テクスチャ（縮小=青、通常=緑、巨大化=オレンジ）を
## target_modeに応じて切り替える。GlowOutlineの発光色も同じ色味に揃える。

@export_enum("small", "normal", "big") var target_mode: String = "small"
@export var pad_small_tex: Texture2D
@export var pad_normal_tex: Texture2D
@export var pad_big_tex: Texture2D

@onready var _visual: Polygon2D = $Visual
@onready var _glow: Polygon2D = $GlowOutline

const GLOW_SMALL := Color(0.55, 0.75, 1.0, 0.6)
const GLOW_NORMAL := Color(0.55, 0.9, 0.6, 0.6)
const GLOW_BIG := Color(1.0, 0.65, 0.4, 0.6)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_visual.color = Color(1, 1, 1, 1)
	match target_mode:
		"small":
			_visual.texture = pad_small_tex
			_glow.color = GLOW_SMALL
		"big":
			_visual.texture = pad_big_tex
			_glow.color = GLOW_BIG
		_:
			_visual.texture = pad_normal_tex
			_glow.color = GLOW_NORMAL

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_size_mode"):
		body.set_size_mode(target_mode)

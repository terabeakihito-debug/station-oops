extends StaticBody2D
## HintObject
## OOPS core フェーズ1で破壊する対象。アイコン（謎めいた「？」の箱）で
## 表示し、破壊されるとヒント文字をGameManagerに通知、実際の文字を
## はっきり表示してから消滅する。

@export var hint_letter: String = "?"
@export var health: int = 20

@onready var _icon: Sprite2D = $Icon
@onready var _label: Label = $Label

var _destroyed: bool = false
const COLOR_NORMAL := Color(1, 1, 1)
const COLOR_FLASH := Color(1.6, 1.6, 1.6)

func _ready() -> void:
	_icon.modulate = COLOR_NORMAL
	_label.text = ""

func take_damage(amount: int) -> void:
	if _destroyed:
		return
	health -= amount
	_flash_hit()
	if health <= 0:
		_destroy()

func _flash_hit() -> void:
	var tween := create_tween()
	tween.tween_property(_icon, "modulate", COLOR_FLASH, 0.05)
	tween.tween_property(_icon, "modulate", COLOR_NORMAL, 0.15)

func _destroy() -> void:
	_destroyed = true
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	# アイコンは文字が大きくなるのに合わせて縮みながらフェードアウトする
	# （「箱が割れて中身が出てきた」ように見せる）。
	_label.text = hint_letter
	_label.add_theme_color_override("font_color", Color(1, 1, 0.4))
	_label.add_theme_font_size_override("font_size", 40)
	_label.scale = Vector2(1.0, 1.0)
	_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_label, "scale", Vector2(1.8, 1.8), 0.2)
	tween.parallel().tween_property(_icon, "scale", _icon.scale * 0.2, 0.2)
	tween.parallel().tween_property(_icon, "modulate:a", 0.0, 0.2)
	tween.tween_interval(0.7) # ここで文字がはっきり見える状態を保持する
	tween.tween_property(_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	# 演出が終わってからヒント収集を通知する（最後の1個で即座に
	# 次フェーズへ進んでしまい、演出が見えなくなるのを防ぐため）。
	GameManager.collect_hint(hint_letter)
	queue_free()

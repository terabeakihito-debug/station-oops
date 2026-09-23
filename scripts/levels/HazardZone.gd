extends Area2D
## HazardZone
## SIZE DOCK用：小さくならないと通れない「危険地帯」。
## 物理的に通行を塞ぐわけではないが、size_modeが"small"でない状態で
## 触れるとダメージを受ける（＝縮小する意味を持たせるためのギミック）。
## 一度当たったら短いクールダウンを設け、同じ場所で連続ダメージを受け
## 続けないようにしている。

@export var damage: int = 15
@export var cooldown: float = 1.0

var _last_hit_time: float = -999.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if not ("size_mode" in body):
		return
	if body.size_mode == "small":
		return # 小さければ安全に通過できる
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < cooldown:
		return
	_last_hit_time = now
	if body.has_method("take_damage"):
		body.take_damage(damage)
	_flash_warning()

func _flash_warning() -> void:
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color(2.0, 2.0, 0.6), 0.08)
	tween.tween_property(_sprite, "modulate", Color(1, 1, 1), 0.15)

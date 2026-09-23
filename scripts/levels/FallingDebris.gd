extends Node2D
## FallingDebris
## FLIP LAB用の落下ギミック。天井付近で待機し、一定間隔ごとに
## 赤く点滅して予告→落下→着地後しばらくしてから元の位置へ戻る、を繰り返す。
## 落下中・着地時にプレイヤーと重なるとダメージを与える。
## プレイヤーの現在の重力方向（gravity_dir）を参照し、通常時は下（+y）へ、
## プレイヤーが反転中は逆方向（-y、天井側）へ落ちる。「どちらの床を歩いていても
## 同じガラクタに狙われる」形で、反転ギミックと連動させている。

@export var fall_interval: float = 4.0 ## 次の落下までの待機時間（秒）
@export var warning_time: float = 0.8 ## 落下前の点滅予告時間（秒）
@export var fall_distance: float = 400.0 ## 落下する距離（px）
@export var fall_duration: float = 0.4 ## 落下にかかる時間（秒）
@export var reset_delay: float = 1.2 ## 着地後、元の位置に戻るまでの待機時間（秒）
@export var damage: int = 10

var _origin_y: float
var _player: Node2D = null

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _hit_area: Area2D = $HitArea

func _ready() -> void:
	_origin_y = position.y
	_player = get_tree().get_first_node_in_group("player")
	_run_cycle()

func _run_cycle() -> void:
	while true:
		await get_tree().create_timer(fall_interval).timeout
		await _warn()
		await _fall()
		_check_hit()
		await get_tree().create_timer(reset_delay).timeout
		_reset()

func _warn() -> void:
	var tween := create_tween()
	tween.set_loops(4)
	tween.tween_property(_sprite, "modulate", Color(1.4, 0.4, 0.4), warning_time / 8.0)
	tween.tween_property(_sprite, "modulate", Color(1, 1, 1), warning_time / 8.0)
	await tween.finished

func _fall() -> void:
	# プレイヤーが今どちらの重力方向にいるかで、落ちる向きを合わせる。
	var dir_sign := 1.0
	if _player and "gravity_dir" in _player:
		dir_sign = float(_player.gravity_dir)
	var tween := create_tween()
	tween.tween_property(self, "position:y", _origin_y + fall_distance * dir_sign, fall_duration)
	await tween.finished

func _check_hit() -> void:
	for body in _hit_area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)

func _reset() -> void:
	position.y = _origin_y
	_sprite.modulate = Color(1, 1, 1)

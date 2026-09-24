extends Area2D

## リフト間を遮る放電帯。消えた瞬間だけジャンプで抜けられる。
@export var active_time: float = 0.75
@export var rest_time: float = 0.65
@export var damage: int = 12

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _lines: Array[Line2D] = [$ArcA, $ArcB]
var _last_hit_time := -999.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_run_cycle()


func _run_cycle() -> void:
	while is_inside_tree():
		_set_active(true)
		await get_tree().create_timer(active_time).timeout
		_set_active(false)
		await get_tree().create_timer(rest_time).timeout


func _set_active(active: bool) -> void:
	_collision.set_deferred("disabled", not active)
	for line in _lines:
		line.visible = active


func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < 0.8:
		return
	_last_hit_time = now
	body.take_damage(damage)

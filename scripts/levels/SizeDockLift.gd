extends AnimatableBody2D

## SIZE DOCKの貨物リフト。穴を渡るためのタイミングを作る。
@export var travel_distance: float = 96.0
@export var travel_time: float = 1.4
@export var pause_time: float = 0.35

var _start_y: float


func _ready() -> void:
	_start_y = position.y
	_run_cycle()


func _run_cycle() -> void:
	while is_inside_tree():
		await _move_to(_start_y - travel_distance)
		await get_tree().create_timer(pause_time).timeout
		await _move_to(_start_y)
		await get_tree().create_timer(pause_time).timeout


func _move_to(target_y: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", target_y, travel_time)
	await tween.finished

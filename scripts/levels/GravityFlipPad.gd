extends Area2D
## GravityFlipPad
## FLIP LABのコアギミック。触れたキャラクターの重力方向を反転させる
## （`toggle_gravity()`を持つノードに対して呼び出す）。

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("toggle_gravity"):
		body.toggle_gravity()

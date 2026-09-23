extends Area2D
## Ladder
## 特定ステージ専用ではなく、各ステージに縦の広がりを持たせるための
## 汎用ギミック。プレイヤーが重なっている間だけ登り降りモードになる
## （set_climbing()を持つ相手に対して呼び出す）。

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_climbing"):
		body.set_climbing(true)

func _on_body_exited(body: Node) -> void:
	if body.has_method("set_climbing"):
		body.set_climbing(false)

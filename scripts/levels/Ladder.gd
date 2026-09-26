extends Area2D
## Ladder
## 特定ステージ専用ではなく、各ステージに縦の広がりを持たせるための
## 汎用ギミック。プレイヤーが重なっている間だけ登り降りモードになる
## （set_climbing()を持つ相手に対して呼び出す）。

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	# 見た目の足先が梯子の上端へ届いた時点で終了する。
	# body_exited待ちだと、キャラクターの胴体がまだArea2D内に残り、
	# 上端でclimbポーズが止まって見える。
	var ladder_shape := $CollisionShape2D.shape as RectangleShape2D
	if ladder_shape == null:
		return
	var top_y := global_position.y - ladder_shape.size.y * 0.5
	var bottom_y := global_position.y + ladder_shape.size.y * 0.5
	for body in get_overlapping_bodies():
		if not body.has_method("set_climbing") or not bool(body.get("is_climbing")):
			continue
		var body_shape := body.get_node_or_null("CollisionShape2D")
		var half_height := 28.0
		if body_shape != null and body_shape.shape is RectangleShape2D:
			half_height = (body_shape.shape as RectangleShape2D).size.y * 0.5
		var gravity_dir := int(body.get("gravity_dir"))
		var reached_exit := body.global_position.y <= top_y - half_height if gravity_dir > 0 else body.global_position.y >= bottom_y + half_height
		if reached_exit:
			# 登り切り開始位置を足場の高さへ固定し、宙に残さない。
			body.global_position.y = top_y - half_height if gravity_dir > 0 else bottom_y + half_height
			if body is CharacterBody2D:
				body.velocity.y = 0.0
			body.set_climbing(false)

func _on_body_entered(body: Node) -> void:
	if body.has_method("set_climbing"):
		body.set_climbing(true)

func _on_body_exited(body: Node) -> void:
	if body.has_method("set_climbing"):
		body.set_climbing(false)

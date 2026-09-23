extends Area2D
## FallZone
## 各ステージ共通の「落下判定」エリア。床の隙間から落ちた先、
## 画面外の下方に配置する。プレイヤーが触れた瞬間に即座に
## on_fall_death()を呼ぶ（時間や距離による推測は行わない）。

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("on_fall_death"):
		body.on_fall_death()

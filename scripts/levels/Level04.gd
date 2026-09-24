extends Node2D
## Level_04_SizeDock
## サイズ切替ギミックのステージ。低い通路があり、小さくならないと通れない。
## 中盤に階段状の縦移動区間（staircase_assembled）と、飛び越える木箱の山
## （crate_pile_assembled）を配置している。終盤にもう一つ、木箱（単体）を
## 使った縮小必須の低い通路がある。
## さらにその先、①小さくならないとダメージを受ける火花地帯、②巨大化しないと
## 開かないゲート、の2つの新しい区画を追加している。

const SOURCE_SIZEDOCK := 3

@onready var _ground: TileMapLayer = $Ground

func _ready() -> void:
	MusicManager.play_track("size_dock")
	_build_ground()

func _build_ground() -> void:
	for x in range(32):
		# 階段前と危険区間に短い穴を作り、サイズ操作だけでなく
		# ジャンプの判断も必要にする。
		if x == 11 or x == 22 or x == 24:
			continue
		_ground.set_cell(Vector2i(x, 5), SOURCE_SIZEDOCK, Vector2i(0, 0))

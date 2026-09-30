extends Node2D
## Level_01_Tutorial
## チュートリアル整備室。起動時にコードでタイルを配置する
## （TileMapLayerのtile_dataは内部ビット形式に依存するため、
## 手書きではなくset_cell()で組み立てる）。
##
## 物理値からの目安（jump_velocity=-770, gravity=980）：
##   最大到達高さ ≒ 302px（2タイル強）→ 足場は床から最大2タイル上まで
##   1ジャンプの水平到達距離 ≒ 345px（約2.7タイル）→ 隙間は最大2タイルに抑える
##
## 区画構成（列0始まり、1列=128px）：
##   ①導入区画       x=0〜4   平坦な床のみ（移動に慣れる）
##   ②障害物区画     x=5〜9   床は連続、ロッカー（LockerObstacle）を飛び越える
##   ③縦移動区画     x=10〜15 ロッカー3段重ね（高さ450px）をはしごで登り、
##                             反対側へ降りる（Ladderギミックの練習）
##   ④連続ジャンプ   x=16〜21 1タイルの隙間を2箇所連続（リズムよく跳ぶ練習）
##   ⑤仕上げ区画     x=22〜27 床は連続、ロッカーを飛び越えて出口へ
##   ⑥最終複合区画   x=28〜35 隙間→ロッカー→はしご、を組み合わせた総仕上げ。
##                             はしごを登った先の高台（y=384）に出口がある。
##
## ※以前は②⑤に「隙間の上に浮かぶ足場」を、③に階段状の浮遊足場3枚を
## 置いていたが、床が無い空間に板だけが浮いて見え違和感があったため、
## 床を連続させた上でロッカー（床に立つ障害物）を飛び越える／はしごで
## 登る方式に変更した。

const SOURCE_STAGE0 := 0

@onready var _ground: TileMapLayer = $Ground
@onready var _platforms: TileMapLayer = $Platforms

func _ready() -> void:
	MusicManager.play_track("tutorial")
	_build_ground()
	_build_platforms()

func _build_ground() -> void:
	# 床は5行目（y=640〜768）。GAP_COLUMNSに含まれる列だけ空けて敷き詰める。
	# 隙間は④連続ジャンプ区画と⑥最終複合区画の入口。
	var gap_columns := [17, 19, 29, 40, 42]
	for x in range(48):
		if x in gap_columns:
			continue
		_ground.set_cell(Vector2i(x, 5), SOURCE_STAGE0, Vector2i(0, 0))
	# ⑥最終複合区画の出口：はしごを登った先の高台（x=34〜35、y=3行目 → y=384〜512）。
	for x in range(44, 48):
		_ground.set_cell(Vector2i(x, 3), SOURCE_STAGE0, Vector2i(0, 0))

func _build_platforms() -> void:
	# ③縦移動区画：足場タイルは使わない（ロッカー3段重ね＋はしごを.tscn側に配置）。
	pass

	# ④連続ジャンプ区画：足場なし。列17・19の隙間を続けて跳ぶ純粋なリズム練習。

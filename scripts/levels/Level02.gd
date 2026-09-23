extends Node2D
## Level_02_FlipLab
## 重力反転ギミックのステージ。床と天井の両方にタイルを敷き、
## GravityFlipPadで重力を反転させて天井を歩けるようにする。
##
## プレイヤーは最初から重力反転した状態（天井に立っている状態）で始まる。
## 中盤に床の隙間が2箇所連続し（列17〜18、列21〜22）、天井を渡って戻る、
## を連続で行う必要がある。
## 終盤（列26以降）は壁の無い開放的な縦のパズル空間になっており、
## 空中に浮かぶ足場に乗ったフリップパッドを何度も踏んで反転を繰り返しながら
## ジグザグに上（時には下）へ進み、最終的に出口へたどり着く。

const SOURCE_FLIPLAB := 1

@onready var _ground: TileMapLayer = $Ground
@onready var _ceiling: TileMapLayer = $Ceiling
@onready var _player: CharacterBody2D = $Player

func _ready() -> void:
	MusicManager.play_track("flip_lab")
	_build_ground()
	_build_ceiling()
	_start_flipped()

func _build_ground() -> void:
	# 画面下部（y=5行目 → ピクセルy=640〜768）。
	# 列17〜18、列21〜22の2箇所を隙間にして、天井への反転迂回を連続で
	# 求める構成にしている。列26以降（終盤の反転パズル空間）は通常の床が続く。
	var gap_columns := [17, 18, 21, 22]
	for x in range(36):
		if x in gap_columns:
			continue
		_ground.set_cell(Vector2i(x, 5), SOURCE_FLIPLAB, Vector2i(0, 0))

func _build_ceiling() -> void:
	# 画面上部（y=1行目 → ピクセルy=128〜256）。反転後はここが「床」になる。
	# 列26以降（終盤の反転パズル空間）は壁も天井も無い開放空間にするため
	# 通常の天井を敷かない。
	for x in range(26):
		_ceiling.set_cell(Vector2i(x, 1), SOURCE_FLIPLAB, Vector2i(0, 0))

func _start_flipped() -> void:
	## プレイヤーは最初から重力反転した状態（天井に張り付いた状態）で開始する。
	## toggle_gravity()と同じ効果を、開始時の状態として直接設定している。
	_player.gravity_dir = -1
	_player.up_direction = Vector2(0, 1)

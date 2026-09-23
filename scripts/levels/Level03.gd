extends Node2D
## Level_03_WireBay
## ワイヤー引っ張りギミックのステージ。床の途中に広い隙間があり、
## WireHookでWirePlatformを隙間の真ん中付近まで引き寄せ、
## 床→足場→対岸、の2段階ジャンプで渡る（足場は時間が経つと自動で戻る）。
##
## パズル構成：対岸の配線盤面（WiringPanel）をインタラクトすると数秒間「通電中」に
## なる。その間に、はしごを登った先の電力復旧スイッチ（PowerSwitch）をオンに
## できれば出口の施錠が解除される。スイッチとドアの間には距離があるため、
## 通電中に素早く行動する必要がある。
## さらに、スイッチON後もドアに辿り着くまでの制限時間があり（PowerSwitch側で
## カウントダウン表示）、間に合わなければドアが再施錠され、スイッチもOFFに
## 戻る＝配線盤面からやり直しになる。

const SOURCE_WIREBAY := 2

@onready var _ground: TileMapLayer = $Ground
@onready var _power_switch: Area2D = $PowerSwitch
@onready var _exit: Area2D = $LevelExit

func _ready() -> void:
	MusicManager.play_track("wire_bay")
	_build_ground()
	_exit.locked = true
	_power_switch.switched_on.connect(_exit.unlock)
	_power_switch.door_timeout.connect(_on_door_timeout)

func _on_door_timeout() -> void:
	## スイッチON後、ドアに辿り着けなかった場合。再施錠してやり直しにする。
	## （既にドアを通過済みならシーンごと破棄されているため、この処理自体
	## 呼ばれない）
	_exit.locked = true

func _build_ground() -> void:
	# 左側の床（x=0〜5、ピクセルx=0〜768）
	for x in range(0, 6):
		_ground.set_cell(Vector2i(x, 5), SOURCE_WIREBAY, Vector2i(0, 0))
	# 対岸〜終端の床（x=12〜29、ピクセルx=1536〜3840）。間（x=6〜11）が広い隙間。
	for x in range(12, 30):
		_ground.set_cell(Vector2i(x, 5), SOURCE_WIREBAY, Vector2i(0, 0))
	# 上段の小さな足場（x=4〜5、y=1行目 → ピクセルy=128〜256）。
	# 左側の床の奥側。ケーブル足場（縦移動ギミック）で登れる寄り道スペース
	# （パズル本体とは無関係の任意ルート）。フックとは離れた位置にある。
	for x in range(4, 6):
		_ground.set_cell(Vector2i(x, 1), SOURCE_WIREBAY, Vector2i(0, 0))
	# 電力復旧スイッチ用の高台（x=16〜18、y=2行目 → ピクセルy=256〜384）。
	# 新設のはしご（SwitchLadder）で登る。
	for x in range(16, 19):
		_ground.set_cell(Vector2i(x, 2), SOURCE_WIREBAY, Vector2i(0, 0))

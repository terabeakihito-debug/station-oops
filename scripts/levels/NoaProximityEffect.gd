extends Node
## NOA近接距離による画面色変化（彩度を落として不穏な雰囲気にする）
##
## 使い方:
## 1. このスクリプトを NOA関連シーン内の適当なNode（例: NOA自身、または
##    ステージ管理用のNode）にアタッチする
## 2. インスペクタで canvas_modulate_path を、シーン内の CanvasModulate ノードへの
##    パスに設定する（CanvasModulateがまだ無ければ追加してください。
##    画面全体の色を一括で変える専用ノードです）
## 3. noa_path を空のままにすると「このスクリプトがアタッチされているノード」を
##    NOAとして扱います。別ノードにアタッチする場合はNOAへのパスを設定してください
## 4. プレイヤーは "player" グループに所属している前提です
##    （未所属の場合は _ready() で警告が出ます。グループ名が違う場合は
##    player_group の値を変更してください）

@export var canvas_modulate_path: NodePath
@export var noa_path: NodePath  # 空ならこのスクリプトのオーナー(get_parent())を使う
@export var player_group: String = "player"

## 距離のしきい値（メモの指定値）
@export var near_distance: float = 200.0  # これ以下で最大変化
@export var far_distance: float = 400.0   # これ以上で変化なし

## 色の設定
@export var normal_color: Color = Color(1, 1, 1, 1)
@export var near_color: Color = Color(0.55, 0.55, 0.55, 1)  # 彩度を落とした色

var _canvas_modulate: CanvasModulate
var _noa: Node2D
var _player: Node2D


func _ready() -> void:
	_canvas_modulate = get_node_or_null(canvas_modulate_path) as CanvasModulate
	if _canvas_modulate == null:
		push_warning("NoaProximityEffect: CanvasModulateが見つかりません。canvas_modulate_pathを設定してください。")

	if noa_path.is_empty():
		_noa = get_parent() as Node2D
	else:
		_noa = get_node_or_null(noa_path) as Node2D
	if _noa == null:
		push_warning("NoaProximityEffect: NOAノードが見つかりません。noa_pathを設定してください。")

	_player = get_tree().get_first_node_in_group(player_group) as Node2D
	if _player == null:
		push_warning("NoaProximityEffect: '%s'グループにプレイヤーが見つかりません。" % player_group)


func _process(_delta: float) -> void:
	if _canvas_modulate == null or _noa == null or _player == null:
		return

	var distance := _noa.global_position.distance_to(_player.global_position)

	# far_distance以上 -> t=0（通常）, near_distance以下 -> t=1（最大変化）
	var t: float = clamp(inverse_lerp(far_distance, near_distance, distance), 0.0, 1.0)

	_canvas_modulate.color = normal_color.lerp(near_color, t)

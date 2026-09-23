extends CharacterBody2D
## NOA
## 最終ボス（OOPS core）。ダメージ概念のない3フェーズのパズル/クイズ形式。
## フェーズ1中にNOAへインタラクトすると対決開始（フェーズ2へ）。
## HintObjectの収集は任意のおまけで、対決開始の条件ではない。
## フェーズ2=クイズ、フェーズ3=クロスワード。各フェーズの完了は外部
## （レベル側）からenter_phase_2() / enter_phase_3() / defeat() を呼んで進行させる。

enum Phase { PHASE_1, PHASE_2, PHASE_3, DEFEATED }

@export var noa_seed: int = 907275835 ## GameManager.NOA_SEEDと同値。ビジュアル生成の参照用。
@export var calm_color: Color = Color(0.1, 1.1, 0.5) ## 遠距離時の色（鮮やかな緑）
@export var alert_color: Color = Color(1.4, 0.1, 0.35) ## 近距離時の色（鮮やかな赤/ピンク、やや過発光気味）
@export var far_distance: float = 400.0 ## この距離以上離れていればcalm_color
@export var near_distance: float = 100.0 ## この距離以下まで近づくとalert_color
@export var glow_max_energy: float = 1.6 ## 最接近時のグロー強度

signal confrontation_requested

var current_phase: Phase = Phase.PHASE_1
var scanned_by_echo: bool = false
var _player: Node2D = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _glow: PointLight2D = $Glow
@onready var _prompt_label: Label = $PromptLabel

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_prompt_label.visible = false

func _process(_delta: float) -> void:
	## プレイヤーとの距離に応じて色を補間する（遠距離=calm_color→近距離=alert_color）。
	## 色の変化だけでは気づきにくかったため、グロー（PointLight2D）の強さも
	## 同じ補間値で連動させ、近づくほど発光が強くなるようにしている。
	## 撃破後は演出を止め、defeatアニメーションの見た目をそのまま保つ。
	if current_phase == Phase.DEFEATED:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	var dist := global_position.distance_to(_player.global_position)
	var t := clampf((far_distance - dist) / (far_distance - near_distance), 0.0, 1.0)
	_sprite.modulate = calm_color.lerp(alert_color, t)
	_glow.color = calm_color.lerp(alert_color, t)
	_glow.energy = lerpf(0.15, glow_max_energy, t)

func on_scanned() -> void:
	## ECHOのスキャンコマンドで検知された際に呼ばれる（Echo.gd _do_scan 参照）。
	## 初回スキャンでHUDにフェーズ進行パネルを開示する。
	if scanned_by_echo:
		return
	scanned_by_echo = true
	EventBus.boss_phase_changed.emit(current_phase)

func show_prompt() -> void:
	if current_phase == Phase.PHASE_1:
		_prompt_label.visible = true

func hide_prompt() -> void:
	_prompt_label.visible = false

func on_interact() -> void:
	## ヒント（HintObject）の収集はあくまで任意のおまけ。対決自体は
	## プレイヤーがここでインタラクトした時点で始まる（収集状況に関係ない）。
	if current_phase != Phase.PHASE_1:
		return
	_prompt_label.visible = false
	confrontation_requested.emit()

func play_quiz_reaction(is_correct: bool) -> void:
	## フェーズ2のクイズ演出用。正解/不正解のリアクションを再生する。
	_sprite.play("correct" if is_correct else "incorrect")

func enter_phase_2() -> void:
	## プレイヤーがNOAにインタラクトした時点（対決開始）で、レベル側から呼ばれる。
	if current_phase != Phase.PHASE_1:
		return
	current_phase = Phase.PHASE_2
	EventBus.boss_phase_changed.emit(Phase.PHASE_2)

func enter_phase_3() -> void:
	## フェーズ2（クイズ3問正解）完了時に、レベル側から呼ばれる。
	if current_phase != Phase.PHASE_2:
		return
	current_phase = Phase.PHASE_3
	EventBus.boss_phase_changed.emit(Phase.PHASE_3)

func defeat() -> void:
	## フェーズ3（クロスワード完成）達成時に、レベル側から呼ばれる。
	if current_phase == Phase.DEFEATED:
		return
	current_phase = Phase.DEFEATED
	_sprite.play("defeat")
	EventBus.boss_defeated.emit()

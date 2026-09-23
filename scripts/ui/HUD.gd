extends CanvasLayer
## HUD
## プレイヤーの体力バー、NOAのフェーズ進行表示、ECHOスキャン結果の
## 一時表示を担当する。EventBus経由で各所からのシグナルを受けて更新する。

const PHASE_NAMES := {
	0: "フェーズ1：ヒント収集",
	1: "フェーズ2：クイズ",
	2: "フェーズ3：クロスワード",
	3: "撃破",
}

@onready var _player_bar: ProgressBar = $PlayerHealthPanel/PlayerHealthBar
@onready var _boss_panel: Control = $BossPhasePanel
@onready var _phase_label: Label = $BossPhasePanel/PhaseLabel
@onready var _hint_progress_label: Label = $BossPhasePanel/HintProgressLabel
@onready var _scan_label: Label = $ScanResultLabel

var _scan_label_tween: Tween

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.boss_phase_changed.connect(_on_boss_phase_changed)
	EventBus.hint_collected.connect(_on_hint_collected)
	EventBus.echo_scan_completed.connect(_on_scan_completed)
	EventBus.boss_defeated.connect(_on_boss_defeated)

func _on_player_health_changed(current: int, max_value: int) -> void:
	_player_bar.max_value = max_value
	_player_bar.value = current

func _on_boss_phase_changed(phase: int) -> void:
	_boss_panel.visible = true
	_phase_label.text = PHASE_NAMES.get(phase, "フェーズ%d" % phase)

func _on_hint_collected(_hint_letter: String, collected_count: int, total_count: int) -> void:
	_boss_panel.visible = true
	_hint_progress_label.text = "ヒント %d/%d" % [collected_count, total_count]

func _on_scan_completed(found_count: int) -> void:
	if found_count <= 0:
		_scan_label.text = "スキャン: 反応なし"
	else:
		_scan_label.text = "スキャン: %d件検知" % found_count
	_scan_label.visible = true
	_scan_label.modulate.a = 1.0
	if _scan_label_tween:
		_scan_label_tween.kill()
	_scan_label_tween = create_tween()
	_scan_label_tween.tween_interval(1.5)
	_scan_label_tween.tween_property(_scan_label, "modulate:a", 0.0, 0.6)
	_scan_label_tween.tween_callback(func(): _scan_label.visible = false)

func _on_boss_defeated() -> void:
	_phase_label.text = PHASE_NAMES.get(3, "撃破")

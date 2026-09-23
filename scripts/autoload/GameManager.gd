extends Node
## GameManager
## ゲーム全体の進行状態（章、フラグ、キャラクターシード）を管理するオートロード。
## STATION OPS からの引き継ぎ設定もここで保持する。

# --- キャラクターシード（NovelAI等でのビジュアル一貫性用） ---
const PROTAGONIST_SEED: int = 2400857919
const ECHO_SEED: int = 1066145037
const NOA_SEED: int = 907275835

# --- 進行フラグ ---
var current_chapter: int = 0
var flags: Dictionary = {}

# --- ECHOとの関係値（STATION OPSのECHOコメンタリー演出を踏襲） ---
var echo_trust_level: int = 0

# --- プレイヤー名前（OOPS core フェーズ3のクロスワードで使用） ---
const PLAYER_NAME_MIN_LENGTH: int = 3
const PLAYER_NAME_MAX_LENGTH: int = 8
var player_name_input: String = ""

func set_player_name(name_value: String) -> bool:
	## 3〜8文字の英大文字であることを確認して保存する。
	if name_value.length() < PLAYER_NAME_MIN_LENGTH or name_value.length() > PLAYER_NAME_MAX_LENGTH:
		return false
	player_name_input = name_value
	return true

# --- OOPS core フェーズ1（ヒント収集） ---
const TOTAL_HINT_COUNT: int = 4
var collected_hints: Array[String] = []

func collect_hint(hint_letter: String) -> void:
	if collected_hints.size() >= TOTAL_HINT_COUNT:
		return
	collected_hints.append(hint_letter)
	EventBus.hint_collected.emit(hint_letter, collected_hints.size(), TOTAL_HINT_COUNT)
	if collected_hints.size() >= TOTAL_HINT_COUNT:
		EventBus.all_hints_collected.emit()

func reset_hints() -> void:
	collected_hints.clear()

func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	EventBus.flag_changed.emit(flag_name, value)

func has_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func reset_game() -> void:
	current_chapter = 0
	flags.clear()
	echo_trust_level = 0
	player_name_input = ""
	reset_hints()

extends Node
## EventBus
## シーン間を跨ぐシグナルを中継するオートロード。
## 「Godot開発」記事シリーズでSignalの解説に使う想定のため、
## 用途ごとにシグナルを分けてコメントを残している。

# ゲーム進行系
signal flag_changed(flag_name: String, value: bool)
signal chapter_changed(chapter: int)
signal player_name_confirmed(name_value: String)

# プレイヤー系
signal player_health_changed(current: int, max: int)
signal player_died

# ECHO（ドローン相棒）系
signal echo_command_issued(command_name: String)
signal echo_trust_changed(new_value: int)
signal echo_scan_completed(found_count: int)

# ボス（NOA）系
signal boss_phase_changed(phase: int)
signal boss_defeated

# OOPS core フェーズ1（ヒント収集）系
signal hint_collected(hint_letter: String, collected_count: int, total_count: int)
signal all_hints_collected

# 各種ギミックの制限時間系（画面固定のタイマーHUD用）
signal puzzle_timer_started(label_text: String, duration: float)
signal puzzle_timer_stopped

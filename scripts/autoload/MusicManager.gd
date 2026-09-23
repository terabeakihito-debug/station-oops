extends Node
## MusicManager
## ステージごとのBGMをクロスフェードで切り替えるオートロード。
## 各シーンの _ready() から play_track("track_key") を呼び出して使う。
## 同じトラックが指定された場合は何もしない（シーン再読み込み等での re-play を防ぐ）。

const BGM_DIR := "res://assets/audio/bgm/"
const CROSSFADE_DURATION: float = 1.0

## track_key -> ファイル名。ファイルは全て BGM_DIR 直下に置く想定。
## title と tutorial は同じ曲（Opening〜チュートリアル通しで1曲）を指す。
const TRACKS: Dictionary = {
	"title": "title.mp3",
	"tutorial": "title.mp3",
	"flip_lab": "flip_lab.mp3",
	"wire_bay": "wire_bay.mp3",
	"size_dock": "size_dock.mp3",
	"oops_core": "oops_core.mp3",
	"ending": "ending.mp3",
}

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _current_track: String = ""
var _tween: Tween


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_b = AudioStreamPlayer.new()
	add_child(_player_a)
	add_child(_player_b)
	_active_player = _player_a


## track_key を指定してBGMを切り替える。既に同じトラックが再生中なら何もしない。
## ファイルが未配置の場合は警告を出して何もしない（無音のまま進行できる）。
func play_track(track_key: String, loop: bool = true) -> void:
	if track_key == _current_track:
		return
	if not TRACKS.has(track_key):
		push_warning("MusicManager: 未登録のtrack_key '%s'" % track_key)
		return

	var path: String = BGM_DIR + String(TRACKS[track_key])
	if not ResourceLoader.exists(path):
		push_warning("MusicManager: BGMファイルが見つかりません: %s（配置するまで無音です）" % path)
		_current_track = track_key  # 再度同じキーで無駄に警告を出さないようにする
		return

	var stream: AudioStream = load(path)
	if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
		stream.loop = loop

	var incoming: AudioStreamPlayer = _player_b if _active_player == _player_a else _player_a
	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	if _tween:
		_tween.kill()
	var outgoing := _active_player
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(incoming, "volume_db", 0.0, CROSSFADE_DURATION)
	_tween.tween_property(outgoing, "volume_db", -80.0, CROSSFADE_DURATION)
	_tween.set_parallel(false)
	_tween.tween_callback(outgoing.stop)

	_active_player = incoming
	_current_track = track_key


## BGMを止めたい場面（エンディングなど）で使う。
func stop_bgm() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_active_player, "volume_db", -80.0, CROSSFADE_DURATION)
	_tween.tween_callback(_active_player.stop)
	_current_track = ""

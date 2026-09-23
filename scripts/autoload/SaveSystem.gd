extends Node
## SaveSystem
## Resource を介したセーブ/ロード管理。
## STATION OPS の記事シリーズで扱った save/load パターンを流用している。

const SAVE_PATH: String = "user://station_oops_save.tres"

func save_game() -> void:
	var data := SaveData.new()
	data.current_chapter = GameManager.current_chapter
	data.flags = GameManager.flags.duplicate()
	data.echo_trust_level = GameManager.echo_trust_level
	var err := ResourceSaver.save(data, SAVE_PATH)
	if err != OK:
		push_error("SaveSystem: セーブに失敗しました err=%s" % err)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var data: SaveData = ResourceLoader.load(SAVE_PATH)
	if data == null:
		return false
	GameManager.current_chapter = data.current_chapter
	GameManager.flags = data.flags.duplicate()
	GameManager.echo_trust_level = data.echo_trust_level
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

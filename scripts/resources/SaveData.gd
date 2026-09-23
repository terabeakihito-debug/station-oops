extends Resource
class_name SaveData
## セーブデータ本体。Resourceとして .tres 形式で保存される。

@export var current_chapter: int = 0
@export var flags: Dictionary = {}
@export var echo_trust_level: int = 0

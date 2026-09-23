extends CanvasLayer
## CrosswordUI
## OOPS core フェーズ3：クロスワード（という体裁のジョーク）。
## 見た目は複雑なクロスワード（単語バンクからの交差語で埋め尽くされた盤面）
## にして、SF映画のハッカー対決シーンのような緊迫感を演出するが、
## 実際にやることは名前入力画面と同じ「自分の名前を打ち込むだけ」。
## オンスクリーンのA〜Zキーボード＋物理キーボード入力の両方に対応する。

signal crossword_completed

const KEYBOARD_ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

@onready var _grid: GridContainer = $CenterContainer/VBoxContainer/GridContainer
@onready var _keyboard_container: VBoxContainer = $CenterContainer/VBoxContainer/KeyboardContainer
@onready var _message_label: Label = $CenterContainer/VBoxContainer/MessageLabel

var _board: Dictionary = {}
var _target_name: String = ""
var _filled: String = ""
var _spine_labels: Array = []
var _completed: bool = false

const CELL_SIZE := Vector2(38, 42)

func _ready() -> void:
	_target_name = GameManager.player_name_input
	if _target_name.length() == 0:
		_target_name = "NOA" # 名前未設定時の保険（本来は名前入力画面で必ず設定される）
	_board = CrosswordGenerator.generate(_target_name)
	_build_grid()
	_build_keyboard()
	_message_label.text = "不正アクセスを検知　認証コードを再入力せよ"

func _input(event: InputEvent) -> void:
	## 名前入力画面と同じく、物理キーボードのA〜Zでも直接入力できる。
	if _completed:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	if key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		if get_viewport():
			get_viewport().set_input_as_handled()
		_on_letter_pressed(char(key_event.keycode))

func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_spine_labels.clear()
	_grid.columns = _board["width"]
	var cells: Dictionary = _board["cells"]
	var spine_col: int = _board["spine_col"]
	for row in _board["height"]:
		for col in _board["width"]:
			var pos := Vector2i(col, row)
			if cells.has(pos):
				var lbl := Label.new()
				lbl.custom_minimum_size = CELL_SIZE
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				if col == spine_col:
					# プレイヤー名の縦列：最初は空欄で、正解を選ぶたびに埋まっていく。
					lbl.text = "_"
					lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
					_spine_labels.append(lbl)
				else:
					# 単語バンクからの交差語：見た目の複雑さを出すための装飾。
					lbl.text = cells[pos]
					lbl.modulate.a = 0.55
				_grid.add_child(lbl)
			else:
				var spacer := Control.new()
				spacer.custom_minimum_size = CELL_SIZE
				_grid.add_child(spacer)

func _build_keyboard() -> void:
	for row_letters in KEYBOARD_ROWS:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		for i in row_letters.length():
			var letter: String = row_letters[i]
			var btn := Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(44, 44)
			btn.pressed.connect(_on_letter_pressed.bind(letter))
			row.add_child(btn)
		_keyboard_container.add_child(row)

func _on_letter_pressed(letter: String) -> void:
	if _completed or _filled.length() >= _target_name.length():
		return
	var expected: String = _target_name[_filled.length()]
	if letter == expected:
		_filled += letter
		_spine_labels[_filled.length() - 1].text = letter
		_message_label.text = ""
		if _filled.length() == _target_name.length():
			_completed = true
			_message_label.text = "認証完了"
			await get_tree().create_timer(1.0).timeout
			crossword_completed.emit()
			queue_free()
	else:
		_message_label.text = "エラー：認証コード不一致　もう一度"

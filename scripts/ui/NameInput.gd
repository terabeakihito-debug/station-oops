extends Control
## NameInput
## ゲーム開始直後に表示する名前入力画面。
## 画面上のオンスクリーンキーボード（A-Zボタン）で3〜8文字の英大文字を入力させ、
## GameManager.player_name_input に保存する（OOPS core フェーズ3のクロスワードで使用）。

const KEYBOARD_ROWS := ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

@onready var _name_label: Label = $CenterContainer/VBoxContainer/NameLabel
@onready var _keyboard_container: VBoxContainer = $CenterContainer/VBoxContainer/KeyboardContainer
@onready var _backspace_button: Button = $CenterContainer/VBoxContainer/ButtonRow/BackspaceButton
@onready var _confirm_button: Button = $CenterContainer/VBoxContainer/ButtonRow/ConfirmButton

var _current_name: String = ""

func _ready() -> void:
	_build_keyboard()
	_backspace_button.pressed.connect(_on_backspace_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_update_display()

func _input(event: InputEvent) -> void:
	## オンスクリーンキーボードのボタン操作に加え、物理キーボードからの
	## 直接入力にも対応する（A〜Z、Backspace、Enterで確定）。
	## _unhandled_key_inputではなく_inputを使うのは、画面上のボタンが
	## フォーカスを持っている場合にGodotのGUI入力処理へ先に消費されて
	## 届かなくなるのを避けるため。
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	if key_event.keycode == KEY_BACKSPACE:
		if get_viewport():
			get_viewport().set_input_as_handled()
		_on_backspace_pressed()
	elif key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
		if get_viewport():
			get_viewport().set_input_as_handled()
		if not _confirm_button.disabled:
			_on_confirm_pressed()
	elif key_event.keycode >= KEY_A and key_event.keycode <= KEY_Z:
		# Godotの物理キーコードはA〜Zがそのままアルファベットの文字コードと
		# 一致しているため、大文字として直接変換できる。
		if get_viewport():
			get_viewport().set_input_as_handled()
		_on_letter_pressed(char(key_event.keycode))

func _build_keyboard() -> void:
	for row_letters in KEYBOARD_ROWS:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		for i in row_letters.length():
			var letter: String = row_letters[i]
			var btn := Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(52, 52)
			btn.pressed.connect(_on_letter_pressed.bind(letter))
			row.add_child(btn)
		_keyboard_container.add_child(row)

func _on_letter_pressed(letter: String) -> void:
	if _current_name.length() < GameManager.PLAYER_NAME_MAX_LENGTH:
		_current_name += letter
		_update_display()

func _on_backspace_pressed() -> void:
	if _current_name.length() > 0:
		_current_name = _current_name.substr(0, _current_name.length() - 1)
		_update_display()

func _on_confirm_pressed() -> void:
	if GameManager.set_player_name(_current_name):
		EventBus.player_name_confirmed.emit(_current_name)
		if OS.has_feature("debug"):
			# デバッグ実行時はオープニングムービーを飛ばしてステージ選択画面へ。
			# リリースエクスポートではhas_feature("debug")がfalseになるため、
			# この分岐自体が通らない。
			get_tree().change_scene_to_file("res://scenes/ui/DebugStageSelect.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/ui/OpeningMovie.tscn")

func _update_display() -> void:
	_name_label.text = _current_name if _current_name.length() > 0 else "___"
	_confirm_button.disabled = _current_name.length() < GameManager.PLAYER_NAME_MIN_LENGTH
	_backspace_button.disabled = _current_name.length() == 0

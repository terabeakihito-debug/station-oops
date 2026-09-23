class_name CrosswordGenerator
extends RefCounted

# CrosswordGenerator
# OOPS core フェーズ3用のクロスワード盤面自動生成。
# プレイヤー名（3〜8文字）を縦列に固定し、各文字について単語バンクから
# その文字を含む単語を検索して交差させる。同じ単語は重複して使わない。
# 盤面サイズ（幅）は、交差させた単語のうち縦列より左に何文字はみ出すか
# （＝各単語内でのプレイヤー名文字の位置）の最大値から逆算する。

# 宇宙・科学系の単語バンク。13語でA〜Z全26文字をカバーしている。
const WORD_BANK = [
	"GALAXY", "NEBULA", "COMET", "ORBIT", "PLANET", "QUASAR",
	"VORTEX", "ZENITH", "JUPITER", "KRYPTON", "WORMHOLE", "FUSION", "DENSITY"
]

# player_nameからクロスワード盤面を生成する。
# 戻り値のDictionary：
#   "width": int          盤面の横幅（マス数）
#   "height": int         盤面の縦幅（＝プレイヤー名の文字数）
#   "spine_col": int      縦列（プレイヤー名）が通る列番号
#   "player_name": String 大文字化したプレイヤー名
#   "cells": Dictionary   Vector2i(col, row) -> 文字（1文字のString）
#   "crossings": Array    [{"row": int, "word": String, "pos": int, "col_start": int}, ...]
static func generate(input_name):
	var upper_name = input_name.to_upper()
	var bank = WORD_BANK.duplicate()
	bank.shuffle()

	var used_words = []
	var crossings = []

	var i = 0
	while i < upper_name.length():
		var letter = upper_name.substr(i, 1)
		var candidates = []
		for word in bank:
			if used_words.has(word):
				continue
			var pos = word.find(letter)
			if pos != -1:
				candidates.append({"word": word, "pos": pos})
		if candidates.size() > 0:
			candidates.shuffle()
			var chosen = candidates[0]
			used_words.append(chosen["word"])
			crossings.append({"row": i, "word": chosen["word"], "pos": chosen["pos"]})
		i += 1

	# 縦列の位置：各交差単語で「プレイヤー名の文字より左に何文字あるか」の最大値。
	var spine_col = 0
	for c in crossings:
		if c["pos"] > spine_col:
			spine_col = c["pos"]

	# 盤面の幅：縦列より右に一番長く伸びる単語に合わせる。
	var width = spine_col + 1
	for c in crossings:
		var col_start = spine_col - c["pos"]
		c["col_start"] = col_start
		var word_string = c["word"]
		var right_edge = col_start + word_string.length()
		if right_edge > width:
			width = right_edge

	var height = upper_name.length()
	var cells = {}

	# 縦列（プレイヤー名）を配置
	i = 0
	while i < upper_name.length():
		cells[Vector2i(spine_col, i)] = upper_name.substr(i, 1)
		i += 1

	# 交差単語を配置
	for c in crossings:
		var row = c["row"]
		var word = c["word"]
		var col_start = c["col_start"]
		var k = 0
		while k < word.length():
			cells[Vector2i(col_start + k, row)] = word.substr(k, 1)
			k += 1

	var result = {}
	result["width"] = width
	result["height"] = height
	result["spine_col"] = spine_col
	result["player_name"] = upper_name
	result["cells"] = cells
	result["crossings"] = crossings
	return result

extends Node

const SAVE_PATH = "user://high_score.save"

var dungeon_level: int = 1
var score: int = 0
var high_score: int = 0

signal level_changed(new_level: int)
signal score_changed(new_score: int)
signal high_score_changed(new_high_score: int)

func _ready() -> void:
	load_high_score()

func reset_level() -> void:
	dungeon_level = 1
	score = 0
	level_changed.emit(dungeon_level)
	score_changed.emit(score)

func increment_level() -> void:
	dungeon_level += 1
	level_changed.emit(dungeon_level)

func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)
	if score > high_score:
		high_score = score
		save_high_score()
		high_score_changed.emit(high_score)

func is_new_high_score() -> bool:
	return score == high_score and score > 0

func save_high_score() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.close()

func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()
			file.close()
			high_score_changed.emit(high_score)

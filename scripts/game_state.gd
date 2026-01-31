extends Node

var dungeon_level: int = 1
var score: int = 0
var high_score: int = 0

signal level_changed(new_level: int)
signal score_changed(new_score: int)

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

func is_new_high_score() -> bool:
	return score == high_score and score > 0

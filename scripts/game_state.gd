extends Node

var dungeon_level: int = 1

signal level_changed(new_level: int)

func reset_level() -> void:
	dungeon_level = 1
	level_changed.emit(dungeon_level)

func increment_level() -> void:
	dungeon_level += 1
	level_changed.emit(dungeon_level)

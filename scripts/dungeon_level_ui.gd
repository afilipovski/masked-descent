extends Label

func _ready() -> void:
	update_level_display(GameState.dungeon_level)
	GameState.level_changed.connect(_on_level_changed)

func _on_level_changed(new_level: int) -> void:
	update_level_display(new_level)

func update_level_display(level: int) -> void:
	text = "Level %d" % level

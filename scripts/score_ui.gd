extends Label

func _ready() -> void:
	update_score_display(GameState.score)
	GameState.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
	update_score_display(new_score)

func update_score_display(score_value: int) -> void:
	text = "Score: %d" % score_value

extends Control

@onready var play_button = $CenterContainer/VBoxContainer/PlayButton
@onready var exit_button = $CenterContainer/VBoxContainer/ExitButton
@onready var high_score_label = $CenterContainer/VBoxContainer/HighScoreLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	update_high_score_display()
	GameState.high_score_changed.connect(_on_high_score_changed)
	play_button.grab_focus()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func update_high_score_display() -> void:
	high_score_label.text = "High Score: %d" % GameState.high_score

func _on_high_score_changed(_new_high_score: int) -> void:
	update_high_score_display()

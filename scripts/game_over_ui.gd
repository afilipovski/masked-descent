extends Control

@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton
@onready var score_label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var high_score_message = $CenterContainer/VBoxContainer/HighScoreMessage

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS # Allow UI to work when paused
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_restart_pressed()

func show_game_over() -> void:
	show()
	score_label.text = "Score: %d" % GameState.score
	
	if GameState.is_new_high_score():
		high_score_message.text = "NEW HIGH SCORE!"
		high_score_message.show()
	else:
		high_score_message.text = "High Score: %d" % GameState.high_score
		high_score_message.show()
	
	restart_button.grab_focus()

func _on_restart_pressed() -> void:
	hide()
	GameState.reset_level()
	
	# Regenerate dungeon (which will clear enemies internally)
	var tilemap = get_tree().get_first_node_in_group(Groups.TILEMAP)
	if tilemap and tilemap.has_method("regenerate"):
		tilemap.regenerate()
	
	# Reset player (which will unpause the game)
	get_tree().call_group(Groups.PLAYER, "reset_position")

func _on_main_menu_pressed() -> void:
	get_tree().paused = false # Unpause before changing scenes
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

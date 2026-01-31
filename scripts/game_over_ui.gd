extends Control

@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton

func _ready() -> void:
	hide()
	restart_button.pressed.connect(_on_restart_pressed)

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_accept"):
		_on_restart_pressed()

func show_game_over() -> void:
	show()
	restart_button.grab_focus()

func _on_restart_pressed() -> void:
	hide()
	GameState.reset_level()
	get_tree().call_group(Groups.PLAYER, "reset_position")
	var tilemap = get_tree().get_first_node_in_group(Groups.TILEMAP)
	if tilemap and tilemap.has_method("regenerate"):
		tilemap.regenerate()

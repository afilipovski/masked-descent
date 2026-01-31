extends Control
class_name GemSelectionUI

signal gem_selected(gem: GemData)
signal selection_cancelled

@export var gem_button_scene: PackedScene

var available_gems: Array[GemData] = []
var panel: Panel
var button_container: HBoxContainer
var cancel_button: Button

func show_gem_selection(gems: Array[GemData]):
	available_gems = gems
	_create_gem_buttons()

	# Lock player movement when UI is shown
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].lock_movement()

	show()

func _create_gem_buttons():
	# Clear existing buttons
	for child in button_container.get_children():
		child.queue_free()

	# Create button for each gem
	for gem in available_gems:
		var button = Button.new()
		button.text = gem.gem_name + "\n" + gem.description
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(430, 275)  # 330 * 1.3, 210 * 1.3

		# Color button based on rarity
		var style = StyleBoxFlat.new()
		match gem.rarity:
			1: style.bg_color = Color.GRAY
			2: style.bg_color = Color.GREEN
			3: style.bg_color = Color.BLUE
			4: style.bg_color = Color.PURPLE
			5: style.bg_color = Color.GOLD
		button.add_theme_stylebox_override("normal", style)

		button.add_theme_font_size_override("font_size", 31)  # 24 * 1.3
		button.pressed.connect(_on_gem_button_pressed.bind(gem))

		button_container.add_child(button)

func _on_gem_button_pressed(gem: GemData):
	gem_selected.emit(gem)
	_unlock_player_movement()
	hide()

func _on_cancel_button_pressed():
	selection_cancelled.emit()
	_unlock_player_movement()
	hide()

func _ready():
	_create_ui_elements()

func _unlock_player_movement():
	# Unlock player movement when UI is hidden
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].unlock_movement()

func _create_ui_elements():
	# Set up the main control to fill the screen
	anchors_preset = Control.PRESET_FULL_RECT

	# Get viewport size to center properly
	var viewport_size = get_viewport().get_visible_rect().size

	# Create main panel - even bigger
	panel = Panel.new()
	panel.size = Vector2(1750, 975)  # 1350 * 1.3, 750 * 1.3
	panel.position = Vector2((viewport_size.x - 1750) / 2, (viewport_size.y - 975) / 2)
	add_child(panel)

	# Create VBoxContainer with scaled margins
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(60, 60)  # 45 * 1.3
	vbox.size = Vector2(1630, 855)  # Panel size minus margins (1750-120, 975-120)
	vbox.add_theme_constant_override("separation", 40)  # 30 * 1.3
	panel.add_child(vbox)

	# Create title label
	var title_label = Label.new()
	title_label.text = "Choose a Gem"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 62)  # 48 * 1.3
	vbox.add_child(title_label)

	# Create button container
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button_container.add_theme_constant_override("separation", 58)  # 45 * 1.3
	vbox.add_child(button_container)

	# Create cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size = Vector2(293, 98)  # 225 * 1.3, 75 * 1.3
	cancel_button.add_theme_font_size_override("font_size", 35)  # 27 * 1.3
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	vbox.add_child(cancel_button)

	# Initially hide the UI
	hide()
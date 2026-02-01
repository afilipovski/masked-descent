extends Node2D
class_name TreasureChest

signal chest_opened
signal powerup_selected(powerup: PowerupData)

@export var is_opened: bool = false
@export var open_sound: AudioStream

var interaction_area: Area2D
var animated_sprite: AnimatedSprite2D
var chest_ui: Control
var player_nearby: bool = false
var open_sound_player: AudioStreamPlayer2D
var available_powerups: Array[PowerupData] = []

func _ready():
	add_to_group("interactables")
	_setup_chest_nodes()

func _setup_chest_nodes():
	# Create StaticBody2D for chest collision if it doesn't exist
	var static_body = get_node_or_null("StaticBody2D")
	if not static_body:
		static_body = StaticBody2D.new()
		static_body.name = "StaticBody2D"
		add_child(static_body)

		var chest_collision = CollisionShape2D.new()
		var chest_shape = RectangleShape2D.new()
		chest_shape.size = Vector2(32, 32)
		chest_collision.shape = chest_shape
		static_body.add_child(chest_collision)
		print("Created chest collision shape")

	# Create sprite if it doesn't exist
	if not get_node_or_null("AnimatedSprite2D") and not get_node_or_null("Sprite2D"):
		var sprite = Sprite2D.new()
		# You can set a placeholder texture here if needed
		add_child(sprite)
		print("Created chest sprite")

	# Create interaction area if it doesn't exist
	interaction_area = get_node_or_null("InteractionArea")
	if not interaction_area:
		interaction_area = Area2D.new()
		interaction_area.name = "InteractionArea"
		interaction_area.collision_mask = 255  # Detect all layers for testing
		interaction_area.monitoring = true
		add_child(interaction_area)

		# Create interaction collision shape
		var interaction_collision = CollisionShape2D.new()
		var interaction_shape = CircleShape2D.new()
		interaction_shape.radius = 80.0  # Make it bigger for testing
		interaction_collision.shape = interaction_shape
		interaction_area.add_child(interaction_collision)
		print("Created interaction area with collision mask 255 and radius 80")

	# Connect signals
	if interaction_area and not interaction_area.body_entered.is_connected(_on_player_entered):
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)
		print("Connected interaction area signals")

	# Get animated sprite or sprite
	animated_sprite = get_node_or_null("AnimatedSprite2D")
	if animated_sprite:
		if is_opened:
			animated_sprite.play("open")
		else:
			animated_sprite.play("closed")

	# Create or find audio players for open/close SFX
	open_sound_player = get_node_or_null("OpenSound")
	if not open_sound_player:
		open_sound_player = AudioStreamPlayer2D.new()
		open_sound_player.name = "OpenSound"
		# Route to SFX bus if it exists; otherwise default
		open_sound_player.bus = "SFX"
		add_child(open_sound_player)

	# Assign exported streams if set
	if open_sound:
		open_sound_player.stream = open_sound

func _on_player_entered(body: Node2D):
	print("Body entered interaction area: ", body.name, " groups: ", body.get_groups())
	if body.is_in_group("player"):
		player_nearby = true
		if not is_opened:
			# Show interaction prompt
			print("Press E to open chest")
		else:
			print("Chest is already opened")

func _on_player_exited(body: Node2D):
	print("Body exited interaction area: ", body.name)
	if body.is_in_group("player"):
		player_nearby = false
		# Hide interaction prompt
		print("Left chest area")

# Input handling moved to player script

func _is_player_near() -> bool:
	return player_nearby

func open_chest():
	if is_opened:
		return

	is_opened = true

	# Play open sound (positional)
	if open_sound_player:
		open_sound_player.play()

	# Play opening animation
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("opening"):
		animated_sprite.play("opening")
		await animated_sprite.animation_finished
		animated_sprite.play("open")
	elif animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("open"):
		animated_sprite.play("open")

	# Get all powerups to offer
	available_powerups = PowerupData.get_all_powerups()
	
	# Show chest UI with powerups
	_show_chest_ui()

func _show_chest_ui():
	# Create UI if it doesn't exist
	if not chest_ui:
		chest_ui = _create_chest_ui()
		
		# Create a CanvasLayer to ensure UI renders above everything and ignores camera
		var canvas_layer = CanvasLayer.new()
		canvas_layer.name = "ChestUILayer"
		canvas_layer.layer = 100  # High layer to render on top
		get_tree().current_scene.add_child(canvas_layer)
		canvas_layer.add_child(chest_ui)

	# Lock player movement
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].lock_movement()
	
	chest_ui.show()
	chest_opened.emit()

func _create_chest_ui() -> Control:
	var ui = Control.new()
	ui.name = "ChestUI"
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.hide()
	
	# Semi-transparent dark overlay
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(overlay)
	
	# Get viewport size to center panel
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Main panel with dungeon aesthetic - wider for 3 buttons
	var panel = Panel.new()
	panel.size = Vector2(900, 500)
	panel.position = Vector2((viewport_size.x - 900) / 2, (viewport_size.y - 500) / 2)
	
	# Dark stone-like background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.12, 0.1)  # Dark brownish stone
	panel_style.border_color = Color(0.3, 0.25, 0.2)  # Lighter stone border
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	
	ui.add_child(panel)
	
	# Load dungeon font
	var dungeon_font = load("res://assets/DungeonFont.ttf")
	
	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(40, 40)
	vbox.size = Vector2(820, 420)
	vbox.add_theme_constant_override("separation", 30)
	panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Choose a Powerup"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if dungeon_font:
		title.add_theme_font_override("font", dungeon_font)
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))  # Parchment color
	vbox.add_child(title)
	
	# Powerup buttons container
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button_container.add_theme_constant_override("separation", 20)
	vbox.add_child(button_container)
	
	# Create a button for each powerup
	for powerup in available_powerups:
		var button = _create_powerup_button(powerup, dungeon_font)
		button_container.add_child(button)
	
	# Close instruction
	var close_label = Label.new()
	close_label.text = "Press ESC to close"
	close_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if dungeon_font:
		close_label.add_theme_font_override("font", dungeon_font)
	close_label.add_theme_font_size_override("font_size", 24)
	close_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	vbox.add_child(close_label)
	
	return ui

func _create_powerup_button(powerup: PowerupData, font: Font) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(240, 280)
	
	# Dark button style
	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.2, 0.17, 0.15)
	normal_style.border_color = Color(0.4, 0.35, 0.3)
	normal_style.border_width_left = 3
	normal_style.border_width_right = 3
	normal_style.border_width_top = 3
	normal_style.border_width_bottom = 3
	normal_style.corner_radius_top_left = 6
	normal_style.corner_radius_top_right = 6
	normal_style.corner_radius_bottom_left = 6
	normal_style.corner_radius_bottom_right = 6
	
	var hover_style = normal_style.duplicate()
	hover_style.bg_color = Color(0.3, 0.25, 0.2)
	hover_style.border_color = Color(0.6, 0.5, 0.4)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	
	# Create vertical container for icon and text
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(vbox)
	
	# Add icon texture
	if powerup.icon_texture:
		var icon = TextureRect.new()
		icon.texture = powerup.icon_texture
		icon.custom_minimum_size = Vector2(80, 80)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vbox.add_child(icon)
	
	# Add name label
	var name_label = Label.new()
	name_label.text = powerup.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font:
		name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(name_label)
	
	# Add description label
	var desc_label = Label.new()
	desc_label.text = powerup.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(220, 0)
	if font:
		desc_label.add_theme_font_override("font", font)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
	vbox.add_child(desc_label)
	
	# Connect button press
	button.pressed.connect(_on_powerup_selected.bind(powerup))
	
	return button

func _on_powerup_selected(powerup: PowerupData):
	print("Player selected powerup: ", powerup.display_name)
	powerup_selected.emit(powerup)
	_close_chest_ui()

func _input(event):
	# Handle ESC key to close chest UI
	if chest_ui and chest_ui.visible and event.is_action_pressed("ui_cancel"):
		_close_chest_ui()
		get_viewport().set_input_as_handled()

func _close_chest_ui():
	if chest_ui:
		chest_ui.hide()
		
		# Unlock player movement
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			players[0].unlock_movement()

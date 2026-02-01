extends Node2D
class_name TreasureChest

signal chest_opened(gems: Array[GemData])

@export var gem_selection_ui_scene: PackedScene
@export var is_opened: bool = false
@export var gems_to_offer: int = 3
@export var open_sound: AudioStream

var interaction_area: Area2D
var animated_sprite: AnimatedSprite2D
var gem_selection_ui: GemSelectionUI
var player_nearby: bool = false
var open_sound_player: AudioStreamPlayer2D

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

	# Generate random gems
	var available_gems = GemData.get_random_gems(gems_to_offer)

	# Show gem selection UI
	_show_gem_selection(available_gems)

func _show_gem_selection(gems: Array[GemData]):
	# Create UI if it doesn't exist
	if not gem_selection_ui:
		# Create the UI programmatically since we don't have a scene file
		gem_selection_ui = GemSelectionUI.new()

		# Create a CanvasLayer to ensure UI renders above everything and ignores camera
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 100  # High layer to render on top
		get_tree().current_scene.add_child(canvas_layer)
		canvas_layer.add_child(gem_selection_ui)

		gem_selection_ui.gem_selected.connect(_on_gem_selected)
		gem_selection_ui.selection_cancelled.connect(_on_selection_cancelled)

	if gem_selection_ui:
		gem_selection_ui.show_gem_selection(gems)

func _on_gem_selected(gem: GemData):
	print("Player selected: ", gem.gem_name)
	chest_opened.emit([gem])

	# TODO: Add gem to player's mask inventory
	# PlayerInventory.add_gem(gem)

func _on_selection_cancelled():
	print("Player cancelled gem selection")

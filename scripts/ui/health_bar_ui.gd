extends MarginContainer

@onready var health_bar_sprite: TextureRect = $HealthBarSprite
@onready var health_progress: ProgressBar = $HealthBarSprite/HealthProgress

var player: CharacterBody2D = null

var health_bar_textures = [
	preload("res://assets/health_bar/health_bar_full.png"), # 100-80%
	preload("res://assets/health_bar/health_bar_medium.png"), # 79-60%
	preload("res://assets/health_bar/healt_bar_low.png"), # 59-40%
	preload("res://assets/health_bar/health_bar_danger.png"), # 39-20%
	preload("res://assets/health_bar/health_bar_danger.png") # 19-0% (reuse danger)
]

func _ready():
	# Wait for player to be ready
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group(Groups.PLAYER)

	if player:
		player.health_changed.connect(_on_player_health_changed)
		_on_player_health_changed(player.health)

func _on_player_health_changed(current_health: int):
	if not player:
		return

	var max_health = player.max_health
	var health_percent = (float(current_health) / float(max_health)) * 100.0

	# Update progress bar
	health_progress.max_value = max_health
	health_progress.value = current_health

	# Update sprite frame based on health percentage
	var frame_index = _get_frame_for_health_percent(health_percent)
	_set_health_bar_frame(frame_index)

func _get_frame_for_health_percent(percent: float) -> int:
	# Map health percentage to frame (0-4)
	# 100-80% = frame 0 (full)
	# 79-60% = frame 1
	# 59-40% = frame 2
	# 39-20% = frame 3
	# 19-0% = frame 4 (nearly empty)
	if percent > 80:
		return 0
	elif percent > 60:
		return 1
	elif percent > 40:
		return 2
	elif percent > 20:
		return 3
	else:
		return 4

func _set_health_bar_frame(frame_index: int):
	# Switch to the appropriate health bar texture
	if frame_index >= 0 and frame_index < health_bar_textures.size():
		health_bar_sprite.texture = health_bar_textures[frame_index]

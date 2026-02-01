extends Node2D

@export var swoosh_sound: AudioStream

var _swoosh_player: AudioStreamPlayer2D

func _ready():
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("swoosh")
		# Play swoosh SFX (positional)
		_swoosh_player = get_node_or_null("SwooshSound")
		if not _swoosh_player:
			_swoosh_player = AudioStreamPlayer2D.new()
			_swoosh_player.name = "SwooshSound"
			# Only set to SFX bus if it exists (avoid errors if bus not created)
			if AudioServer.get_bus_index("SFX") != -1:
				_swoosh_player.bus = "SFX"
			add_child(_swoosh_player)
		if swoosh_sound:
			_swoosh_player.stream = swoosh_sound
			_swoosh_player.play()
		else:
			print("swoosh_attack: no swoosh_sound assigned on SwooshAttack node")
		animated_sprite.animation_finished.connect(_on_animation_finished)
		print("Animation started, frames: ", animated_sprite.sprite_frames.get_frame_count("swoosh"))

	# Backup timer in case animation signal fails
	var timer = Timer.new()
	timer.wait_time = 1.0  # 1 second backup
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_animation_finished():
	print("Animation finished, destroying swoosh")
	queue_free()

func _on_timer_timeout():
	print("Backup timer triggered, destroying swoosh")
	queue_free()

func set_direction(direction: Vector2):
	rotation = direction.angle()

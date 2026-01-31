extends Node2D

func _ready():
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("swoosh")
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

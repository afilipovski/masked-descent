extends Node2D

func _ready():
	var animated_sprite = $AnimatedSprite2D
	if !animated_sprite:
		return

	var animations = animated_sprite.sprite_frames.get_animation_names()
	if animations.size() > 0:
		var anim_name = animations[0]
		animated_sprite.play(anim_name)
	else:
		print("Death effect: No animations found in sprite frames!")

	animated_sprite.animation_finished.connect(_on_animation_finished)

	var timer = Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	timer.start()

func _on_animation_finished():
	queue_free()

func _on_timer_timeout():
	queue_free()

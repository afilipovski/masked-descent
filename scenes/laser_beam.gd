extends State

var can_transition: bool = false

func enter():
	super.enter()
	await play_animation("laser_cast")
	await play_animation("laser")
	can_transition = true

func play_animation(anim_name):
	animation_player.play(anim_name)
	await animation_player.animation_finished

func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")

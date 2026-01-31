extends State

var can_transition: bool = false
var locked_target: Vector2 = Vector2.ZERO

func enter():
	super.enter()
	lock_target()
	await play_animation("laser_cast")
	await play_animation("laser")
	can_transition = true

func play_animation(anim_name):
	animation_player.play(anim_name)
	await animation_player.animation_finished

func lock_target() -> void:
	if player == null or pivot == null:
		return

	locked_target = player.global_position
	pivot.look_at(locked_target)

func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")

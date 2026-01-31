extends State
 
func enter():
	super.enter()
	animation_player.play("death")
	await animation_player.animation_finished
	if character.has_method("die"):
		character.die()

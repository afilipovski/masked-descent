extends State

func enter():
	super.enter()
	if character:
		character.set_physics_process(true)
	animation_player.play("idle")

func exit():
	super.exit()
	if character:
		character.set_physics_process(false)

func transition():
	if character == null or character.player == null:
		return

	if not character.player_detected:
		get_parent().change_state("Idle")
		return

	var distance = character.direction.length()

	print(distance)
	if distance < 50:
		get_parent().change_state("MeleeAttack")
	elif distance >= 50 and distance <= 130:
		get_parent().change_state("Dash")
	elif distance > 130:
		var chance = randi() % 2
		match chance:
			0:
				get_parent().change_state("HomingMissile")
			1:
				get_parent().change_state("LaserBeam")

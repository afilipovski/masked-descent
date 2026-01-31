extends State

const EXIT_DISTANCE := 50.0
const ENTER_DISTANCE := 30.0

func enter():
	super.enter()
	animation_player.play("melee_attack")

func transition():
	if character == null or character.player == null:
		return

	if not character.player_detected:
		get_parent().change_state("Idle")
	elif character.direction.length() > EXIT_DISTANCE:
		get_parent().change_state("Follow")

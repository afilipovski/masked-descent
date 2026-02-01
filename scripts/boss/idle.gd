extends State

@onready var progress_bar: ProgressBar = owner.find_child("ProgressBar")
var detection_area: Area2D = null

var player_entered: bool = false

func set_player_entered(value: bool) -> void:
	player_entered = value
	if character:
		character.player_detected = value
	if progress_bar:
		progress_bar.set_deferred("visible", value)

func enter():
	super.enter()
	if character and detection_area == null:
		detection_area = character.get_node_or_null("PlayerDetection") as Area2D
	if detection_area and player and detection_area.overlaps_body(player):
		set_player_entered(true)

func transition():
	if character and character.player_detected:
		get_parent().change_state("Follow")

func _on_player_detection_body_entered(body):
	if body.is_in_group("player"):
		# Don't detect stealthed players
		if body.has_node("CombatManager"):
			var cm = body.get_node("CombatManager") as CombatManager
			if cm and cm.is_player_stealthed():
				return

		set_player_entered(true)

func _on_player_detection_body_exited(body):
	if body.is_in_group("player"):
		set_player_entered(false)

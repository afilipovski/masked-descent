extends State
 
@export var bullet_node: PackedScene
var can_transition: bool = false
 
func enter():
	super.enter()
	animation_player.play("ranged_attacks")
	await animation_player.animation_finished
	shoot()
	can_transition = true
 
func shoot():
	if bullet_node == null or character == null:
		return
	var bullet = bullet_node.instantiate()
	bullet.global_position = character.global_position
	get_tree().current_scene.add_child(bullet)
 
func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")

extends "res://scripts/enemies/base_enemy.gd"
class_name RangedEnemy

@export var projectile_scene: PackedScene
@export var attack_cooldown: float = 2.0
var attack_timer: Timer

func _on_ready():
	# Ranged enemy - keeps distance and shoots
	speed = 100.0
	health = 2
	max_health = 2
	damage = 1
	detection_range = 400.0

	# Setup attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	attack_timer.autostart = false
	add_child(attack_timer)

func _update_movement(_delta: float):
	if not player:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= detection_range:
		# Keep distance from player
		var direction = (global_position - player.global_position).normalized()
		if distance_to_player < 150.0:  # Too close, back away
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO  # Stay in place and attack

func _attack_player(player_body: Node2D):
	if attack_timer.time_left > 0:
		return

	# Ranged attack instead of melee
	if projectile_scene and player:
		var projectile = projectile_scene.instantiate()
		get_parent().add_child(projectile)
		projectile.global_position = global_position

		var direction = (player.global_position - global_position).normalized()
		if projectile.has_method("set_direction"):
			projectile.set_direction(direction)

		attack_timer.start()
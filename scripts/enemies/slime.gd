extends "res://scripts/enemies/base.gd"
class_name SlimeEnemy

const PROJECTILE_SCENE = preload("res://scenes/enemy_projectile.tscn")

@export var attack_range: float = 200.0
@export var attack_cooldown: float = 0.8
@export var projectile_speed: float = 200.0
@export var projectile_damage: int = 2

var last_attack_time: float = 0.0
var is_attacking: bool = false

func _on_ready():
	speed = 80.0
	health = 4
	max_health = 4
	damage = 1
	detection_range = 220.0

func _update_movement(_delta: float):
	if not player:
		velocity = Vector2.ZERO
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var optimal_distance = attack_range * 0.8  # Stay at 80% of attack range

	# If player is in attack range, try to attack
	if distance_to_player <= attack_range and can_attack():
		perform_ranged_attack()
		velocity = Vector2.ZERO
		_update_animation()
		return

	# Movement logic with deadzone to prevent jittering
	var deadzone = 20.0  # Don't move if within this range of optimal distance

	if distance_to_player < optimal_distance - deadzone:
		# Too close - back away
		var retreat_direction = (global_position - player.global_position).normalized()
		velocity = retreat_direction * speed * 0.6
	elif distance_to_player > optimal_distance + deadzone:
		# Too far - move closer
		var approach_direction = (player.global_position - global_position).normalized()
		velocity = approach_direction * speed * 0.8
	else:
		# In optimal range - stop moving
		velocity = Vector2.ZERO

	_update_animation()

func _update_animation():
	var animated_sprite = $AnimatedSprite2D
	if not animated_sprite or velocity.length() <= 0:
		return

	if abs(velocity.y) > abs(velocity.x):
		if velocity.y < 0:
			animated_sprite.play("walk_up")
		else:
			animated_sprite.play("walk_down")
	else:
		if velocity.x < 0:
			animated_sprite.play("walk_left")
		else:
			animated_sprite.play("walk_right")

func _physics_process(_delta: float) -> void:
	if not player:
		find_player()
		return

	last_attack_time += _delta
	_update_movement(_delta)
	move_and_slide()

func can_attack() -> bool:
	return last_attack_time >= attack_cooldown and can_detect_player()

func perform_ranged_attack():
	if not can_attack():
		return

	last_attack_time = 0.0
	is_attacking = true

	# Fire projectile toward player
	fire_projectile()

	print("Slime fired projectile at player!")

func fire_projectile():
	if not player:
		return

	var projectile = PROJECTILE_SCENE.instantiate()
	get_parent().add_child(projectile)

	# Position projectile slightly in front of slime to avoid self-collision
	var direction = (player.global_position - global_position).normalized()
	projectile.global_position = global_position + direction * 16

	# Set projectile properties
	projectile.set_direction(direction)
	projectile.set_damage(projectile_damage)
	projectile.set_speed(projectile_speed)

	print("Slime fired projectile with ", projectile_damage, " damage at speed ", projectile_speed)

# Override the base attack behavior - slimes don't do melee damage
func deal_damage_to_player(_player_body: Node2D):
	# Slimes only attack at range, no melee damage
	pass

# Make slimes less aggressive in melee range
func _attack_player(player_body: Node2D):
	# Don't attack in melee range, slimes prefer ranged combat
	pass
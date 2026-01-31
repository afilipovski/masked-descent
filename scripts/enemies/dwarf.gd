extends "res://scripts/enemies/base.gd"
class_name DwarfEnemy

@export var knockback_force: float = 300.0
@export var attack_recoil_time: float = 0.3
@export var attack_effect_scene: PackedScene

var attack_recoil_timer: float = 0.0

func _on_ready():
	speed = 130.0
	health = 10
	max_health = 10
	damage = 3
	detection_range = 130.0

func _update_movement(_delta: float):
	if _handle_attack_recoil(_delta):
		return
	_update_animation()

	chase_player()

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

func _handle_attack_recoil(_delta: float):
	## Handle attack recoil - dwarf stops and steps back slightly, returns true if ocurred
	if attack_recoil_timer <= 0:
		return false

	attack_recoil_timer -= _delta
	if player:
		var retreat_direction = (global_position - player.global_position).normalized()
		velocity = retreat_direction * speed * 0.3
		return true

	velocity = Vector2.ZERO
	return false

func _physics_process(_delta: float) -> void:
	if not player:
		find_player()
		return

	_update_movement(_delta)
	move_and_slide()

func deal_damage_to_player(player_body: Node2D):
	_play_attack_effect(player_body)
	if !player_body.has_method("take_damage"):
		return
	player_body.take_damage(damage)

	if !player_body.has_method("apply_knockback"):
		return
	var knockback_direction = (player_body.global_position - global_position).normalized()
	player_body.apply_knockback(knockback_direction * knockback_force)

	attack_recoil_timer = attack_recoil_time

func _play_attack_effect(player_body: Node2D):
	if !attack_effect_scene:
		return

	var effect = attack_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position
	var attack_direction = (player_body.global_position - global_position).normalized()
	effect.set_direction(attack_direction)

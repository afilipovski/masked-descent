extends "res://scripts/enemies/base_enemy.gd"
class_name TankEnemy

func _on_ready():
	# Tank enemy - slow but tough
	speed = 80.0
	health = 8
	max_health = 8
	damage = 2
	detection_range = 150.0

func _on_damage_taken(amount: int):
	# Tank takes reduced damage
	print("Tank enemy takes reduced damage!")
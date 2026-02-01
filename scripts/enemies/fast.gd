extends "res://scripts/enemies/base.gd"
class_name FastEnemy

func _on_ready():
	# Fast enemy - high speed, low health
	speed = 250.0
	health = 1
	max_health = 1
	damage = 1
	detection_range = 300.0
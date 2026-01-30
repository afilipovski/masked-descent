extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed = 2000


func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	# Rotate sprite to face the direction
	rotation = direction.angle()


func _physics_process(_delta: float) -> void:
	velocity = direction * speed
	move_and_slide()

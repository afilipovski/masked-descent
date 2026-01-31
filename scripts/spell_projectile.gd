extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed = 220.0
var lifetime = 1.2
var max_distance = 500.0
var traveled_distance = 0.0
var damage = 10

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		_despawn()
		return

	var collision = move_and_collide(direction * speed * delta)

	if collision:
		_on_collision(collision)

	var movement = direction * speed * delta
	traveled_distance += movement.length()
	if traveled_distance >= max_distance:
		_despawn()


func _on_collision(collision: KinematicCollision2D) -> void:
	var collider = collision.get_collider()

	if collider.is_in_group(Groups.PLAYER):
		return
	if collider.is_in_group(Groups.ENEMY):
		_damage_enemy(collider)
	elif collider is TileMap or collider.is_in_group(Groups.WALL):
		_hit_wall()

	_despawn()


func _damage_enemy(enemy: Node) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		print("Projectile hit enemy for 1 damage!")


func _hit_wall() -> void:
	# Future: spawn particle effect, play sound
	pass


func _despawn() -> void:
	queue_free()

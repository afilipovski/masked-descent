extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed = 200.0
var lifetime = 1.5
var max_distance = 400.0
var traveled_distance = 0.0
var damage = 2

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()

func set_damage(new_damage: int) -> void:
	damage = new_damage

func set_speed(new_speed: float) -> void:
	speed = new_speed

func _ready():
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	# Set collision detection
	monitoring = true
	monitorable = false

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		_despawn()
		return

	# Move the projectile
	var movement = direction * speed * delta
	position += movement
	traveled_distance += movement.length()

	if traveled_distance >= max_distance:
		_despawn()

func _on_body_entered(body: Node2D) -> void:
	print("Enemy projectile hit body: ", body.name, " groups: ", body.get_groups())

	# Check if it's the player
	if body.is_in_group(Groups.PLAYER):
		_damage_player(body)
		_despawn()
	# Ignore enemies
	elif body.is_in_group(Groups.ENEMY):
		print("Projectile ignoring enemy")
		return
	# Hit wall or other solid object
	else:
		print("Projectile hit obstacle, despawning")
		_despawn()

func _damage_player(player: Node2D) -> void:
	if player.has_method("take_damage"):
		player.take_damage(damage)
		print("Enemy projectile dealt ", damage, " damage to player!")
	else:
		print("Player doesn't have take_damage method!")

func _despawn() -> void:
	print("Enemy projectile despawning")
	queue_free()
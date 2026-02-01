extends CharacterBody2D

var direction: Vector2 = Vector2.RIGHT
var speed = 220.0
var lifetime = 1.2
var max_distance = 500.0
var traveled_distance = 0.0
var damage = 4
@export var fire_sound: AudioStream
@export var fire_sound_volume_db: float = 0.0

func _ready() -> void:
	# Play a firing sound when the projectile is spawned. The AudioStreamPlayer2D
	# is added to the scene tree and freed when it finishes.
	if fire_sound:
		var player: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
		player.stream = fire_sound
		player.volume_db = fire_sound_volume_db
		# Use SFX bus if it exists
		if AudioServer.get_bus_index("SFX") != -1:
			player.bus = "SFX"

		# Add to a stable parent so the player stays active even if the projectile
		# gets freed quickly. Prefer the projectile's parent, fallback to root.
		var root_node: Node = get_parent()
		if not root_node:
			root_node = get_tree().get_root()
		root_node.add_child(player)
		player.global_position = global_position
		player.play()
		player.connect("finished", Callable(player, "queue_free"))

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

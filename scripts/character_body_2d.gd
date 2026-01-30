extends CharacterBody2D

const PROJECTILE_SPELL = preload("uid://cvhml3bqscuh2")

const SPEED = 200.0
const FIRE_COOLDOWN = 0.5 # Seconds between shots
const STAIRS_SOURCE = 2

@export var max_health: int = 10
var health: int
var fire_timer = 0.0 # Time elapsed since last shot

signal health_changed(new_health: int)
signal player_died

func _ready() -> void:
	add_to_group(Groups.PLAYER)
	health = max_health
	reset_position()
	reset_position()


func reset_position() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("get_spawn_position"):
		position = tilemap.get_spawn_position()


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector(
		Inputs.MOVE_LEFT,
		Inputs.MOVE_RIGHT,
		Inputs.MOVE_UP,
		Inputs.MOVE_DOWN
	)

	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()

	check_stairs()

	if fire_timer > 0:
		fire_timer -= delta

	var shoot_direction := Input.get_vector(
		Inputs.SHOOT_LEFT,
		Inputs.SHOOT_RIGHT,
		Inputs.SHOOT_UP,
		Inputs.SHOOT_DOWN
	)

	if shoot_direction != Vector2.ZERO and fire_timer <= 0:
		shoot(shoot_direction)
		fire_timer = FIRE_COOLDOWN


func shoot(direction: Vector2) -> void:
	var projectile = PROJECTILE_SPELL.instantiate()

	get_parent().add_child(projectile)
	projectile.global_position = global_position

	if projectile.has_method("set_direction"):
		projectile.set_direction(direction)
	elif "velocity" in projectile:
		projectile.velocity = direction.normalized()
	elif "direction" in projectile:
		projectile.direction = direction.normalized()


func check_stairs() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap:
		var tile_pos = tilemap.local_to_map(position)
		var tile_source = tilemap.get_cell_source_id(0, tile_pos)

		if tile_source == STAIRS_SOURCE:
			descend_to_next_level()


func descend_to_next_level() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("regenerate"):
		tilemap.regenerate()


func take_damage(amount: int):
	health -= amount
	health_changed.emit(health)
	print("Player took damage! Health: ", health)

	if health <= 0:
		die()

func die():
	print("Player died!")
	player_died.emit()
	health = max_health
	reset_position()

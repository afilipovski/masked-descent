extends CharacterBody2D

const PROJECTILE_SPELL = preload("uid://cvhml3bqscuh2")
const MELEE_HITBOX = preload("uid://bpgefom8c5e3c")


const SPEED = 200.0
const SPRINT_MULTIPLIER = 1.8
const FIRE_COOLDOWN = 0.5 # Seconds between shots
const STAIRS_SOURCE = 2

@export var max_health: int = 10
@export var wall_collision_damage: int = 2

@onready var mask_sprite = $MaskSprite

var health: int
var fire_timer = 0.0 # Time elapsed since last shot

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 800.0

# Mask textures
var mask_textures = []
@onready var combat_manager: CombatManager = CombatManager.new()
@onready var sprite: Sprite2D = $Sprite2D

signal health_changed(new_health: int)
signal player_died

func _ready() -> void:
	add_to_group(Groups.PLAYER)
	add_child(combat_manager)
	reset_position()

	# Load mask textures
	mask_textures = [
		load("res://assets/mask_1.png"),
		load("res://assets/mask_2.png"),
		load("res://assets/mask_3.png")
	]

	# Set initial mask
	if mask_textures.size() > 0:
		mask_sprite.texture = mask_textures[0]

func reset_position() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("get_spawn_position"):
		position = tilemap.get_spawn_position()

func _physics_process(delta: float) -> void:
	if _handle_knockback(delta):
		move_and_slide()
		_check_wall_collision_damage()
		return

	if Input.is_action_just_pressed(Inputs.CYCLE_MASK):
		combat_manager.cycle_mask()
		combat_manager.activate_mobility()

	var direction := Input.get_vector(
		Inputs.MOVE_LEFT,
		Inputs.MOVE_RIGHT,
		Inputs.MOVE_UP,
		Inputs.MOVE_DOWN
	)

	var current_speed = SPEED
	if Input.is_action_pressed(Inputs.SPRINT):
		current_speed *= SPRINT_MULTIPLIER

	current_speed *= combat_manager.get_speed_multiplier()

	if direction != Vector2.ZERO:
		velocity = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	check_stairs()

	if sprite:
		var mod = sprite.modulate
		mod.a = combat_manager.get_opacity()
		sprite.modulate = mod

	if fire_timer > 0:
		fire_timer -= delta

	var shoot_direction := Input.get_vector(
		Inputs.SHOOT_LEFT,
		Inputs.SHOOT_RIGHT,
		Inputs.SHOOT_UP,
		Inputs.SHOOT_DOWN
	)

	if shoot_direction != Vector2.ZERO and fire_timer <= 0:
		combat_manager.perform_attack(self , shoot_direction)

		match combat_manager.current_mask:
			Masks.Type.RANGED:
				shoot(shoot_direction)
				fire_timer = FIRE_COOLDOWN
			Masks.Type.MELEE:
				spawn_melee_hitbox(shoot_direction)
				fire_timer = FIRE_COOLDOWN
			Masks.Type.MOBILITY:
				pass

func _handle_knockback(delta: float) -> bool:
	if knockback_velocity.length() > 0:
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

	var is_player_knocked_back = knockback_velocity.length() > 50.0

	if is_player_knocked_back:
		velocity = knockback_velocity
		return true

	return false

func shoot(direction: Vector2) -> void:
	var projectile = PROJECTILE_SPELL.instantiate()
	get_parent().add_child(projectile)

	var spawn_offset = direction.normalized() * 20
	projectile.global_position = global_position + spawn_offset

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

func _check_wall_collision_damage():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is not TileMap or !(collider and collider.is_in_group(Groups.WALL)):
			continue

		var is_knockback_significant = knockback_velocity.length() > 100.0
		if !is_knockback_significant:
			continue

		take_damage(wall_collision_damage)
		print("Player hit wall during knockback! Took ", wall_collision_damage, " damage")

		knockback_velocity = knockback_velocity * 0.3
		break

func apply_knockback(force: Vector2):
	knockback_velocity = force

func _on_mask_changed(mask_index: int):
	if mask_index >= 0 and mask_index < mask_textures.size():
		mask_sprite.texture = mask_textures[mask_index]
		print("Player mask changed to: ", mask_index)

func spawn_melee_hitbox(direction: Vector2) -> void:
	var hitbox = MELEE_HITBOX.instantiate()
	get_parent().add_child(hitbox)

	var offset = direction.normalized() * 20
	hitbox.global_position = global_position + offset
	hitbox.rotation = direction.angle()

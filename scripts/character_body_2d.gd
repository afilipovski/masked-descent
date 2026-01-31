extends CharacterBody2D

const PROJECTILE_SPELL = preload("uid://cvhml3bqscuh2")
const MELEE_HITBOX = preload("uid://bpgefom8c5e3c")


const SPEED = 200.0
const SPRINT_MULTIPLIER = 1.8
const FIRE_COOLDOWN = 0.5 # Seconds between shots
const STAIRS_SOURCE = 2
const DOOR_SOURCE = 9

@export var max_health: int = 10
@export var wall_collision_damage: int = 2

@onready var mask_sprite = $MaskSprite

var health: int
var fire_timer = 0.0 # Time elapsed since last shot

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 800.0
var original_collision_mask: int = 0

# Mask textures
var mask_textures = []
@onready var combat_manager: CombatManager = CombatManager.new()
@onready var sprite: Sprite2D = $Sprite2D
var movement_locked: bool = false

signal health_changed(new_health: int)
signal player_died

func _ready() -> void:
	add_to_group(Groups.PLAYER)
	add_child(combat_manager)
	health = max_health
	reset_position()

	combat_manager.mask_changed.connect(_on_combat_mask_changed)
	combat_manager.stealth_activated.connect(_on_stealth_activated)
	combat_manager.stealth_deactivated.connect(_on_stealth_deactivated)

	# Load mask textures
	mask_textures = [
		load("res://assets/mask_1.png"),
		load("res://assets/mask_2.png"),
		load("res://assets/mask_3.png")
	]

	# Set initial mask
	if mask_textures.size() > 0:
		mask_sprite.texture = mask_textures[0]
	original_collision_mask = collision_mask

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

	# Don't allow movement if locked (e.g., during UI interactions)
	if movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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
	_check_door_collision()
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
				if combat_manager.try_activate_stealth():
					fire_timer = FIRE_COOLDOWN

	# Check for interact input
	if Input.is_action_just_pressed(Inputs.INTERACT):
		_handle_interact_input()


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

		# Only allow descending on stairs (not door)
		if tile_source == STAIRS_SOURCE:
			descend_to_next_level()

func _check_door_collision() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if not tilemap or not tilemap.has_method("is_door_position"):
		return

	var tile_pos = tilemap.local_to_map(position)
	if tilemap.is_door_position(tile_pos):
		# Push player back from door
		var door_world_pos = tilemap.map_to_local(tile_pos)
		var push_direction = (position - door_world_pos).normalized()
		position += push_direction * 2.0

func descend_to_next_level() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("regenerate"):
		GameState.increment_level()
		GameState.add_score(20)
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

func spawn_melee_hitbox(direction: Vector2) -> void:
	var hitbox = MELEE_HITBOX.instantiate()
	get_parent().add_child(hitbox)

	var offset = direction.normalized() * 20
	hitbox.global_position = global_position + offset
	hitbox.rotation = direction.angle()

func lock_movement():
	movement_locked = true

func unlock_movement():
	movement_locked = false

func _handle_interact_input():
	print("Player pressed interact key!")
	# Find nearby interactables
	var interactables = get_tree().get_nodes_in_group("interactables")
	for interactable in interactables:
		if interactable.has_method("_is_player_near") and interactable._is_player_near():
			print("Found nearby interactable: ", interactable.name)
			if interactable.has_method("open_chest"):
				if not interactable.is_opened:
					print("Opening chest...")
					interactable.open_chest()
				else:
					print("Chest is already opened")
			break

func _on_combat_mask_changed(mask_type: Masks.Type):
	var mask_index = mask_type as int
	if mask_index >= 0 and mask_index < mask_textures.size():
		mask_sprite.texture = mask_textures[mask_index]

	var mask_ui = get_parent().get_node_or_null("UI/MaskInventory")
	if mask_ui and mask_ui.has_method("update_display"):
		mask_ui.update_display(mask_type)

	print("Player mask changed to: ", Masks.get_mask_name(mask_type))

func _on_stealth_activated():
	enable_enemy_phasing()

func _on_stealth_deactivated():
	disable_enemy_phasing()

func enable_enemy_phasing():
	# Disable collision with enemy layer (layer 4, which is bit 3 in 0-indexed)
	# Enemy collision_layer = 141 = binary 10001101
	# We need to turn off bits that would collide with enemies
	# Since enemies are on multiple layers, we'll just disable the specific enemy bits
	# Bit 0 (1), Bit 2 (4), Bit 3 (8), Bit 7 (128) = 141
	collision_mask &= ~141

func disable_enemy_phasing():
	collision_mask = original_collision_mask

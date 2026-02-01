extends CharacterBody2D

const PROJECTILE_SPELL = preload("uid://cvhml3bqscuh2")
const MELEE_HITBOX = preload("uid://bpgefom8c5e3c")
const SWOOSH_ATTACK = preload("uid://dlnsqouc8xk2q")
const DEATH_EFFECT = preload("res://scenes/death_effect.tscn")

const BOSS_LASER_COOLDOWN = 2
const SPEED = 200.0
const FIRE_COOLDOWN = 0.5 # Seconds between shots
const STAIRS_SOURCE = 2
const DOOR_SOURCE = 9

@export var max_health: int = 15
@export var wall_collision_damage: int = 2

@onready var mask_sprite = $MaskSprite

var health: int
var fire_timer = 0.0 # Time elapsed since last shot

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_friction: float = 800.0
var original_collision_mask: int = 0
var original_collision_layer: int = 0

# Mask textures
var mask_textures = []
@onready var combat_manager: CombatManager = CombatManager.new()
@onready var powerup_manager: PowerupManager = PowerupManager.new()
@onready var sprite: Sprite2D = $Sprite2D
var movement_locked: bool = false
var is_dead: bool = false

signal health_changed(new_health: int)
signal player_died

func _ready() -> void:
	add_to_group(Groups.PLAYER)
	combat_manager.name = "CombatManager"
	powerup_manager.name = "PowerupManager"

	add_child(combat_manager)
	add_child(powerup_manager)
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
	while mask_textures.size() <= Masks.Type.BOSS:
		mask_textures.append(null)

	# Set initial mask
	_on_combat_mask_changed(combat_manager.current_mask)
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask

func _grant_start_boss_mask() -> void:
	unlock_mask(Masks.Type.BOSS, load("res://assets/boss_mask.png"))

func reset_position() -> void:
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("get_spawn_position"):
		position = tilemap.get_spawn_position()

	# Reset player state
	is_dead = false
	health = max_health
	sprite.show()
	mask_sprite.show()
	health_changed.emit(health)

	# Unpause the game
	get_tree().paused = false

func _physics_process(delta: float) -> void:
	# Disable all input when dead
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

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

	var current_speed = SPEED * combat_manager.get_speed_multiplier()

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
			Masks.Type.BOSS:
				spawn_boss_laser(shoot_direction)
				fire_timer = BOSS_LASER_COOLDOWN

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
	
	# Set projectile damage from powerup manager
	if "damage" in projectile:
		projectile.damage = powerup_manager.get_ranged_damage()

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
	is_dead = true

	# Spawn death effect at player position
	var death_effect = DEATH_EFFECT.instantiate()
	death_effect.process_mode = Node.PROCESS_MODE_ALWAYS # Keep playing during pause
	get_parent().add_child(death_effect)
	death_effect.global_position = global_position

	# Hide player sprite and mask
	sprite.hide()
	mask_sprite.hide()

	# Freeze the game
	get_tree().paused = true

	player_died.emit()

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
	var combo_damage = powerup_manager.get_melee_damage(combat_manager.melee_combo_count)
	var combo_scale = combat_manager.get_melee_scale()
	var offset = direction.normalized() * 20
	var swoosh = SWOOSH_ATTACK.instantiate()

	get_parent().add_child(hitbox)
	get_parent().add_child(swoosh)
	hitbox.damage = combo_damage
	hitbox.scale = Vector2(combo_scale, combo_scale)
	hitbox.global_position = global_position + offset
	hitbox.rotation = direction.angle()
	swoosh.global_position = global_position + offset
	swoosh.set_direction(direction)
	swoosh.scale = Vector2(combo_scale, combo_scale)

func spawn_boss_laser(direction: Vector2) -> void:
	var attack = Node2D.new()
	attack.set_script(load("res://scripts/boss_laser_attack.gd"))
	attack.boss_scene = load("res://scenes/boss.tscn")
	attack.global_position = global_position
	attack.direction = direction.normalized()
	get_parent().add_child(attack)
	lock_movement()
	if attack.has_signal("finished"):
		attack.connect("finished", Callable(self, "_on_boss_laser_finished"))

func _on_boss_laser_finished() -> void:
	unlock_movement()

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
					# Connect to powerup selection if not already connected
					if not interactable.powerup_selected.is_connected(_on_powerup_selected):
						interactable.powerup_selected.connect(_on_powerup_selected)
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

func unlock_mask(mask_type: Masks.Type, texture: Texture2D) -> void:
	combat_manager.unlock_mask(mask_type)
	var idx = mask_type as int
	while mask_textures.size() <= idx:
		mask_textures.append(null)
	mask_textures[idx] = texture
	var mask_ui = get_parent().get_node_or_null("UI/MaskInventory")
	if mask_ui and mask_ui.has_method("add_mask_texture"):
		mask_ui.add_mask_texture(mask_type, texture)
	_on_combat_mask_changed(combat_manager.current_mask)
	print("Unlocked mask: ", Masks.get_mask_name(mask_type))

func _on_stealth_activated():
	enable_enemy_phasing()

func _on_stealth_deactivated():
	disable_enemy_phasing()

func _on_powerup_selected(powerup: PowerupData):
	print("Applying powerup: ", powerup.display_name)
	powerup_manager.apply_powerup(powerup)
	
	# Update combat manager cooldown if stealth powerup was selected
	if powerup.type == PowerupData.Type.STEALTH_COOLDOWN:
		combat_manager.STEALTH_COOLDOWN = powerup_manager.get_stealth_cooldown()

func enable_enemy_phasing():
	# Remove player from physics layers so enemies can't detect us
	# Player is on layer 8 (bit 3), enemies check for layer 8
	collision_layer = 0 # Remove from all collision layers
	collision_mask &= ~4 # Also stop colliding with enemy layer (layer 3 = bit 2)

func disable_enemy_phasing():
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask

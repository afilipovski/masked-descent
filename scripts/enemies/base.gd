extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 150.0
@export var damage: int = 1
@export var detection_range: float = 200.0
@export var health: int = 3
@export var max_health: int = 3
@export var death_effect_scene: PackedScene
@export var damage_number_scene: PackedScene = preload("res://scenes/effects/damage_number.tscn")

var player: Node2D
var damage_timer: Timer
var player_in_hitbox: bool = false
var original_modulate: Color

func _ready():
	add_to_group(Groups.ENEMY)
	setup_damage_timer()
	_animate_enemy()
	# Store original color for flicker effect
	var sprite = $AnimatedSprite2D
	if sprite:
		original_modulate = sprite.modulate
	_on_ready()

func _on_ready():
	pass

func _physics_process(_delta: float) -> void:
	if not player:
		find_player()
		return

	_update_hitbox_detection()

	_update_movement(_delta)
	move_and_slide()

func _update_movement(_delta: float):
	chase_player()

func find_player():
	var players = get_tree().get_nodes_in_group(Groups.PLAYER)
	if players.size() > 0:
		player = players[0]

func chase_player():
	if not player:
		return

	if not can_detect_player():
		velocity = Vector2.ZERO
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player <= detection_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

func setup_damage_timer():
	damage_timer = Timer.new()
	damage_timer.wait_time = 1.0
	damage_timer.one_shot = false
	damage_timer.autostart = false
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

func take_damage(amount: int):
	health -= amount
	_show_damage_number(amount)
	_flash_red()
	_on_damage_taken(amount)
	if health <= 0:
		die()

func _on_damage_taken(_amount: int):
	pass

func _show_damage_number(amount: int):
	if !damage_number_scene:
		return
	
	var damage_number = damage_number_scene.instantiate()
	get_parent().add_child(damage_number)
	damage_number.global_position = global_position + Vector2(0, -20)
	damage_number.set_damage(amount)

func _flash_red():
	var sprite = $AnimatedSprite2D
	if !sprite:
		return
	
	# Flash red briefly
	sprite.modulate = Color.RED
	
	# Create tween to return to normal color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.15)

func die():
	_on_death()
	GameState.add_score(10)
	queue_free()


func _on_death():
	if !death_effect_scene:
		return

	var effect = death_effect_scene.instantiate()
	get_parent().add_child(effect)
	effect.global_position = global_position


func _on_hitbox_body_entered(body: Node2D):
	print("Hitbox detected body: ", body.name, " groups: ", body.get_groups())
	if body.is_in_group(Groups.PLAYER):
		if not can_detect_player():
			print("Cannot detect player due to stealth")
			return

		print("Player entered hitbox!")
		player_in_hitbox = true
		_attack_player(body)
		damage_timer.start()
	else:
		print("Body is not in player group")

func _on_hitbox_body_exited(body: Node2D):
	print("Hitbox body exited: ", body.name)
	if body.is_in_group(Groups.PLAYER):
		player_in_hitbox = false
		damage_timer.stop()

func _on_damage_timer_timeout():
	if player_in_hitbox and player:
		if not can_detect_player():
			damage_timer.stop()
			player_in_hitbox = false
			return

		_attack_player(player)

func _attack_player(player_body: Node2D):
	# Override in subclasses for custom attack behavior
	deal_damage_to_player(player_body)

func deal_damage_to_player(player_body: Node2D):
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage)

func can_detect_player() -> bool:
	if not player:
		return false

	if player.has_node("CombatManager"):
		var combat_manager = player.get_node("CombatManager") as CombatManager
		if combat_manager.is_player_stealthed():
			return not combat_manager.is_player_stealthed()
	return true

func _update_hitbox_detection():
	# Check if player stealth state changed while in hitbox
	var hitbox = get_node_or_null("Hitbox")
	if not hitbox or not player:
		return

	var is_overlapping = hitbox.overlaps_body(player)
	var can_detect = can_detect_player()

	# Player in hitbox and detectable, but we're not tracking them
	if is_overlapping and can_detect and not player_in_hitbox:
		player_in_hitbox = true
		_attack_player(player)
		damage_timer.start()

	# Player in hitbox but NOT detectable (stealthed), stop attacking
	elif is_overlapping and not can_detect and player_in_hitbox:
		player_in_hitbox = false
		damage_timer.stop()

	# Player left hitbox
	elif not is_overlapping and player_in_hitbox:
		player_in_hitbox = false
		damage_timer.stop()

func _animate_enemy():
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play()

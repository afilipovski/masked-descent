extends CharacterBody2D

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var sprite: Sprite2D = $Sprite2D

signal boss_defeated

@export var hit_sound: AudioStream
@export var hit_sound_volume_db: float = 0.0

@export var damage: int = 3
@export var hitbox_radius: float = 24.0
@export var damage_interval: float = 1.0
@export var damage_number_scene: PackedScene = preload("res://scenes/effects/damage_number.tscn")

var direction: Vector2
var player_detected: bool = false
var DEF = 0
var damage_timer: Timer
var player_in_hitbox: bool = false
var original_modulate: Color

var health = 100:
	set(value):
		health = value

		if value <= 0:
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= 100 / 2 and DEF == 0:
			DEF = 2
			find_child("FiniteStateMachine").change_state("ArmorBuff")

func _ready():
	add_to_group(Groups.ENEMY)
	_setup_hitbox()
	set_physics_process(false)
	# Store original color for flicker effect
	if sprite:
		original_modulate = sprite.modulate

func _process(_delta):
	if player == null:
		return

	# Check if player is stealthed - lose detection
	if player_detected and player.has_node("CombatManager"):
		var combat_manager = player.get_node("CombatManager") as CombatManager
		if combat_manager and combat_manager.is_player_stealthed():
			player_detected = false

	direction = player.global_position - global_position

	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _physics_process(delta):
	if player == null:
		return

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * 40
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func take_damage(amount: int = 10):
	var actual_damage = max(1, amount - DEF)

	# Play hit sound for boss if assigned
	if hit_sound and actual_damage > 0:
		var _player = AudioStreamPlayer2D.new()
		_player.stream = hit_sound
		_player.volume_db = hit_sound_volume_db
		if AudioServer.get_bus_index("SFX") != -1:
			_player.bus = "SFX"

		var root_node: Node = get_parent()
		if not root_node:
			root_node = get_tree().get_root()
		root_node.add_child(_player)
		_player.global_position = global_position
		_player.play()
		_player.connect("finished", Callable(_player, "queue_free"))

	health -= actual_damage
	_show_damage_number(actual_damage)
	_flash_red()

func _show_damage_number(amount: int):
	if !damage_number_scene or amount <= 0:
		return
	
	var damage_number = damage_number_scene.instantiate()
	get_parent().add_child(damage_number)
	damage_number.global_position = global_position + Vector2(0, -40)
	damage_number.set_damage(amount)

func _flash_red():
	if !sprite:
		return
	
	# Flash red briefly
	sprite.modulate = Color.RED
	
	# Create tween to return to normal color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", original_modulate, 0.15)

func _setup_hitbox() -> void:
	var hitbox = Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.monitoring = true
	hitbox.monitorable = true
	hitbox.collision_layer = 0
	hitbox.collision_mask = 1 << 3 # Player is on layer 8 (bit 3)
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = hitbox_radius
	shape.shape = circle
	hitbox.add_child(shape)
	add_child(hitbox)
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox.body_exited.connect(_on_hitbox_body_exited)

	damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.one_shot = false
	damage_timer.autostart = false
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group(Groups.PLAYER):
		return
	if not can_detect_player():
		return
	player_in_hitbox = true
	_attack_player(body)
	damage_timer.start()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group(Groups.PLAYER):
		player_in_hitbox = false
		damage_timer.stop()

func _on_damage_timer_timeout() -> void:
	if player_in_hitbox and player and can_detect_player():
		_attack_player(player)

func _attack_player(player_body: Node2D) -> void:
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage)

func can_detect_player() -> bool:
	if not player:
		return false
	if player.has_node("CombatManager"):
		var combat_manager = player.get_node("CombatManager") as CombatManager
		if combat_manager and combat_manager.is_player_stealthed():
			return false
	return true

func die():
	GameState.add_score(50)
	var player_node = get_tree().get_first_node_in_group(Groups.PLAYER)
	if player_node and player_node.has_method("unlock_mask"):
		var texture = load("res://assets/boss_mask.png")
		player_node.unlock_mask(Masks.Type.BOSS, texture)
	boss_defeated.emit()
	queue_free()

extends CharacterBody2D
class_name BaseEnemy

@export var speed: float = 150.0
@export var damage: int = 1
@export var detection_range: float = 200.0
@export var health: int = 3
@export var max_health: int = 3

var player: Node2D
var damage_timer: Timer
var player_in_hitbox: bool = false

func _ready():
	add_to_group(Groups.ENEMY)
	setup_damage_timer()
	_animate_enemy()
	_on_ready()

func _on_ready():
	pass

func _physics_process(_delta: float) -> void:
	if not player:
		find_player()
		return

	_update_movement(_delta)
	move_and_slide()

func _update_movement(_delta: float):
	chase_player()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func chase_player():
	if not player:
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
	_on_damage_taken(amount)
	if health <= 0:
		die()

func _on_damage_taken(_amount: int):
	pass

func die():
	_on_death()
	queue_free()

func _on_death():
	pass

func _on_hitbox_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_hitbox = true
		_attack_player(body)
		damage_timer.start()

func _on_hitbox_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_hitbox = false
		damage_timer.stop()

func _on_damage_timer_timeout():
	if player_in_hitbox and player:
		_attack_player(player)

func _attack_player(player_body: Node2D):
	# Override in subclasses for custom attack behavior
	deal_damage_to_player(player_body)

func deal_damage_to_player(player_body: Node2D):
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage)

func _animate_enemy():
	var animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play()

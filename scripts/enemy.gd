extends CharacterBody2D

@export var speed: float = 220.0
@export var damage: int = 1
@export var detection_range: float = 200.0
@export var health: int = 3

var player: Node2D
var damage_timer: Timer
var player_in_hitbox: bool = false

func _ready():
	add_to_group("enemies")

	damage_timer = Timer.new()
	damage_timer.wait_time = 1.0
	damage_timer.one_shot = false
	damage_timer.autostart = false
	damage_timer.timeout.connect(_on_damage_timer_timeout)
	add_child(damage_timer)

func _physics_process(_delta: float) -> void:
	if not player:
		find_player()
		return

	chase_player()
	move_and_slide()

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

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()
		

func die():
	queue_free()

func _on_hitbox_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_in_hitbox = true
		deal_damage_to_player(body)
		damage_timer.start()

func _on_hitbox_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_in_hitbox = false
		damage_timer.stop()

func _on_damage_timer_timeout():
	if player_in_hitbox and player:
		deal_damage_to_player(player)

func deal_damage_to_player(player_body: Node2D):
	if player_body.has_method("take_damage"):
		player_body.take_damage(damage)

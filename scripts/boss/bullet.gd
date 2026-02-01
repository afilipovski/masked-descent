extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")

@export var damage: int = 3

var acceleration: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Detect player (layer 8) and walls/tiles (layer 1).
	collision_mask = 1 | 8
	monitoring = true

func _physics_process(delta):
	if player == null:
		return

	acceleration = (player.global_position - global_position).normalized() * 700
	
	velocity += acceleration * delta
	rotation = velocity.angle()
	velocity = velocity.limit_length(150)
	global_position += velocity * delta

 # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(Groups.PLAYER) and body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

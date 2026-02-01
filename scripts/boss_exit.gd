extends Area2D

@export var texture: Texture2D = preload("res://assets/door.png")
@export var radius: float = 14.0

func _ready() -> void:
	monitoring = true
	monitorable = true
	collision_layer = 0
	collision_mask = 1 << 3 # Player layer (8)

	var sprite = Sprite2D.new()
	sprite.texture = texture
	add_child(sprite)

	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(Groups.PLAYER):
		return
	if body.has_method("descend_to_next_level"):
		body.descend_to_next_level()
	queue_free()

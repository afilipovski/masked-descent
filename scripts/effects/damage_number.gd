extends Label

@export var float_speed: float = 30.0
@export var lifetime: float = 0.8

var velocity: Vector2 = Vector2.ZERO

func _ready():
	# Set up visual properties
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", Color.RED)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 2)
	
	# Random horizontal offset
	velocity = Vector2(randf_range(-20, 20), -float_speed)
	
	# Start fade out animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, lifetime)
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), lifetime * 0.5)
	tween.chain().tween_callback(queue_free)

func _process(delta: float):
	position += velocity * delta
	velocity.y -= 10 * delta  # Slight upward acceleration

func set_damage(amount: int):
	text = str(amount)

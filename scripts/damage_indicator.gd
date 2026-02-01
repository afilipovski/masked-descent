extends Node2D
@onready var label: Label2D = $Label

func _ready():
    # ensure label is visible initially
    label.modulate = Color(1, 1, 1, 1)

func show_damage(amount: int, color: Color = Color(1, 1, 1)) -> void:
    # Set text and color, then animate upward and fade out
    label.text = str(amount)
    label.modulate = color

    # Slight random horizontal offset so overlapping numbers are readable
    position.x += randf_range(-6.0, 6.0)

    var target_offset := Vector2(0, -28)
    var duration := 0.6

    var tw = create_tween()
    tw.tween_property(self, "position", global_position + target_offset, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tw.tween_property(label, "modulate:a", 0.0, duration)
    tw.finished.connect(_on_tween_finished)

func _on_tween_finished() -> void:
    queue_free()
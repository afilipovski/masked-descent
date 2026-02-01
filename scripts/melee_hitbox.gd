extends Area2D
class_name MeleeHitbox

var damage: int = 3
@export var lifetime: float = 0.15

var _time_left: float = 0.0
func _ready() -> void:
	_time_left = lifetime
	monitoring = true
	monitorable = true

func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group(Groups.ENEMY):
		if body.has_method("take_damage"):
			body.take_damage(damage)

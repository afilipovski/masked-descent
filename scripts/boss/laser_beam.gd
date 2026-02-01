extends State

var can_transition: bool = false
var locked_target: Vector2 = Vector2.ZERO
@export var laser_length: float = 320.0
@export var laser_width: float = 40.0
@export var laser_damage: int = 6
@export var damage_interval: float = 0.2

func enter():
	super.enter()
	lock_target()
	await play_animation("laser_cast")
	_start_laser_damage()
	await play_animation("laser")
	can_transition = true

func play_animation(anim_name):
	animation_player.play(anim_name)
	await animation_player.animation_finished

func lock_target() -> void:
	if player == null or pivot == null:
		return

	locked_target = player.global_position
	pivot.look_at(locked_target)

func transition():
	if can_transition:
		can_transition = false
		get_parent().change_state("Follow")

func _start_laser_damage() -> void:
	if animation_player == null:
		return
	var laser_anim = animation_player.get_animation("laser")
	if laser_anim == null:
		return
	var duration = laser_anim.length
	_apply_laser_damage_over_time(duration)

func _apply_laser_damage_over_time(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		_apply_laser_damage_once()
		await get_tree().create_timer(damage_interval).timeout
		elapsed += damage_interval

func _apply_laser_damage_once() -> void:
	if player == null or character == null:
		return
	var origin = pivot.global_position if pivot else character.global_position
	var dir = (locked_target - origin).normalized()
	if dir == Vector2.ZERO and pivot:
		dir = Vector2.RIGHT.rotated(pivot.global_rotation)
	if dir == Vector2.ZERO:
		return
	var end_pos = origin + dir * laser_length
	var to_player = player.global_position - origin
	if to_player.dot(dir) < 0:
		return
	var dist = _distance_to_segment(player.global_position, origin, end_pos)
	if dist <= laser_width * 0.5:
		if player.has_method("take_damage"):
			player.take_damage(laser_damage)

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var t = 0.0
	if ab.length_squared() > 0.0:
		t = (p - a).dot(ab) / ab.length_squared()
		t = clamp(t, 0.0, 1.0)
	var closest = a + ab * t
	return p.distance_to(closest)

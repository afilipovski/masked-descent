extends Node2D

signal finished

@export var boss_scene: PackedScene
@export var direction: Vector2 = Vector2.RIGHT
@export var laser_length: float = 320.0
@export var laser_width: float = 40.0
@export var laser_damage: int = 8

var _boss_root: Node2D
var _boss_node: Node2D
var _animation_player: AnimationPlayer
var _pivot: Node2D

func _ready() -> void:
	if boss_scene == null:
		queue_free()
		return
	_setup_boss_visual()
	await _play_laser_sequence()
	finished.emit()
	queue_free()

func _setup_boss_visual() -> void:
	_boss_root = boss_scene.instantiate()
	add_child(_boss_root)

	_boss_node = _boss_root.get_node_or_null("boss")
	if _boss_node:
		_boss_node.set_script(null)
		var body_sprite = _boss_node.get_node_or_null("Sprite2D")
		if body_sprite:
			body_sprite.visible = false
		var collider = _boss_node.get_node_or_null("CollisionShape2D")
		if collider:
			collider.disabled = true
		var fsm = _boss_node.get_node_or_null("FiniteStateMachine")
		if fsm:
			fsm.queue_free()
		var detection = _boss_node.get_node_or_null("PlayerDetection")
		if detection:
			detection.queue_free()

		_animation_player = _boss_node.get_node_or_null("AnimationPlayer")
		_pivot = _boss_node.get_node_or_null("Pivot")

	if _pivot:
		var target = global_position + direction.normalized() * laser_length
		_pivot.look_at(target)

func _play_laser_sequence() -> void:
	if _animation_player == null:
		return

	if _animation_player.has_animation("laser_cast"):
		_animation_player.play("laser_cast")
		await _animation_player.animation_finished

	if _animation_player.has_animation("laser"):
		_animation_player.play("laser")
		_apply_laser_damage_over_time(_animation_player.get_animation("laser").length)
		await _animation_player.animation_finished

func _apply_laser_damage_over_time(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		_apply_laser_damage_once()
		await get_tree().create_timer(0.2).timeout
		elapsed += 0.2

func _apply_laser_damage_once() -> void:
	var origin = global_position
	var dir = direction.normalized()
	var end_pos = origin + dir * laser_length
	var enemies = get_tree().get_nodes_in_group(Groups.ENEMY)
	for enemy in enemies:
		if enemy == null or not enemy.is_inside_tree():
			continue
		var to_enemy = enemy.global_position - origin
		if to_enemy.dot(dir) < 0:
			continue
		var dist = _distance_to_segment(enemy.global_position, origin, end_pos)
		if dist <= laser_width * 0.5:
			if enemy.has_method("take_damage"):
				enemy.take_damage(laser_damage)

func _distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab = b - a
	var t = 0.0
	if ab.length_squared() > 0.0:
		t = (p - a).dot(ab) / ab.length_squared()
		t = clamp(t, 0.0, 1.0)
	var closest = a + ab * t
	return p.distance_to(closest)

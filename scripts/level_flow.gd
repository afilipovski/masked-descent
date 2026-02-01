extends Node2D

@export var boss_room_scene: PackedScene
@export var boss_scene: PackedScene

@onready var player: Node2D = $Player
@onready var dungeon_tilemap: TileMap = $TileMap

var boss_rooms: Array[Node2D] = []
var boss_spawn_cache: Dictionary = {}
var boss_defeated_handled: bool = false

func _ready() -> void:
	GameState.level_changed.connect(_on_level_changed)
	_apply_level_state(GameState.dungeon_level)

func _on_level_changed(new_level: int) -> void:
	_apply_level_state(new_level)

func _apply_level_state(level: int) -> void:
	var is_boss_level = GameState.is_boss_level(level)
	if is_boss_level:
		boss_defeated_handled = false
		_ensure_boss_room()
		_ensure_boss_present()
	else:
		_remove_boss_rooms()
	if dungeon_tilemap:
		dungeon_tilemap.visible = not is_boss_level
		dungeon_tilemap.process_mode = Node.PROCESS_MODE_INHERIT if not is_boss_level else Node.PROCESS_MODE_DISABLED
	if is_boss_level:
		_move_player_to_boss_spawn()

func _ensure_boss_room() -> void:
	if not boss_rooms.is_empty():
		return
	if boss_room_scene == null:
		push_warning("Boss room scene not assigned.")
		return
	var room = boss_room_scene.instantiate()
	if room is Node2D:
		room.name = "BossRoom"
		add_child(room)
		boss_rooms.append(room)
		_cache_boss_spawn(room)
	else:
		room.queue_free()

func _ensure_boss_present() -> void:
	if boss_rooms.is_empty():
		return
	var room = boss_rooms[0]
	var boss = _find_boss(room)
	if boss != null:
		_cache_boss_spawn(room)
		_bind_boss_signals(boss)
		return
	if boss_scene == null:
		push_warning("Boss scene not assigned.")
		return
	var boss_instance = boss_scene.instantiate()
	if boss_instance is Node2D:
		room.add_child(boss_instance)
		_bind_boss_signals(boss_instance)
		_apply_boss_spawn(boss_instance)
	else:
		boss_instance.queue_free()

func _remove_boss_rooms() -> void:
	for room in boss_rooms:
		if is_instance_valid(room):
			room.queue_free()
	boss_rooms.clear()

func _cache_boss_spawn(room: Node2D) -> void:
	var boss = _find_boss(room)
	if boss == null:
		return
	boss_spawn_cache["global_position"] = boss.global_position
	boss_spawn_cache["scale"] = boss.scale
	boss_spawn_cache["z_index"] = boss.z_index
	boss_spawn_cache["top_level"] = boss.top_level

func _apply_boss_spawn(boss: Node2D) -> void:
	if boss_spawn_cache.has("top_level"):
		boss.top_level = boss_spawn_cache["top_level"]
	if boss_spawn_cache.has("z_index"):
		boss.z_index = boss_spawn_cache["z_index"]
	if boss_spawn_cache.has("scale"):
		boss.scale = boss_spawn_cache["scale"]
	if boss_spawn_cache.has("global_position"):
		boss.global_position = boss_spawn_cache["global_position"]

func _find_boss(root: Node) -> Node2D:
	for child in root.get_children():
		if child is Node2D:
			var script = child.get_script()
			if script and script.resource_path == "res://scripts/boss/boss.gd":
				return child
		var found = _find_boss(child)
		if found != null:
			return found
	return null

func _bind_boss_signals(boss: Node2D) -> void:
	if boss.has_signal("boss_defeated"):
		if not boss.is_connected("boss_defeated", Callable(self, "_on_boss_defeated")):
			boss.connect("boss_defeated", Callable(self, "_on_boss_defeated"))

func _on_boss_defeated() -> void:
	if player and player.has_method("unlock_mask"):
		var texture = load("res://assets/boss_mask.png")
		player.unlock_mask(Masks.Type.BOSS, texture)
	if boss_defeated_handled:
		return
	boss_defeated_handled = true
	_advance_after_boss_delay()

func _advance_after_boss_delay() -> void:
	await get_tree().create_timer(5.0).timeout
	if player and player.has_method("descend_to_next_level"):
		player.descend_to_next_level()

func _move_player_to_boss_spawn() -> void:
	if not player or boss_rooms.is_empty():
		return
	var spawn_pos = _get_room_spawn_position(boss_rooms[0])
	player.global_position = spawn_pos

func _get_room_spawn_position(room: Node2D) -> Vector2:
	var spawn_marker := room.get_node_or_null("PlayerSpawn")
	if spawn_marker is Node2D:
		return spawn_marker.global_position
	var tilemap := room.get_node_or_null("TileMap")
	if tilemap is TileMap:
		var used: Array[Vector2i] = tilemap.get_used_cells(0)
		if used.size() > 0:
			var min_cell: Vector2i = used[0]
			var max_cell: Vector2i = used[0]
			for cell in used:
				min_cell.x = min(min_cell.x, cell.x)
				min_cell.y = min(min_cell.y, cell.y)
				max_cell.x = max(max_cell.x, cell.x)
				max_cell.y = max(max_cell.y, cell.y)
			var center_cell = Vector2i((min_cell.x + max_cell.x) / 2, (min_cell.y + max_cell.y) / 2)
			return tilemap.to_global(tilemap.map_to_local(center_cell))
	return room.global_position

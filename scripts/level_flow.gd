extends Node2D

@export var boss_room_scene: PackedScene

@onready var player: Node2D = $Player
@onready var dungeon_tilemap: TileMap = $TileMap

var boss_rooms: Array[Node2D] = []

func _ready() -> void:
	GameState.level_changed.connect(_on_level_changed)
	_apply_level_state(GameState.dungeon_level)

func _on_level_changed(new_level: int) -> void:
	_apply_level_state(new_level)

func _apply_level_state(level: int) -> void:
	var is_boss_level = GameState.is_boss_level(level)
	if is_boss_level:
		_ensure_boss_room()
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
	else:
		room.queue_free()

func _remove_boss_rooms() -> void:
	for room in boss_rooms:
		if is_instance_valid(room):
			room.queue_free()
	boss_rooms.clear()

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

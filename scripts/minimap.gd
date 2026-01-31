extends Control
class_name Minimap

@export_range(0.1, 0.5) var minimap_scale: float = 0.15 # 15% of viewport size
@export var room_color = Color(0.5, 0.5, 0.5)
@export var background_color = Color(0.1, 0.1, 0.1)
@export var stairs_color = Color(1, 0.8, 0)
@export var current_room_color = Color(0.8, 0.8, 0.8)
@export var corridor_color = Color(0.6, 0.6, 0.6)
@export var player_color = Color(0, 1, 1)

var minimap_size = Vector2(150, 150)

var rooms: Array[Rect2i] = []
var room_connections: Array[Vector2i] = []
var map_bounds = Rect2i()
var stairs_position = Vector2i.ZERO
var current_room_index = -1
var player: Node2D = null
var tilemap: TileMap = null

func _ready():
	update_minimap_size()
	custom_minimum_size = minimap_size

	get_viewport().size_changed.connect(_on_viewport_size_changed)

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group(Groups.PLAYER)
	tilemap = get_tree().get_first_node_in_group(Groups.TILEMAP)

func update_minimap_size() -> void:
	var viewport_size = get_viewport_rect().size
	var base_size = min(viewport_size.x, viewport_size.y) * minimap_scale
	minimap_size = Vector2(base_size, base_size)
	custom_minimum_size = minimap_size

func _on_viewport_size_changed() -> void:
	update_minimap_size()
	queue_redraw()

func _draw():
	var BACKGROUND = Rect2(Vector2.ZERO, minimap_size)
	var BORDER = Rect2(Vector2.ZERO, minimap_size)

	draw_rect(BACKGROUND, background_color, true)
	draw_rect(BORDER, Color.WHITE, false, 2.0)
	_draw_corridors()
	_draw_rooms()
	_draw_stairs()
	_draw_player()

func _process(_delta):
	if player and tilemap:
		update_current_room()
		queue_redraw() # Redraw every frame to update player position

func update_current_room() -> void:
	var tile_pos = tilemap.local_to_map(player.global_position)
	var new_room_index = _find_room_at(tile_pos)

	if new_room_index != current_room_index:
		current_room_index = new_room_index
		queue_redraw()

func update_dungeon_data(
	new_rooms: Array[Rect2i],
	new_stairs_position: Vector2i,
	connections: Array[Vector2i]
) -> void:
	rooms = new_rooms
	stairs_position = new_stairs_position
	room_connections = connections
	calculate_map_bounds()
	queue_redraw()

func calculate_map_bounds() -> void:
	if rooms.is_empty():
		return

	var min_x = rooms[0].position.x
	var min_y = rooms[0].position.y
	var max_x = rooms[0].end.x
	var max_y = rooms[0].end.y

	for room in rooms:
		min_x = min(min_x, room.position.x)
		min_y = min(min_y, room.position.y)
		max_x = max(max_x, room.end.x)
		max_y = max(max_y, room.end.y)

	map_bounds = Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)

func dungeon_to_minimap(dungeon_pos: Vector2) -> Vector2:
	if map_bounds.size.x == 0 or map_bounds.size.y == 0:
		return Vector2.ZERO

	const PADDING = 10.0
	var available_size = minimap_size - Vector2(PADDING * 2, PADDING * 2)

	var scale_x = available_size.x / float(map_bounds.size.x)
	var scale_y = available_size.y / float(map_bounds.size.y)
	var map_scale = min(scale_x, scale_y)

	var relative_pos = dungeon_pos - Vector2(map_bounds.position)
	return relative_pos * map_scale + Vector2(PADDING, PADDING)


func _draw_corridors():
	for connection in room_connections:
		var from_idx = connection.x
		var to_idx = connection.y

		if from_idx < 0 or from_idx >= rooms.size() or to_idx < 0 or to_idx >= rooms.size():
			continue

		var from_room = rooms[from_idx]
		var to_room = rooms[to_idx]

		# Get room centers in world coordinates
		var from_center = Vector2(
			from_room.position.x + from_room.size.x / 2.0,
			from_room.position.y + from_room.size.y / 2.0
		)
		var to_center = Vector2(
			to_room.position.x + to_room.size.x / 2.0,
			to_room.position.y + to_room.size.y / 2.0
		)

		# Convert to minimap coordinates
		var from_minimap = dungeon_to_minimap(from_center)
		var to_minimap = dungeon_to_minimap(to_center)

		# Draw line
		draw_line(from_minimap, to_minimap, corridor_color, 1.5)

func _draw_rooms():
	for i in range(rooms.size()):
		var room = rooms[i]
		var top_left = dungeon_to_minimap(Vector2(room.position))
		var bottom_right = dungeon_to_minimap(Vector2(room.end))
		var room_size = bottom_right - top_left

		var color = current_room_color if i == current_room_index else room_color
		draw_rect(Rect2(top_left, room_size), color, true)

func _draw_stairs():
	if stairs_position == Vector2i.ZERO:
		return

	var stairs_minimap_pos = dungeon_to_minimap(Vector2(stairs_position))
	draw_circle(stairs_minimap_pos, 3.0, stairs_color)

func _draw_player():
	if not player or not tilemap:
		return

	# Convert player's world position to tile coordinates
	var player_tile_pos = tilemap.local_to_map(player.global_position)
	var player_map_pos = dungeon_to_minimap(Vector2(player_tile_pos))
	draw_circle(player_map_pos, 2.5, player_color)

func _find_room_at(tile_pos: Vector2i) -> int:
	for i in range(rooms.size()):
		if rooms[i].has_point(tile_pos):
			return i
	return -1

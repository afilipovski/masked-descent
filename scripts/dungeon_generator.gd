extends TileMap

@export var map_width: int = 50
@export var map_height: int = 50
@export var room_min_size: int = 5
@export var room_max_size: int = 12
@export var max_rooms: int = 15
@export var min_room_spacing: int = 2

const FLOOR_SOURCE = 0
const WALL_SOURCE = 1
const ATLAS_COORDS = Vector2i(0, 0)

var rooms: Array[Rect2i] = []

func _ready():
	generate_dungeon()

func generate_dungeon():
	clear()
	rooms.clear()
	
	fill_with_walls()
	
	# Generate rooms
	for i in range(max_rooms):
		var room = create_random_room()
		if can_place_room(room):
			carve_room(room)
			
			if rooms.size() > 0:
				var prev_center = get_room_center(rooms[-1])
				var new_center = get_room_center(room)
				carve_corridor(prev_center, new_center)
			
			rooms.append(room)
	
	place_walls_around_floors()
	
	print("Generated dungeon with ", rooms.size(), " rooms")

func fill_with_walls():
	for x in range(-map_width/2, map_width/2):
		for y in range(-map_height/2, map_height/2):
			set_cell(0, Vector2i(x, y), WALL_SOURCE, ATLAS_COORDS)

func create_random_room() -> Rect2i:
	var w = randi_range(room_min_size, room_max_size)
	var h = randi_range(room_min_size, room_max_size)
	var x = randi_range(-map_width/2 + 1, map_width/2 - w - 1)
	var y = randi_range(-map_height/2 + 1, map_height/2 - h - 1)
	return Rect2i(x, y, w, h)

func can_place_room(room: Rect2i) -> bool:
	for existing_room in rooms:
		var expanded = existing_room.grow(min_room_spacing)
		if expanded.intersects(room):
			return false
	return true

func carve_room(room: Rect2i):
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			set_cell(0, Vector2i(x, y), FLOOR_SOURCE, ATLAS_COORDS)

func get_room_center(room: Rect2i) -> Vector2i:
	return Vector2i(
		room.position.x + room.size.x / 2,
		room.position.y + room.size.y / 2
	)

func carve_corridor(start: Vector2i, end: Vector2i):
	var current = start
	
	while current.x != end.x:
		set_cell(0, current, FLOOR_SOURCE, ATLAS_COORDS)
		current.x += 1 if end.x > current.x else -1
	
	while current.y != end.y:
		set_cell(0, current, FLOOR_SOURCE, ATLAS_COORDS)
		current.y += 1 if end.y > current.y else -1
	
	set_cell(0, end, FLOOR_SOURCE, ATLAS_COORDS)

func place_walls_around_floors():
	var floor_cells = get_used_cells(0)
	var wall_positions = {}
	
	for cell in floor_cells:
		if get_cell_source_id(0, cell) == FLOOR_SOURCE:
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if dx == 0 and dy == 0:
						continue
					var neighbor = Vector2i(cell.x + dx, cell.y + dy)
					if get_cell_source_id(0, neighbor) == -1 or get_cell_source_id(0, neighbor) == WALL_SOURCE:
						wall_positions[neighbor] = true
	
	for pos in wall_positions:
		var check_pos = Vector2i(pos)
		if get_cell_source_id(0, check_pos) != FLOOR_SOURCE:
			set_cell(0, check_pos, WALL_SOURCE, ATLAS_COORDS)

func get_spawn_position() -> Vector2:
	if rooms.size() > 0:
		var first_room = rooms[0]
		var center = get_room_center(first_room)
		return map_to_local(center)
	return Vector2.ZERO

func regenerate():
	generate_dungeon()
	get_tree().call_group("player", "reset_position")

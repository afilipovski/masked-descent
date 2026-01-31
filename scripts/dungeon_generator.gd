extends TileMap

@export var map_width: int = 50
@export var map_height: int = 50
@export var room_min_width: int = 6
@export var room_max_width: int = 14
@export var room_min_height: int = 4
@export var room_max_height: int = 10
@export var max_rooms: int = 15
@export var min_room_spacing: int = 2
@export var corridor_width: int = 3
@export var enemies_per_room_area: float = 0.02

const FLOOR_SOURCE = 0
const WALL_SOURCE = 1 # wall-test (fallback)
const STAIRS_SOURCE = 2
const WALL_N_SOURCE = 3
const WALL_S_SOURCE = 4
const WALL_E_SOURCE = 5
const WALL_W_SOURCE = 6
const WALL_NE_SOURCE = 7
const WALL_NW_SOURCE = 8
const ATLAS_COORDS = Vector2i(0, 0)

const ENEMY_SCENE = preload("res://scenes/enemies/dwarf.tscn")

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
	place_stairs()
	spawn_enemies()
	
	print("Generated dungeon with ", rooms.size(), " rooms")

func fill_with_walls():
	for x in range(-map_width / 2, map_width / 2):
		for y in range(-map_height / 2, map_height / 2):
			set_cell(0, Vector2i(x, y), WALL_SOURCE, ATLAS_COORDS)

func create_random_room() -> Rect2i:
	var w = randi_range(room_min_width, room_max_width)
	var h = randi_range(room_min_height, room_max_height)
	# Ensure room is not square by regenerating if w == h
	while w == h:
		h = randi_range(room_min_height, room_max_height)
	var x = randi_range(-map_width / 2 + 1, map_width / 2 - w - 1)
	var y = randi_range(-map_height / 2 + 1, map_height / 2 - h - 1)
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
	var half_width = corridor_width / 2
	
	while current.x != end.x:
		for offset in range(-half_width, half_width + 1):
			set_cell(0, Vector2i(current.x, current.y + offset), FLOOR_SOURCE, ATLAS_COORDS)
		current.x += 1 if end.x > current.x else -1
	
	while current.y != end.y:
		for offset in range(-half_width, half_width + 1):
			set_cell(0, Vector2i(current.x + offset, current.y), FLOOR_SOURCE, ATLAS_COORDS)
		current.y += 1 if end.y > current.y else -1
	
	for dx in range(-half_width, half_width + 1):
		for dy in range(-half_width, half_width + 1):
			set_cell(0, Vector2i(end.x + dx, end.y + dy), FLOOR_SOURCE, ATLAS_COORDS)

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
			var wall_type = get_wall_type_for_position(check_pos)
			set_cell(0, check_pos, wall_type, ATLAS_COORDS)

func get_wall_type_for_position(pos: Vector2i) -> int:
	# Check which directions have floor tiles
	var north_floor = get_cell_source_id(0, Vector2i(pos.x, pos.y + 1)) == FLOOR_SOURCE
	var south_floor = get_cell_source_id(0, Vector2i(pos.x, pos.y - 1)) == FLOOR_SOURCE
	var east_floor = get_cell_source_id(0, Vector2i(pos.x + 1, pos.y)) == FLOOR_SOURCE
	var west_floor = get_cell_source_id(0, Vector2i(pos.x - 1, pos.y)) == FLOOR_SOURCE
	
	# Check for corners (floor on two adjacent diagonal sides)
	var ne_floor = north_floor and east_floor
	var nw_floor = north_floor and west_floor
	var se_floor = south_floor and east_floor
	var sw_floor = south_floor and west_floor

	if north_floor and east_floor and west_floor and not south_floor:
		return FLOOR_SOURCE
	
	# Corners take priority
	if ne_floor and not south_floor and not west_floor:
		return WALL_S_SOURCE
	if nw_floor and not south_floor and not east_floor:
		return WALL_S_SOURCE
	if se_floor and not north_floor and not west_floor:
		return WALL_NE_SOURCE
	if sw_floor and not north_floor and not east_floor:
		return WALL_NW_SOURCE
	
	# Then cardinal directions
	if south_floor and not north_floor:
		return WALL_N_SOURCE
	if north_floor:
		return WALL_S_SOURCE
	if west_floor and not east_floor:
		return WALL_W_SOURCE
	if east_floor and not west_floor:
		return WALL_E_SOURCE
	
	# Default fallback
	return WALL_SOURCE

func get_spawn_position() -> Vector2:
	if rooms.size() > 0:
		var first_room = rooms[0]
		var center = get_room_center(first_room)
		return map_to_local(center)
	return Vector2.ZERO

func place_stairs():
	if rooms.size() > 0:
		var last_room = rooms[-1]
		var stairs_pos = get_room_center(last_room)
		set_cell(0, stairs_pos, STAIRS_SOURCE, ATLAS_COORDS)
		print("Placed stairs at: ", stairs_pos)

func spawn_enemies():
	clear_existing_enemies()
	
	var total_enemies = 0
	# Skip first room (player spawn) and last room (stairs)
	for i in range(1, rooms.size() - 1):
		var room = rooms[i]
		var room_area = room.size.x * room.size.y
		var num_enemies = max(1, int(room_area * enemies_per_room_area))
		
		print("Room ", i, " (", room.size.x, "x", room.size.y, ", area: ", room_area, "): spawning ", num_enemies, " enemies")
		
		for j in range(num_enemies):
			var enemy_instance = ENEMY_SCENE.instantiate()
			var spawn_pos = get_random_position_in_room(room)
			enemy_instance.global_position = map_to_local(spawn_pos)
			get_parent().add_child(enemy_instance)
			total_enemies += 1
	
	print("Total enemies spawned: ", total_enemies)

func get_random_position_in_room(room: Rect2i) -> Vector2i:
	var x = randi_range(room.position.x + 1, room.position.x + room.size.x - 2)
	var y = randi_range(room.position.y + 1, room.position.y + room.size.y - 2)
	return Vector2i(x, y)

func clear_existing_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		enemy.queue_free()

func regenerate():
	generate_dungeon()
	get_tree().call_group("player", "reset_position")

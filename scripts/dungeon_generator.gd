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
const DOOR_SOURCE = 9
const ATLAS_COORDS = Vector2i(0, 0)

const ENEMY_SCENE = preload("res://scenes/enemies/dwarf.tscn")
const CHEST_SCENE = preload("res://scenes/interactables/treasure_chest.tscn")
# Alternative: Load at runtime to debug
# var CHEST_SCENE = load("res://scenes/interactables/treasure_chest.tscn")

var rooms: Array[Rect2i] = []
var room_connections: Array[Vector2i] = []
var door_position: Vector2i = Vector2i.ZERO
var total_enemies: int = 0
var door_open: bool = false
var chest_position: Vector2i = Vector2i.ZERO

signal dungeon_generated(rooms_data: Array[Rect2i], stairs_position: Vector2i, connections: Array[Vector2i], chest_pos: Vector2i)
signal door_opened()

func _ready():
	generate_dungeon()

func generate_dungeon():
	clear()
	rooms.clear()
	room_connections.clear()
	door_open = false
	total_enemies = 0
	chest_position = Vector2i.ZERO

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
				# Record connection between previous room and new room
				room_connections.append(Vector2i(rooms.size() - 1, rooms.size()))

			rooms.append(room)

	# Phase 1: Enforce tile adjacency rules (place generic walls)
	place_walls_around_floors()
	remove_thin_walls()

	# Phase 2: Texture walls with appropriate tile types
	texture_walls()

	place_door()
	total_enemies = spawn_enemies()
	# Spawn chest after everything else is set up
	call_deferred("spawn_chest_and_emit_signal")

	print("Generated dungeon with ", rooms.size(), " rooms and ", total_enemies, " enemies")

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
	# Keep rooms at least 2 tiles away from map edges to ensure wall border
	var x = randi_range(-map_width / 2 + 2, map_width / 2 - w - 2)
	var y = randi_range(-map_height / 2 + 2, map_height / 2 - h - 2)
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

	# Place generic walls (enforce adjacency rules only)
	for pos in wall_positions:
		var check_pos = Vector2i(pos)
		if get_cell_source_id(0, check_pos) != FLOOR_SOURCE:
			set_cell(0, check_pos, WALL_SOURCE, ATLAS_COORDS)

func remove_thin_walls():
	var changed = true
	while changed:
		changed = false
		var used_cells = get_used_cells(0)

		for cell in used_cells:
			var source_id = get_cell_source_id(0, cell)
			if source_id == FLOOR_SOURCE or source_id == STAIRS_SOURCE or source_id == DOOR_SOURCE:
				continue

			# Check if this wall is surrounded by floor on opposite sides
			var north = get_cell_source_id(0, Vector2i(cell.x, cell.y - 1))
			var south = get_cell_source_id(0, Vector2i(cell.x, cell.y + 1))
			var east = get_cell_source_id(0, Vector2i(cell.x + 1, cell.y))
			var west = get_cell_source_id(0, Vector2i(cell.x - 1, cell.y))

			var is_floor_or_empty = func(id): return id == FLOOR_SOURCE or id == -1

			# Vertical single-tile wall: floor/empty on both left and right
			if is_floor_or_empty.call(west) and is_floor_or_empty.call(east):
				set_cell(0, cell, FLOOR_SOURCE, ATLAS_COORDS)
				changed = true
			# Horizontal single-tile wall: floor/empty on both top and bottom
			elif is_floor_or_empty.call(north) and is_floor_or_empty.call(south):
				set_cell(0, cell, FLOOR_SOURCE, ATLAS_COORDS)
				changed = true

func texture_walls():
	# Apply appropriate textures to all walls based on floor adjacency
	var used_cells = get_used_cells(0)
	for cell in used_cells:
		var source_id = get_cell_source_id(0, cell)
		# Only texture wall tiles
		if source_id != FLOOR_SOURCE and source_id != STAIRS_SOURCE and source_id != DOOR_SOURCE:
			var wall_type = get_wall_type_for_position(cell)
			set_cell(0, cell, wall_type, ATLAS_COORDS)

func get_wall_type_for_position(pos: Vector2i) -> int:
	# Check which directions have floor tiles
	var north_floor = get_cell_source_id(0, Vector2i(pos.x, pos.y + 1)) == FLOOR_SOURCE
	var south_floor = get_cell_source_id(0, Vector2i(pos.x, pos.y - 1)) == FLOOR_SOURCE
	var east_floor = get_cell_source_id(0, Vector2i(pos.x + 1, pos.y)) == FLOOR_SOURCE
	var west_floor = get_cell_source_id(0, Vector2i(pos.x - 1, pos.y)) == FLOOR_SOURCE

	# count of adjacent floor tiles
	var adjacent_floors = int(north_floor) + int(south_floor) + int(east_floor) + int(west_floor)
	if adjacent_floors >= 3:
		return FLOOR_SOURCE

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

func place_door():
	if rooms.size() > 0:
		var last_room = rooms[-1]
		door_position = get_room_center(last_room)
		set_cell(0, door_position, DOOR_SOURCE, ATLAS_COORDS)
		print("Placed door at: ", door_position)

func spawn_enemies() -> int:
	clear_existing_enemies()

	var enemies_spawned = 0
	# Skip first room (player spawn) and last room (door)
	for i in range(1, rooms.size() - 1):
		var room = rooms[i]
		var room_area = room.size.x * room.size.y
		var num_enemies = max(1, int(room_area * enemies_per_room_area))

		print("Room ", i, " (", room.size.x, "x", room.size.y, ", area: ", room_area, "): spawning ", num_enemies, " enemies")

		for j in range(num_enemies):
			var enemy_instance = ENEMY_SCENE.instantiate()
			var spawn_pos = get_random_position_in_room(room)
			enemy_instance.global_position = map_to_local(spawn_pos)
			enemy_instance.tree_exited.connect(_on_enemy_died)
			get_parent().add_child.call_deferred(enemy_instance)
			enemies_spawned += 1

	print("Total enemies spawned: ", enemies_spawned)
	return enemies_spawned

func get_random_position_in_room(room: Rect2i) -> Vector2i:
	# Collect all floor tiles in the room
	var floor_tiles: Array[Vector2i] = []
	for x in range(room.position.x, room.position.x + room.size.x):
		for y in range(room.position.y, room.position.y + room.size.y):
			var pos = Vector2i(x, y)
			if get_cell_source_id(0, pos) == FLOOR_SOURCE:
				floor_tiles.append(pos)

	# Return random floor tile, or fallback to room center if no floor found
	if floor_tiles.size() > 0:
		return floor_tiles[randi() % floor_tiles.size()]
	else:
		return get_room_center(room)

func clear_existing_enemies():
	var enemies = get_tree().get_nodes_in_group(Groups.ENEMY)
	print("Clearing ", enemies.size(), " enemies")
	for enemy in enemies:
		enemy.queue_free()

func spawn_chest_and_emit_signal():
	spawn_chest()

	# Emit signal after chest is spawned
	var stairs_pos = Vector2i.ZERO
	if rooms.size() > 0:
		stairs_pos = get_room_center(rooms[-1])

	print("Emitting dungeon_generated signal with chest_position: ", chest_position)
	dungeon_generated.emit(rooms, stairs_pos, room_connections, chest_position)

func spawn_chest():
	clear_existing_chests()

	# Skip first room (player spawn) and last room (stairs)
	# Randomly pick one room from the middle rooms to spawn a chest
	if rooms.size() > 2:
		var available_rooms = range(1, rooms.size() - 1) # Exclude first and last
		var chest_room_index = available_rooms[randi() % available_rooms.size()]
		var chest_room = rooms[chest_room_index]

		# Find a good position in the room (not center, but not edge)
		var spawn_pos = get_random_position_in_room(chest_room)
		chest_position = spawn_pos

		print("Attempting to spawn chest at tile position: ", spawn_pos)

		if CHEST_SCENE == null:
			print("ERROR: CHEST_SCENE is null!")
			return

		var chest_instance = CHEST_SCENE.instantiate()
		if chest_instance == null:
			print("ERROR: Failed to instantiate chest!")
			return

		var world_pos = map_to_local(spawn_pos)
		print("World position calculated: ", world_pos)

		chest_instance.position = world_pos # Use position instead of global_position
		chest_instance.name = "GeneratedChest"

		var parent = get_parent()
		if parent == null:
			print("ERROR: No parent found!")
			return

		parent.add_child(chest_instance)
		print("Successfully spawned chest in room ", chest_room_index, " at tile position: ", spawn_pos)
		print("Chest added to parent: ", parent.name)

		# Verify the chest was added
		await get_tree().process_frame
		var found_chest = parent.get_node_or_null("GeneratedChest")
		if found_chest:
			print("Chest verified in scene tree at position: ", found_chest.position)
		else:
			print("ERROR: Chest not found in scene tree after adding!")
	else:
		print("Not enough rooms to spawn a chest")
		chest_position = Vector2i.ZERO # Set to zero if no chest spawned

func clear_existing_chests():
	var chests = get_tree().get_nodes_in_group("interactables")
	print("Clearing existing chests. Found ", chests.size(), " interactables")
	for chest in chests:
		print("Checking interactable: ", chest.name, ", script: ", chest.get_script())
		if chest.get_script() and chest.get_script().get_global_name() == "TreasureChest":
			print("Removing chest: ", chest.name)
			chest.queue_free()

func regenerate():
	generate_dungeon()
	get_tree().call_group(Groups.PLAYER, "reset_position")

func _on_enemy_died():
	if door_open or not is_inside_tree():
		return

	var enemies_alive = get_tree().get_nodes_in_group(Groups.ENEMY).size()
	var enemies_killed = total_enemies - enemies_alive
	var kill_percentage = float(enemies_killed) / float(total_enemies) if total_enemies > 0 else 0.0

	print("Enemies killed: ", enemies_killed, "/", total_enemies, " (", int(kill_percentage * 100), "%)")

	if kill_percentage >= 0.30:
		open_door()

func open_door():
	if door_open:
		return

	door_open = true
	# Replace door with stairs
	set_cell(0, door_position, STAIRS_SOURCE, ATLAS_COORDS)
	print("Door opened! Stairs revealed at: ", door_position)
	door_opened.emit()

func is_door_position(pos: Vector2i) -> bool:
	return pos == door_position and not door_open

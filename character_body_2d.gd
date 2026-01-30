extends CharacterBody2D


const SPEED = 300.0
const STAIRS_SOURCE = 2

func _ready():
	add_to_group("player")
	reset_position()

func reset_position():
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("get_spawn_position"):
		position = tilemap.get_spawn_position()

func _physics_process(delta: float) -> void:
	# 1. Get input for both horizontal (x) and vertical (y) axes
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Apply movement
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		# 3. Smoothly stop when no keys are pressed
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
	
	check_stairs()

func check_stairs():
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap:
		var tile_pos = tilemap.local_to_map(position)
		var tile_source = tilemap.get_cell_source_id(0, tile_pos)
		
		if tile_source == STAIRS_SOURCE:
			descend_to_next_level()

func descend_to_next_level():
	var tilemap = get_parent().get_node_or_null("TileMap")
	if tilemap and tilemap.has_method("regenerate"):
		tilemap.regenerate()

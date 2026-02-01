extends CanvasLayer

@onready var previous_mask_slot = $CarouselContainer/PreviousMask
@onready var current_mask_slot = $CarouselContainer/CurrentMask
@onready var next_mask_slot = $CarouselContainer/NextMask

var mask_textures = []
var current_mask_index = 0
var available_mask_indices: Array[int] = []

func _ready():
	mask_textures = [
		load("res://assets/mask_1.png"),
		load("res://assets/mask_2.png"),
		load("res://assets/mask_3.png")
	]
	while mask_textures.size() <= Masks.Type.BOSS:
		mask_textures.append(null)
	_rebuild_available_masks()

	_update_carousel_display()


func update_display(mask_type: Masks.Type):
	if available_mask_indices.is_empty():
		return
	current_mask_index = mask_type as int
	if current_mask_index not in available_mask_indices:
		current_mask_index = available_mask_indices[0]
	_update_carousel_display()

func _update_carousel_display():
	if available_mask_indices.is_empty():
		return

	# Calculate indices for previous and next masks (wrap around)
	var current_pos = available_mask_indices.find(current_mask_index)
	if current_pos == -1:
		current_pos = 0
		current_mask_index = available_mask_indices[0]
	var previous_pos = (current_pos - 1 + available_mask_indices.size()) % available_mask_indices.size()
	var next_pos = (current_pos + 1) % available_mask_indices.size()
	var previous_index = available_mask_indices[previous_pos]
	var next_index = available_mask_indices[next_pos]

	# Update textures
	current_mask_slot.texture = mask_textures[current_mask_index]
	previous_mask_slot.texture = mask_textures[previous_index]
	next_mask_slot.texture = mask_textures[next_index]

func add_mask_texture(mask_type: Masks.Type, texture: Texture2D) -> void:
	var idx = mask_type as int
	while mask_textures.size() <= idx:
		mask_textures.append(null)
	mask_textures[idx] = texture
	_rebuild_available_masks()
	_update_carousel_display()

func _rebuild_available_masks() -> void:
	available_mask_indices.clear()
	for i in range(mask_textures.size()):
		if mask_textures[i] != null:
			available_mask_indices.append(i)


func get_current_mask_index() -> int:
	return current_mask_index

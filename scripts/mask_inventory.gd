extends CanvasLayer

@onready var previous_mask_slot = $CarouselContainer/PreviousMask
@onready var current_mask_slot = $CarouselContainer/CurrentMask
@onready var next_mask_slot = $CarouselContainer/NextMask

var mask_textures = []
var current_mask_index = 0

func _ready():
	mask_textures = [
		load("res://assets/mask_1.png"),
		load("res://assets/mask_2.png"),
		load("res://assets/mask_3.png")
	]

	_update_carousel_display()


func update_display(mask_type: Masks.Type):
	if mask_textures.size() == 0:
		return

	current_mask_index = mask_type as int
	_update_carousel_display()

func _update_carousel_display():
	if mask_textures.size() == 0:
		return

	# Calculate indices for previous and next masks (wrap around)
	var previous_index = (current_mask_index - 1 + mask_textures.size()) % mask_textures.size()
	var next_index = (current_mask_index + 1) % mask_textures.size()

	# Update textures
	current_mask_slot.texture = mask_textures[current_mask_index]
	previous_mask_slot.texture = mask_textures[previous_index]
	next_mask_slot.texture = mask_textures[next_index]


func get_current_mask_index() -> int:
	return current_mask_index

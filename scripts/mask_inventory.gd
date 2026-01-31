extends CanvasLayer

@onready var previous_mask_slot = $CarouselContainer/PreviousMask
@onready var current_mask_slot = $CarouselContainer/CurrentMask
@onready var next_mask_slot = $CarouselContainer/NextMask

# Define all available mask textures
var mask_textures = []
var current_mask_index = 0

signal mask_changed(mask_index: int)

func _ready():
	# Load mask textures
	mask_textures = [
		load("res://assets/mask_1.png"),
		load("res://assets/mask_2.png"),
		load("res://assets/mask_3.png")
	]
	
	_update_carousel_display()


func _input(event):
	if event.is_action_pressed("cycle_mask"):
		cycle_to_next_mask()


func cycle_to_next_mask():
	if mask_textures.size() == 0:
		return
	
	current_mask_index = (current_mask_index + 1) % mask_textures.size()
	_update_carousel_display()
	mask_changed.emit(current_mask_index)
	
	print("Switched to mask: ", current_mask_index)


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

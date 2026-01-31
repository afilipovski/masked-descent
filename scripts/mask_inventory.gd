extends CanvasLayer

@onready var previous_mask_slot = $CarouselContainer/PreviousMask
@onready var current_mask_slot = $CarouselContainer/CurrentMask
@onready var next_mask_slot = $CarouselContainer/NextMask

# Define all available mask colors
var mask_colors = [
	Color(1, 0, 0, 1),      # Red
	Color(0, 1, 0, 1),      # Green
	Color(0, 0, 1, 1),      # Blue
	Color(1, 1, 0, 1),      # Yellow
	Color(1, 0, 1, 1),      # Magenta
	Color(0, 1, 1, 1),      # Cyan
	Color(1, 0.5, 0, 1),    # Orange
	Color(0.5, 0, 1, 1)     # Purple
]

var current_mask_index = 0

signal mask_changed(mask_index: int)

func _ready():
	_update_carousel_display()


func _input(event):
	if event.is_action_pressed("cycle_mask"):
		cycle_to_next_mask()


func cycle_to_next_mask():
	if mask_colors.size() == 0:
		return
	
	current_mask_index = (current_mask_index + 1) % mask_colors.size()
	_update_carousel_display()
	mask_changed.emit(current_mask_index)
	
	print("Switched to mask: ", current_mask_index)


func _update_carousel_display():
	if mask_colors.size() == 0:
		return
	
	# Calculate indices for previous and next masks (wrap around)
	var previous_index = (current_mask_index - 1 + mask_colors.size()) % mask_colors.size()
	var next_index = (current_mask_index + 1) % mask_colors.size()
	
	# Update colors
	current_mask_slot.color = mask_colors[current_mask_index]
	previous_mask_slot.color = mask_colors[previous_index]
	next_mask_slot.color = mask_colors[next_index]


func get_current_mask_index() -> int:
	return current_mask_index

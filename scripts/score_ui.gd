extends Label

@onready var floating_score_label: Label = $FloatingScore

var current_displayed_score: int = 0
var target_score: int = 0
var counting_tween: Tween = null

# Animation settings
const COUNT_DURATION = 0.4
const PULSE_SCALE = 1.2
const PULSE_DURATION = 0.3
const FLASH_COLOR = Color(1, 1, 0, 1) # Yellow flash
const ORIGINAL_COLOR = Color(1, 0, 0, 1) # Red
const FLOAT_DISTANCE = 40.0
const FLOAT_DURATION = 1.0

func _ready() -> void:
	current_displayed_score = GameState.score
	update_score_display(GameState.score)
	GameState.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int, points_added: int) -> void:
	if points_added > 0:
		spawn_floating_score(points_added)
		animate_score_increase(new_score)
	else:
		# If no points added (e.g., reset), just update instantly
		current_displayed_score = new_score
		update_score_display(new_score)

func update_score_display(score_value: int) -> void:
	text = "Score: %d" % score_value

func animate_score_increase(new_score: int) -> void:
	# Cancel any existing counting animation
	if counting_tween and counting_tween.is_valid():
		counting_tween.kill()

	target_score = new_score

	# Create tween for counting animation
	counting_tween = create_tween()
	counting_tween.set_parallel(false)

	# Count up from current to new score
	counting_tween.tween_method(
		func(value: float):
			current_displayed_score = int(value)
			update_score_display(current_displayed_score),
		float(current_displayed_score),
		float(target_score),
		COUNT_DURATION
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# Pulse scale effect (parallel with counting)
	var pulse_tween = create_tween()
	pulse_tween.set_parallel(false)
	pulse_tween.tween_property(self , "scale", Vector2(PULSE_SCALE, PULSE_SCALE), PULSE_DURATION * 0.5)
	pulse_tween.tween_property(self , "scale", Vector2.ONE, PULSE_DURATION * 0.5)

	# Color flash effect
	var color_tween = create_tween()
	color_tween.set_parallel(false)
	color_tween.tween_property(self , "modulate", FLASH_COLOR, PULSE_DURATION * 0.3)
	color_tween.tween_property(self , "modulate", ORIGINAL_COLOR, PULSE_DURATION * 0.7)

func spawn_floating_score(points: int) -> void:
	if not floating_score_label:
		return

	# Set the text to show the points gained
	floating_score_label.text = "+%d" % points
	floating_score_label.modulate = Color(0, 1, 0, 1) # Green color
	floating_score_label.position = Vector2(0, 0)
	floating_score_label.visible = true

	# Animate the floating label
	var float_tween = create_tween()
	float_tween.set_parallel(true)
	float_tween.tween_property(floating_score_label, "position:y", -FLOAT_DISTANCE, FLOAT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(floating_score_label, "modulate:a", 0.0, FLOAT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	float_tween.finished.connect(func(): floating_score_label.visible = false)

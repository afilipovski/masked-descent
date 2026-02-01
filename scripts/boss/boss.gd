extends CharacterBody2D

@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var sprite: Sprite2D = $Sprite2D

var direction: Vector2
var player_detected: bool = false
var DEF = 0

var health = 100:
	set(value):
		health = value

		if value <= 0:
			find_child("FiniteStateMachine").change_state("Death")
		elif value <= 100 / 2 and DEF == 0:
			DEF = 5
			find_child("FiniteStateMachine").change_state("ArmorBuff")

func _ready():
	set_physics_process(false)

func _process(_delta):
	if player == null:
		return

	# Check if player is stealthed - lose detection
	if player_detected and player.has_node("CombatManager"):
		var combat_manager = player.get_node("CombatManager") as CombatManager
		if combat_manager and combat_manager.is_player_stealthed():
			player_detected = false

	direction = player.global_position - global_position

	if direction.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

func _physics_process(delta):
	if player == null:
		return

	if direction != Vector2.ZERO:
		velocity = direction.normalized() * 40
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func take_damage():
	health -= 10 - DEF

func die():
	GameState.add_score(50)
	queue_free()

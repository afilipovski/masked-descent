extends Node2D
class_name State

@onready var character: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")
@onready var animation_player: AnimationPlayer = null
@onready var pivot: Node2D = null


func _ready() -> void:
	if character:
		animation_player = character.get_node_or_null("AnimationPlayer") as AnimationPlayer
		pivot = character.get_node_or_null("Pivot") as Node2D
	set_physics_process(false)

func enter() -> void:
	set_physics_process(true)

func exit() -> void:
	set_physics_process(false)

func transition() -> void:
	pass

func _physics_process(_delta: float) -> void:
	transition()

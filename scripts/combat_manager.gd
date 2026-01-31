extends Node
class_name CombatManager

signal mask_changed(new_mask: Masks.Type)
signal attack_performed(attack_type: String)

var current_mask := Masks.Type.RANGED
var mask_list: Array[Masks.Type] = [Masks.Type.MELEE, Masks.Type.RANGED, Masks.Type.MOBILITY]
var current_mask_index: int = 1 # Start with ranged (current behavior)

var melee_combo_count: int = 0
var melee_combo_timer: float = 0.0
const MELEE_COMBO_WINDOW: float = 0.8 # Time window to continue combo

var is_stealthed: bool = false
var stealth_timer: float = 0.0
const STEALTH_DURATION: float = 1.0
const STEALTH_SPEED_MULTIPLIER: float = 1.5
const STEALTH_OPACITY: float = 0.3

func _ready() -> void:
    set_process(true)

func _process(delta: float) -> void:
    if melee_combo_timer > 0:
        melee_combo_timer -= delta
        if melee_combo_timer <= 0:
            reset_melee_combo()

    if stealth_timer > 0:
        stealth_timer -= delta
        if stealth_timer <= 0:
            end_stealth()

func cycle_mask() -> void:
    current_mask_index = (current_mask_index + 1) % mask_list.size()
    current_mask = mask_list[current_mask_index]
    reset_melee_combo()
    mask_changed.emit(current_mask)
    print("Switched to: ", Masks.get_mask_name(current_mask))

func can_perform_attack() -> bool:
    if is_stealthed:
        return false
    return Masks.can_attack(current_mask)

func perform_attack(player: Node2D, direction: Vector2) -> void:
    if not can_perform_attack():
        return

    var attack_type = Masks.get_attack_type(current_mask)

    match attack_type:
        "combo":
            perform_melee_combo(player, direction)
        "projectile":
            perform_ranged_attack(player, direction)

    attack_performed.emit(attack_type)

func perform_melee_combo(player: Node2D, direction: Vector2) -> void:
    melee_combo_count += 1
    if melee_combo_count > 3:
        melee_combo_count = 1

    melee_combo_timer = MELEE_COMBO_WINDOW
    print("Melee combo hit ", melee_combo_count, "/3")

    # This will be called by player to spawn the actual attack
    # For now, just track the combo state

func perform_ranged_attack(player: Node2D, direction: Vector2) -> void:
    # Player will handle the actual projectile spawning
    # This is just for tracking/validation
    print("Ranged attack fired")

func activate_mobility() -> void:
    if current_mask != Masks.Type.MOBILITY:
        return

    if is_stealthed:
        return

    start_stealth()

func start_stealth() -> void:
    is_stealthed = true
    stealth_timer = STEALTH_DURATION
    print("Stealth activated!")

func end_stealth() -> void:
    is_stealthed = false
    stealth_timer = 0.0
    print("Stealth ended")

func reset_melee_combo() -> void:
    melee_combo_count = 0
    melee_combo_timer = 0.0

func get_current_mask_name() -> String:
    return Masks.get_mask_name(current_mask)

func get_speed_multiplier() -> float:
    if is_stealthed:
        return STEALTH_SPEED_MULTIPLIER
    return 1.0

func get_opacity() -> float:
    if is_stealthed:
        return STEALTH_OPACITY
    return 1.0

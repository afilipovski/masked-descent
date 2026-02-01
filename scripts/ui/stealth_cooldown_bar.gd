extends ProgressBar

var combat_manager: CombatManager
var signal_connected: bool = false

func _ready():
    visible = false
    max_value = 1.0
    value = 0.0
    show_percentage = false

func _process(_delta):
    if not signal_connected:
        var player = get_parent()
        if player and player.has_node("CombatManager"):
            combat_manager = player.get_node("CombatManager") as CombatManager
            if combat_manager:
                combat_manager.stealth_deactivated.connect(_on_stealth_deactivated)
                signal_connected = true

    if not combat_manager or not visible:
        return

    if combat_manager.stealth_cooldown_timer > 0:
        value = 1.0 - (combat_manager.stealth_cooldown_timer / combat_manager.STEALTH_COOLDOWN)
    else:
        visible = false

func _on_stealth_deactivated():
    visible = true
    value = 0.0

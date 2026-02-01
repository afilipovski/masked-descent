extends Node
class_name PowerupData

enum Type {
	RANGED_DAMAGE,
	MELEE_DAMAGE,
	STEALTH_COOLDOWN
}

var type: Type
var display_name: String
var description: String
var icon_text: String  # Emoji or short text to display

func _init(p_type: Type):
	type = p_type
	match type:
		Type.RANGED_DAMAGE:
			display_name = "Power Shot"
			description = "Increases ranged damage"
			icon_text = ">"
		Type.MELEE_DAMAGE:
			display_name = "Brutal Strike"
			description = "Increases melee damage"
			icon_text = "X"
		Type.STEALTH_COOLDOWN:
			display_name = "Swift Shadows"
			description = "Faster invisibility cooldown"
			icon_text = "*"

static func get_all_powerups() -> Array[PowerupData]:
	var powerups: Array[PowerupData] = []
	powerups.append(PowerupData.new(Type.RANGED_DAMAGE))
	powerups.append(PowerupData.new(Type.MELEE_DAMAGE))
	powerups.append(PowerupData.new(Type.STEALTH_COOLDOWN))
	return powerups

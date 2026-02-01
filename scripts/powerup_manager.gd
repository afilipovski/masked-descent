extends Node
class_name PowerupManager

signal powerup_applied(powerup: PowerupData)

var ranged_damage_bonus: int = 0
var melee_damage_bonus: int = 0
var stealth_cooldown_reduction: float = 0.0

func apply_powerup(powerup: PowerupData) -> void:
	match powerup.type:
		PowerupData.Type.RANGED_DAMAGE:
			ranged_damage_bonus += 1
			print("Applied Ranged Damage powerup! Total bonus: +", ranged_damage_bonus)
		PowerupData.Type.MELEE_DAMAGE:
			melee_damage_bonus += 1
			print("Applied Melee Damage powerup! Total bonus: +", melee_damage_bonus)
		PowerupData.Type.STEALTH_COOLDOWN:
			stealth_cooldown_reduction += 0.5  # Reduce cooldown by 0.5 seconds
			print("Applied Stealth Cooldown powerup! Total reduction: -", stealth_cooldown_reduction, "s")
	
	powerup_applied.emit(powerup)

func get_ranged_damage() -> int:
	return 2 + ranged_damage_bonus  # Base damage + bonus

func get_melee_damage(combo_count: int) -> int:
	var base_damage: int
	match combo_count:
		1: base_damage = 3
		2: base_damage = 4
		3: base_damage = 6
		_: base_damage = 3
	return base_damage + melee_damage_bonus

func get_stealth_cooldown() -> float:
	return max(0.5, 3.0 - stealth_cooldown_reduction)  # Minimum 0.5s cooldown

class_name GemData
extends Resource

enum GemType {
	RUBY,
	SAPPHIRE,
	EMERALD,
	DIAMOND,
	TOPAZ,
	AMETHYST
}

@export var gem_type: GemType
@export var gem_name: String
@export var description: String
@export var icon: Texture2D
@export var rarity: int = 1 # 1=common, 2=uncommon, 3=rare, 4=epic, 5=legendary

static func create_gem(type: GemType, name: String, desc: String, rarity: int = 1) -> GemData:
	var gem = GemData.new()
	gem.gem_type = type
	gem.gem_name = name
	gem.description = desc
	gem.rarity = rarity
	return gem

static func get_random_gems(count: int = 3) -> Array[GemData]:
	var gems: Array[GemData] = []
	var available_gems = [
		create_gem(GemType.RUBY, "Ruby of Power", "Increases attack damage", 2),
		create_gem(GemType.SAPPHIRE, "Sapphire of Wisdom", "Increases mana regeneration", 2),
		create_gem(GemType.EMERALD, "Emerald of Life", "Increases maximum health", 2),
		create_gem(GemType.DIAMOND, "Diamond of Protection", "Reduces incoming damage", 3),
		create_gem(GemType.TOPAZ, "Topaz of Speed", "Increases movement speed", 2),
		create_gem(GemType.AMETHYST, "Amethyst of Focus", "Reduces spell cooldowns", 3)
	]

	available_gems.shuffle()
	for i in range(min(count, available_gems.size())):
		gems.append(available_gems[i])

	return gems


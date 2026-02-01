class_name Masks

enum Type {
    MELEE,
    RANGED,
    MOBILITY,
    BOSS
}

const MASK_DATA = {
    Type.MELEE: {
        "name": "Melee Mask",
        "can_attack": true,
        "attack_type": "combo"
    },
    Type.RANGED: {
        "name": "Ranged Mask",
        "can_attack": true,
        "attack_type": "projectile"
    },
    Type.MOBILITY: {
        "name": "Mobility Mask",
        "can_attack": false,
        "attack_type": "stealth"
    },
    Type.BOSS: {
        "name": "Boss Mask",
        "can_attack": true,
        "attack_type": "boss_laser"
    }
}

static func get_mask_name(mask_type: Type) -> String:
    return MASK_DATA[mask_type]["name"]

static func can_attack(mask_type: Type) -> bool:
    return MASK_DATA[mask_type]["can_attack"]

static func get_attack_type(mask_type: Type) -> String:
    return MASK_DATA[mask_type]["attack_type"]

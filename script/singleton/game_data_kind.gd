extends Node

var WEAPON = {
	SWORD = 0,
	AXE = 1,
	MACE = 2,
	STAFF = 3,
	BOW = 4,
	THROWN = 5,
	BOLT = 6,
	DAGGER = 7,
	POLEARM = 8
}

var STAT = {
	PRIMARY = {
		BURLY = 0,
		SAGE = 1,
		NIMBLE = 2,
		CADDISH = 3,
		STUBBORN = 4,
		SAVVY = 5
	},
	SECONDARY = {
		SPELL_POINT = 0,
		MELEE_POWER = 1,
		MAGIC_POWER = 3,
		CRITICAL = 4,
		HAYWIRE = 5,
		DODGE = 6,
		BLOCK = 7,
		COUNTER = 8,
		ACCURACY = 9, # ENEMY_DODGE_REDUCTION
		ARMOR = 10,   # ARMOR_ABSORPTION
		RESIST = 11,
		SNEAK = 12,
		LIFE_REGEN = 13,
		MANA_REGEN = 14,
		WAND_BURNOUT_REDUCTION = 15,
		TRAP_SENSE = 16, # TRAP_SENSE_LEVEL
		TRAP_SIGHT = 17, # TRAP_SIGHT_RADIUS
		SIGHT = 18 # SIGHT_RADIUS
	}
}

var _reverse_lookup = null
func find_by_id(kind, entry_id):
	if _reverse_lookup == null:
		_reverse_lookup = {
			weapon = {},
			primarybuff = {},
			secondarybuff = {}
		}
		for key in WEAPON:
			_reverse_lookup[WEAPON[key]] = key
		for key in STAT.PRIMARY:
			_reverse_lookup[STAT.PRIMARY[key]] = key
		for key in STAT.SECONDARY:
			_reverse_lookup[STAT.SECONDARY[key]] = key
	if not kind in _reverse_lookup:
		Log.warn("Unknown game data kind [" + kind + "]")
		return null
	if not entry_id in _reverse_lookup[kind]:
		Log.warn("Unknown id [" + entry_id + "] in [" + kind +"] reverse lookup")
		return null
	return _reverse_lookup[kind][entry_id]

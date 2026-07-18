# data/biomes/mole_tunnels_enemies.gd
extends Resource
class_name MoleTunnelsEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ КРОТОВЫХ НОР
## ============================================================

# data/biomes/mole_tunnels_enemies.gd

const INTENTS = {
	# Слепыш-мутант
	DataManager.EnemyId.MOLE_MUTANT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
		]
	},
	
	# Крот-силач
	DataManager.EnemyId.STRONG_MOLE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 }, { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	
	# Бешеная крыса
	DataManager.EnemyId.RABID_RAT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 6 } ],
		]
	},
	
	# Крот-гриб
	DataManager.EnemyId.MOLE_FUNGUS: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 2, "duration": 4 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.SELF, "base_value": 5 } ],
		]
	},
	
	# Многоголовый слепыш
	DataManager.EnemyId.MANY_HEADED_MOLE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 }, { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 8 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.COLD, "value": 3, "duration": 3 } ],
		]
	},
	
	# Шахтёр-гриб
	DataManager.EnemyId.FUNGAL_MINER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 3, "duration": 4 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 4, "duration": 5 } ],
		]
	},
	
	# Гора грызунов (босс)
	DataManager.EnemyId.RODENT_MOUND: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 4, "duration": 5 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.SELF, "base_value": 8 } ],
		]
	},
}

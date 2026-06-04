# data/biomes/mole_tunnels_enemies.gd
extends Resource
class_name MoleTunnelsEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ КРОТОВЫХ НОР
## ============================================================

const INTENTS = {
	# Слепыш-мутант
	DataManager.MoleEnemy.MOLE_MUTANT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# Ход 1
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 }
			],
			# Ход 2
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 },
				{ "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.REGROWTH, "passive_duration": 3 }
			],
		]
	},
	
	# Крот-силач
	DataManager.MoleEnemy.STRONG_MOLE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# Ход 1
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 },
				{ "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 }
			],
			# Ход 2
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 }
			],
			# Ход 3
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 },
				{ "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 }
			],
			# Ход 4
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 6 }
			],
		]
	},
	
	# Бешеная крыса
	DataManager.MoleEnemy.RABID_RAT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# Ход 1
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 }
			],
			# Ход 2
			[
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 6 }
			],
		]
	},
}

extends Resource
class_name RottenMarshesEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ ГНИЛОСТНЫХ ТОПЕЙ
## ============================================================

const INTENTS = {
	# Гребнистая лягушка
	DataManager.EnemyId.CRESTED_TOAD: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ALL_ALLIES, "status": DataManager.Status.STRENGTH, "value": 3, "duration": 1 }, { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
		]
	},
	DataManager.EnemyId.ROTTING_SNAIL: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.SELF, "base_value": 10 } ],
		]
	},
	DataManager.EnemyId.TOXIC_IMP: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 4 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
		]
	},
	DataManager.EnemyId.FLESH_HOUND: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 5, "duration": 1 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
		]
	},
	DataManager.EnemyId.THORNY_BLOOM: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.ALL_ALLIES, "base_value": 20 } ],
		]
	},
	DataManager.EnemyId.ROTTEN_PORTER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 2, "duration": 3 } ],
		]
	},
}

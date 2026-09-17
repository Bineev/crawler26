extends Resource
class_name RottenMarshesEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ ГНИЛОСТНЫХ ТОПЕЙ
## ============================================================

const INTENTS = {
	# Гребнистая лягушка — саппорт-бафер (урон 14/цикл, было 10, +20%)
	DataManager.EnemyId.CRESTED_TOAD: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ALL_ALLIES, "status": DataManager.Status.STRENGTH, "value": 3, "duration": 1 }, { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
		]
	},
	
	# Улитка распада — слабый танк (урон 10/цикл, было 8, +20%)
	DataManager.EnemyId.ROTTING_SNAIL: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
		]
	},
	
	# Болотный вампир — дебаффер-дамагер (урон 16/цикл, было 12, +20%)
	DataManager.EnemyId.TOXIC_IMP: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 4 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	
	# Гончая-цветок — дамагер с щитом (урон 16/цикл, было 13, +20%)
	DataManager.EnemyId.FLESH_HOUND: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
		]
	},
	
	# Шипастая поросль — сустейнер-элитка (урон 18/цикл, было 15, +20%)
	DataManager.EnemyId.THORNY_BLOOM: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 18 } ],
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.ALL_ALLIES, "base_value": 13 } ],
		]
	},
	
	# Сгнивший рабочий — универсал (урон 19/цикл, было 15, +20%)
	DataManager.EnemyId.ROTTEN_PORTER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 }, { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 3 } ],
		]
	},
	
	# Хозяин гнили — босс-сустейнер с ядом (урон 40/цикл, было 34, +20%, блок усилен)
	DataManager.EnemyId.MASTER_OF_ROT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход - Яд на 5 ходов
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 5 } ],
			
			# 2 ход - Щит 10 (было 3)
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 } ],
			
			# 3 ход - Урон 8 (было 7)
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			
			# 4 ход - Урон 12 (было 10)
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
			
			# 5 ход - Наложить на себя Rotting Shield (3 заряда)
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.ROTTING_SHIELD, "passive_duration": 3 } ],
			
			# 6 ход - Щит 12 (было 7)
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 12 } ],
			
			# 7 ход - Урон 8 (было 7)
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			
			# 8 ход - Наложить на себя Venomous Shield
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.VENOMOUS_SHIELD, "passive_duration": 0 } ],
			
			# 9 ход - Урон 12 (было 10)
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
		]
	}
}

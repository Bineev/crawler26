extends Resource
class_name RottenMarshesEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ ГНИЛОСТНЫХ ТОПЕЙ
## ============================================================

const INTENTS = {
	# Гребнистая лягушка — саппорт-бафер (урон 10/цикл)
	DataManager.EnemyId.CRESTED_TOAD: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 2 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ALL_ALLIES, "status": DataManager.Status.STRENGTH, "value": 3, "duration": 1 }, { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 2 } ],
		]
	},
	
	# Улитка распада — слабый танк (урон 8/цикл)
	DataManager.EnemyId.ROTTING_SNAIL: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
		]
	},
	
	# Болотный вампир — дебаффер-дамагер (урон 12/цикл, было 15)
	DataManager.EnemyId.TOXIC_IMP: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 4 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
		]
	},
	
	# Гончая-цветок — дамагер с щитом (урон 13/цикл, было 17)
	DataManager.EnemyId.FLESH_HOUND: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	
	# Шипастая поросль — сустейнер-элитка (урон 15/цикл, было 7)
	DataManager.EnemyId.THORNY_BLOOM: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.ALL_ALLIES, "base_value": 13 } ],
		]
	},
	
	# Сгнивший рабочий — универсал (урон 15/цикл, было 23)
	DataManager.EnemyId.ROTTEN_PORTER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 }, { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 3 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 2 }, { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 3 } ],
		]
	},
	
	# Хозяин гнили — босс-сустейнер с ядом (урон 34/цикл)
	DataManager.EnemyId.MASTER_OF_ROT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход - Яд на 5 ходов
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 5 } ],
			
			# 2 ход - Щит 3
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 3 } ],
			
			# 3 ход - Урон 7
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			
			# 4 ход - Урон 10
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			
			# 5 ход - Наложить на себя Rotting Shield (3 заряда)
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.ROTTING_SHIELD, "passive_duration": 3 } ],
			
			# 6 ход - Щит 7
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 7 } ],
			
			# 7 ход - Урон 7
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			
			# 8 ход - Наложить на себя Venomous Shield
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.VENOMOUS_SHIELD, "passive_duration": 0 } ],
			
			# 9 ход - Урон 10
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
		]
	}
}

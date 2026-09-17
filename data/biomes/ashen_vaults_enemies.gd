extends Resource
class_name AshenVaultsEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ ПЕПЕЛЬНЫХ СВОДОВ
## ============================================================

const INTENTS = {
	# Тлеющий карлик — WEAK дебаффер (урон 13/цикл, было 10, +20%)
	DataManager.EnemyId.SMOLDERING_IMP: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Урон 8
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			
			# 2 ход — Смола 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.RESIN, "value": 1, "duration": 3 } ],
			
			# 3 ход — Урон 5 + Щит 5
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 },
				{ "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 5 }
			],
			
			# 4 ход — Горение 4 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 4, "duration": 3 } ],
		]
	},
	
	# Восковой голем — WEAK танк-дебаффер (урон 8/цикл, было 6, +20%)
	DataManager.EnemyId.WAX_GOLEM: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Щит 6
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 6 } ],
			
			# 2 ход — Горение 4 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 4, "duration": 3 } ],
			
			# 3 ход — Уязвимость 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			
			# 4 ход — Урон 8
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	
	# Раскаленный старец — ELITE дамагер-дебаффер (урон 20/цикл, было 16, +20%)
	DataManager.EnemyId.MOLTEN_ELDER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Горение 3 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 3, "duration": 2 } ],
			
			# 2 ход — Урон 9
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 9 } ],
			
			# 3 ход — Горение 5 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 5, "duration": 2 } ],
			
			# 4 ход — Щит 8
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 8 } ],
			
			# 5 ход — Урон 11
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 11 } ],
		]
	},
	
	# Вестник пепла — ELITE дамагер (урон 42/цикл, было 34, +20%)
	DataManager.EnemyId.ASH_HERALD: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Уязвимость 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 3 } ],
			
			# 2 ход — Урон 5
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			
			# 3 ход — Урон 9
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 9 } ],
			
			# 4 ход — Урон 10
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			
			# 5 ход — Щит 10
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 } ],
			
			# 6 ход — Урон 18
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 18 } ],
		]
	},
	
	# Аколит сажи — NORMAL саппорт (урон 18/цикл, было 14, +20%)
	DataManager.EnemyId.SOOT_ACOLYTE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Урон 9
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 9 } ],
			
			# 2 ход — Надлом 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.FRACTURE, "value": 1, "duration": 3 } ],
			
			# 3 ход — Урон 9
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 9 } ],
			
			# 4 ход — Смола 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.RESIN, "value": 1, "duration": 2 } ],
			
			# 5 ход — Горение 5 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 5, "duration": 3 } ],
			
			# 6 ход — Лечение всех союзников на 8
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.ALL_ALLIES, "base_value": 8 } ],
		]
	},
	
	# Гротеск боли — NORMAL танк-дамагер (урон 30/цикл, было 24, +20%)
	DataManager.EnemyId.GROTESQUE_PAIN: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Урон 8 + Щит 10
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 },
				{ "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 }
			],
			
			# 2 ход — Слабость 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			
			# 3 ход — Урон 10 + Кровотечение 2 на 2 хода
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 }
			],
			
			# 4 ход — Щит 12
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 12 } ],
			
			# 5 ход — Урон 12
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
		]
	},
	
	# Аббат Пекла — BOSS дебаффер (урон 39/цикл, было 32, +20%)
	DataManager.EnemyId.HELLFIRE_ABBOT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Смола 1 на 4 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.RESIN, "value": 1, "duration": 4 } ],
			
			# 2 ход — Горение 4 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 4, "duration": 3 } ],
			
			# 3 ход — Горючесть 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.COMBUSTIBLE, "value": 1, "duration": 3 } ],
			
			# 4 ход — Щит 20
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 20 } ],
			
			# 5 ход — Горение 4 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 4, "duration": 3 } ],
			
			# 6 ход — Regrowth на себя
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.REGROWTH, "passive_duration": 0 } ],
			
			# 7 ход — Урон 15
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			
			# 8 ход — Урон 24
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 24 } ],
		]
	}
}

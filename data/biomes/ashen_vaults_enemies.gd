extends Resource
class_name AshenVaultsEnemies

const INTENTS = {
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
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 5, "duration": 1 }
			],
			
			# 4 ход — Горение 5 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 5, "duration": 3 } ],
		]
	},
	DataManager.EnemyId.WAX_GOLEM: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Щит 10
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 } ],
			
			# 2 ход — Горение 10 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 10, "duration": 3 } ],
			
			# 3 ход — Уязвимость 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			
			# 4 ход — Урон 8
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	DataManager.EnemyId.MOLTEN_ELDER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Горючесть 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.COMBUSTIBLE, "value": 1, "duration": 3 } ],
			
			# 2 ход — Урон 8
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			
			# 3 ход — Горение 8 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 8, "duration": 3 } ],
			
			# 4 ход — Щит 8
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 8, "duration": 1 } ],
			
			# 5 ход — Урон 12
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
		]
	},
	DataManager.EnemyId.ASH_HERALD: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Уязвимость 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 3 } ],
			
			# 2 ход — Урон 5
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			
			# 3 ход — Урон 10
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 } ],
			
			# 4 ход — Урон 15
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			
			# 5 ход — Щит 10
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 } ],
			
			# 6 ход — Урон 30
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 30 } ],
		]
	},
	DataManager.EnemyId.SOOT_ACOLYTE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Урон 7
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			
			# 2 ход — Надлом 1 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.FRACTURE, "value": 1, "duration": 3 } ],
			
			# 3 ход — Урон 7
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			
			# 4 ход — Смола 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.RESIN, "value": 1, "duration": 2 } ],
			
			# 5 ход — Горение 5 на 3 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BURN, "value": 5, "duration": 3 } ],
			
			# 6 ход — Лечение всех союзников на 15
			[ { "category": DataManager.EffectCategory.HEAL, "target": DataManager.EffectTarget.ALL_ALLIES, "base_value": 15 } ],
		]
	},
	DataManager.EnemyId.GROTESQUE_PAIN: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1 ход — Урон 6 + Щит 10
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 10, "duration": 1 }
			],
			
			# 2 ход — Слабость 1 на 2 хода
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			
			# 3 ход — Урон 10 + Кровотечение 2 на 2 хода
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 10 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 }
			],
			
			# 4 ход — Щит 12
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.SHIELD, "value": 12, "duration": 1 } ],
			
			# 5 ход — Урон 12
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
		]
	}
}

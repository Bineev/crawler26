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
}
}

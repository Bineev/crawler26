# data/biomes/mole_tunnels_enemies.gd
extends Resource
class_name MoleTunnelsEnemies

## ============================================================
## НАМЕРЕНИЯ ВРАГОВ КРОТОВЫХ НОР
## ============================================================

const INTENTS = {
	# Слепыш-мутант (урон 3–7)
	DataManager.EnemyId.MOLE_MUTANT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Атака малая
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 3 } ],
			
			# 2. Наложить уязвимость
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			
			# 3. Атака побольше
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 7 } ],
			
			# 4. Щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 5 } ],
		]
	},
	
	# Крот-силач (урон 5–9)
	DataManager.EnemyId.STRONG_MOLE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Наложить кровоток (1 на 2)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 2 } ],
			
			# 2. Щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 8 } ],
			
			# 3. Урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 5 } ],
			
			# 4. Урон побольше
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 9 } ],
			
			# 5. Наложить на себя реген (3 на 3)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.REGEN, "value": 3, "duration": 3 } ],
		]
	},
	
	# Бешеная крыса (урон 4–8)
	DataManager.EnemyId.RABID_RAT: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 } ],
			
			# 2. Урон и яд (1 на 2)
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 4 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.POISON, "value": 1, "duration": 2 }
			],
			
			# 3. Наложить уязвимость
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
			
			# 4. Блид (1 на 2)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 2 } ],
		]
	},
	
	# Крот-гриб (урон 4–8)
	DataManager.EnemyId.MOLE_FUNGUS: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 6 } ],
			
			# 2. Блид 2 на 2
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 2, "duration": 2 } ],
			
			# 3. Слабость 1 на 2
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.WEAKNESS, "value": 1, "duration": 2 } ],
			
			# 4. Урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
		]
	},
	
	# Многоголовый слепыш (урон 6–11)
	DataManager.EnemyId.MANY_HEADED_MOLE: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Наложить холод (5 на 3)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.COLD, "value": 5, "duration": 3 } ],
			
			# 2. Урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 6 } ],
			
			# 3. Реген (5 на 3)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.REGEN, "value": 5, "duration": 3 } ],
			
			# 4. Урон выше
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 11 } ],
			
			# 5. Щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 8 } ],
		]
	},
	
	# Шахтёр-гриб (урон 8–12)
	DataManager.EnemyId.FUNGAL_MINER: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Урон + блид (1 на 3)
			[ 
				{ "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 },
				{ "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.BLEED, "value": 1, "duration": 3 }
			],
			
			# 2. Пассивка на себя (Blooddrinker)
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.BLOODDRINKER, "passive_duration": 0 } ],
			
			# 3. Урон сильнее
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
			
			# 4. Щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 10 } ],
			
			# 5. Наложить Холод (15 на 2)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.COLD, "value": 15, "duration": 2 } ],
		]
	},
	
	# Гора грызунов (босс) (урон 5–15)
	DataManager.EnemyId.RODENT_MOUND: {
		"cycle_type": DataManager.IntentCycleType.SEQUENTIAL,
		"intents": [
			# 1. Сильный урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 15 } ],
			
			# 2. Наложить на себя щит
			[ { "category": DataManager.EffectCategory.BLOCK, "target": DataManager.EffectTarget.SELF, "base_value": 12 } ],
			
			# 3. Наложить на себя реген (5 на 3)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.SELF, "status": DataManager.Status.REGEN, "value": 5, "duration": 3 } ],
			
			# 4. Наложить на себя пассивку Fatum
			[ { "category": DataManager.EffectCategory.APPLY_PASSIVE, "target": DataManager.EffectTarget.SELF, "passive": DataManager.Passive.FATUM, "passive_duration": 0 } ],
			
			# 5. Урон
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 8 } ],
			
			# 6. Урон сильнее
			[ { "category": DataManager.EffectCategory.DAMAGE, "target": DataManager.EffectTarget.ENEMY, "base_value": 12 } ],
			
			# 7. Уязвимость (1 на 2)
			[ { "category": DataManager.EffectCategory.APPLY_STATUS, "target": DataManager.EffectTarget.ENEMY, "status": DataManager.Status.VULNERABILITY, "value": 1, "duration": 2 } ],
		]
	},
}

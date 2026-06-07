# scripts/room/enemy_selector.gd
extends Node

## ============================================================
## ПОДБОР ВРАГОВ
## ============================================================

static func select_enemies(combat_type: DataManager.CombatType, biome: DataManager.Biome, floor_level: int, progress_on_floor: int = 0) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	var difficulty_factor = _calculate_difficulty_factor(progress_on_floor)
	
	match combat_type:
		DataManager.CombatType.NORMAL:
			enemies = _select_normal_enemies(biome, floor_level, difficulty_factor)
		DataManager.CombatType.ELITE:
			enemies = _select_elite_enemies(biome, floor_level, difficulty_factor)
		DataManager.CombatType.BOSS:
			enemies = _select_boss_enemies(biome, floor_level)
		DataManager.CombatType.LIMITED_TURNS:
			enemies = _select_limited_enemies(biome, floor_level, difficulty_factor)
	
	return enemies


static func _calculate_difficulty_factor(progress_on_floor: int) -> float:
	return clamp(progress_on_floor / DataManager.DIFFICULTY_MAX_PROGRESS, 0.0, 1.0)


static func _select_normal_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	if biome == DataManager.Biome.MOLE_TUNNELS:
		var weak_enemies = [
			DataManager.MoleEnemy.MOLE_MUTANT,
			DataManager.MoleEnemy.RABID_RAT,
		]
		var normal_enemies = [
			DataManager.MoleEnemy.STRONG_MOLE,
			DataManager.MoleEnemy.MOLE_FUNGUS,
		]
		
		if difficulty < DataManager.NORMAL_DIFFICULTY_EARLY:
			var count = DataManager.NORMAL_ENEMY_COUNT_EARLY
			for i in range(count):
				var enemy_id = weak_enemies[randi() % weak_enemies.size()]
				enemies.append(DataManager.get_enemy_resource(enemy_id))
		
		elif difficulty < DataManager.NORMAL_DIFFICULTY_MID:
			enemies.append(DataManager.get_enemy_resource(weak_enemies[0]))
			enemies.append(DataManager.get_enemy_resource(normal_enemies[0]))
		
		elif difficulty < DataManager.NORMAL_DIFFICULTY_LATE:
			for i in range(DataManager.NORMAL_ENEMY_COUNT_MID):
				var normal_id = normal_enemies[randi() % normal_enemies.size()]
				enemies.append(DataManager.get_enemy_resource(normal_id))
		
		else:
			enemies.append(DataManager.get_enemy_resource(normal_enemies[0]))
			enemies.append(DataManager.get_enemy_resource(normal_enemies[1]))
			enemies.append(DataManager.get_enemy_resource(weak_enemies[0]))
	
	return enemies


static func _select_elite_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	if biome == DataManager.Biome.MOLE_TUNNELS:
		var elite_enemies = [
			DataManager.MoleEnemy.MOLE_FUNGUS,
			DataManager.MoleEnemy.MANY_HEADED_MOLE,
		]
		
		if floor_level >= DataManager.ELITE_MINER_APPEARS_FROM_FLOOR:
			elite_enemies.append(DataManager.MoleEnemy.FUNGAL_MINER)
		
		if difficulty < DataManager.ELITE_DIFFICULTY_EARLY:
			var elite_id = elite_enemies[randi() % elite_enemies.size()]
			enemies.append(DataManager.get_enemy_resource(elite_id))
		
		elif difficulty < DataManager.ELITE_DIFFICULTY_LATE:
			var elite_id = elite_enemies[randi() % elite_enemies.size()]
			enemies.append(DataManager.get_enemy_resource(elite_id))
			enemies.append(DataManager.get_enemy_resource(DataManager.MoleEnemy.MOLE_MUTANT))
		
		else:
			for i in range(DataManager.ELITE_ENEMY_COUNT_LATE):
				var elite_id = elite_enemies[randi() % elite_enemies.size()]
				enemies.append(DataManager.get_enemy_resource(elite_id))
	
	return enemies


static func _select_boss_enemies(biome: DataManager.Biome, floor_level: int) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	if biome == DataManager.Biome.MOLE_TUNNELS:
		enemies.append(DataManager.get_enemy_resource(DataManager.MoleEnemy.RODENT_MOUND))
		
		if floor_level >= DataManager.BOSS_ADD_MINIONS_FROM_FLOOR:
			enemies.append(DataManager.get_enemy_resource(DataManager.MoleEnemy.MOLE_MUTANT))
	
	return enemies


static func _select_limited_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies = _select_normal_enemies(biome, floor_level, difficulty)
	
	if enemies.size() > 1:
		enemies = enemies.slice(0, 1)
	
	return enemies

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
		DataManager.CombatType.ELITE_AFTER_ROB:
			enemies = _select_elite_enemies_after_rob(biome, floor_level, difficulty_factor)
	
	return enemies


static func _calculate_difficulty_factor(progress_on_floor: int) -> float:
	print(progress_on_floor / float(DataManager.DIFFICULTY_MAX_PROGRESS))
	return clamp(progress_on_floor / float(DataManager.DIFFICULTY_MAX_PROGRESS), 0.0, 1.0)


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
		var elite_enemies = [
			DataManager.MoleEnemy.MANY_HEADED_MOLE,
			DataManager.MoleEnemy.FUNGAL_MINER,
		]
		
		# Количество врагов: от 1 до 3 в зависимости от difficulty
		var count = 1
		if difficulty >= 0.15:
			count = 2
		if difficulty >= 0.40:
			count = 3
		
		# Выбор состава в зависимости от difficulty
		var composition = []
		
		if count == 1:
			# 1 враг
			if difficulty <= 0.1:
				composition = [weak_enemies[randi() % weak_enemies.size()]]
			elif difficulty <= 0.2:
				composition = [normal_enemies[randi() % normal_enemies.size()]]
			else:
				if randf() < 0.5:
					composition = [normal_enemies[randi() % normal_enemies.size()]]
				else:
					composition = [elite_enemies[randi() % elite_enemies.size()]]
		
		elif count == 2:
			# 2 врага
			if difficulty <= 0.25:
				# 2 слабых
				composition = [
					weak_enemies[randi() % weak_enemies.size()],
					weak_enemies[randi() % weak_enemies.size()]
				]
			elif difficulty <= 0.35:
				# 1 слабый + 1 обычный
				composition = [
					weak_enemies[randi() % weak_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
			elif difficulty <= 0.50:
				# 2 обычных
				composition = [
					normal_enemies[randi() % normal_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
			else:
				# 1 обычный + 1 элитный
				composition = [
					normal_enemies[randi() % normal_enemies.size()],
					elite_enemies[randi() % elite_enemies.size()]
				]
		
		elif count == 3:
			# 3 врага
			if difficulty <= 0.50:
				# 2 слабых + 1 обычный
				composition = [
					weak_enemies[randi() % weak_enemies.size()],
					weak_enemies[randi() % weak_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
			elif difficulty <= 0.65:
				# 1 слабый + 2 обычных
				composition = [
					weak_enemies[randi() % weak_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
			elif difficulty <= 0.80:
				# 3 обычных
				composition = [
					normal_enemies[randi() % normal_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
			else:
				# 1 элитный + 2 обычных
				composition = [
					elite_enemies[randi() % elite_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()],
					normal_enemies[randi() % normal_enemies.size()]
				]
		
		# Преобразуем состав в ресурсы врагов
		for enemy_type in composition:
			enemies.append(DataManager.get_enemy_resource(enemy_type))
	
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


static func _select_elite_enemies_after_rob(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	if biome == DataManager.Biome.MOLE_TUNNELS:
		# Пул врагов — только сильные
		var elite_pool = [
			DataManager.MoleEnemy.MANY_HEADED_MOLE,
			DataManager.MoleEnemy.FUNGAL_MINER,
		]
		
		# Добавляем STRONG_MOLE как поддержку
		var support_pool = [
			DataManager.MoleEnemy.STRONG_MOLE,
			DataManager.MoleEnemy.MOLE_FUNGUS,
		]
		
		# Количество врагов: 2-3, всегда сложный состав
		var count = 2
		if difficulty >= 0.5:
			count = 3
		
		# Первый враг — всегда элитный
		var elite_id = elite_pool[randi() % elite_pool.size()]
		enemies.append(DataManager.get_enemy_resource(elite_id))
		
		# Остальные — поддержка
		for i in range(count - 1):
			var support_id = support_pool[randi() % support_pool.size()]
			enemies.append(DataManager.get_enemy_resource(support_id))
		
		# На высоких этажах — два элитных
		if floor_level >= 4 and difficulty >= 0.7:
			var second_elite = elite_pool[randi() % elite_pool.size()]
			# Заменяем одного из поддержки на элитного
			if enemies.size() > 1:
				enemies[1] = DataManager.get_enemy_resource(second_elite)
		
		# На высоких этажах — дополнительный враг
		if floor_level >= 6 and difficulty >= 0.8:
			var extra = support_pool[randi() % support_pool.size()]
			enemies.append(DataManager.get_enemy_resource(extra))
	
	return enemies

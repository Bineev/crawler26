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
	return clamp(progress_on_floor / float(DataManager.DIFFICULTY_MAX_PROGRESS), 0.0, 1.0)


static func _select_normal_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			enemies = _select_normal_enemies_mole(biome, floor_level, difficulty)
		DataManager.Biome.ROTTEN_MARSHES:
			enemies = _select_normal_enemies_rotten(biome, floor_level, difficulty)
		DataManager.Biome.ASHEN_VAULTS:  # 🆕
			return _select_normal_enemies_ashen(biome, floor_level, difficulty)
	
	return enemies


static func _select_normal_enemies_mole(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	var weak_enemies = [
		DataManager.EnemyId.MOLE_MUTANT,
		DataManager.EnemyId.RABID_RAT,
	]
	var normal_enemies = [
		DataManager.EnemyId.STRONG_MOLE,
		DataManager.EnemyId.MOLE_FUNGUS,
	]
	var elite_enemies = [
		DataManager.EnemyId.MANY_HEADED_MOLE,
		DataManager.EnemyId.FUNGAL_MINER,
	]
	
	var count = 1
	if difficulty >= 0.15:
		count = 2
	if difficulty >= 0.40:
		count = 3
	
	var composition = []
	
	if count == 1:
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
		if difficulty <= 0.25:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()]
			]
		elif difficulty <= 0.35:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.50:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				elite_enemies[randi() % elite_enemies.size()]
			]
	
	elif count == 3:
		if difficulty <= 0.50:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.65:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.80:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				elite_enemies[randi() % elite_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
	
	for enemy_type in composition:
		enemies.append(DataManager.get_enemy_resource(enemy_type))
	
	return enemies


static func _select_normal_enemies_rotten(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	# 🆕 Слабые враги
	var weak_enemies = [
		DataManager.EnemyId.CRESTED_TOAD,
		DataManager.EnemyId.ROTTING_SNAIL,
	]
	
	# 🆕 Обычные враги
	var normal_enemies = [
		DataManager.EnemyId.TOXIC_IMP,
		DataManager.EnemyId.THORNY_BLOOM,
		DataManager.EnemyId.ROTTEN_PORTER,
	]
	
	# 🆕 Элитные враги
	var elite_enemies = [
		DataManager.EnemyId.FLESH_HOUND,
	]
	
	var count = 1
	if difficulty >= 0.15:
		count = 2
	if difficulty >= 0.40:
		count = 3
	
	var composition = []
	
	if count == 1:
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
		if difficulty <= 0.25:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()]
			]
		elif difficulty <= 0.35:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.50:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				elite_enemies[randi() % elite_enemies.size()]
			]
	
	elif count == 3:
		if difficulty <= 0.50:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.65:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.80:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				elite_enemies[randi() % elite_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
	
	for enemy_type in composition:
		enemies.append(DataManager.get_enemy_resource(enemy_type))
	
	return enemies


static func _select_normal_enemies_ashen(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	# 🆕 Слабые враги
	var weak_enemies = [
		DataManager.EnemyId.SMOLDERING_IMP,
		DataManager.EnemyId.WAX_GOLEM,  # 🆕
	]
	
	# 🆕 Обычные враги
	var normal_enemies = [

	]
	
	# 🆕 Элитные враги
	var elite_enemies = [
		DataManager.EnemyId.MOLTEN_ELDER,  # 🆕
		DataManager.EnemyId.ASH_HERALD,  # 🆕
	]
	
	var count = 1
	if difficulty >= 0.15:
		count = 2
	if difficulty >= 0.40:
		count = 3
	
	var composition = []
	
	if count == 1:
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
		if difficulty <= 0.25:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()]
			]
		elif difficulty <= 0.35:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.50:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				elite_enemies[randi() % elite_enemies.size()]
			]
	
	elif count == 3:
		if difficulty <= 0.50:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.65:
			composition = [
				weak_enemies[randi() % weak_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		elif difficulty <= 0.80:
			composition = [
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
		else:
			composition = [
				elite_enemies[randi() % elite_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()],
				normal_enemies[randi() % normal_enemies.size()]
			]
	
	for enemy_type in composition:
		enemies.append(DataManager.get_enemy_resource(enemy_type))
	
	return enemies



static func _select_elite_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return _select_elite_enemies_mole(biome, floor_level, difficulty)
		DataManager.Biome.ROTTEN_MARSHES:
			return _select_elite_enemies_rotten(biome, floor_level, difficulty)
	
	return []


static func _select_elite_enemies_mole(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	var elite_enemies = [
		DataManager.EnemyId.MOLE_FUNGUS,
		DataManager.EnemyId.MANY_HEADED_MOLE,
	]
	
	if floor_level >= DataManager.ELITE_MINER_APPEARS_FROM_FLOOR:
		elite_enemies.append(DataManager.EnemyId.FUNGAL_MINER)
	
	if difficulty < DataManager.ELITE_DIFFICULTY_EARLY:
		var elite_id = elite_enemies[randi() % elite_enemies.size()]
		enemies.append(DataManager.get_enemy_resource(elite_id))
	
	elif difficulty < DataManager.ELITE_DIFFICULTY_LATE:
		var elite_id = elite_enemies[randi() % elite_enemies.size()]
		enemies.append(DataManager.get_enemy_resource(elite_id))
		enemies.append(DataManager.get_enemy_resource(DataManager.EnemyId.MOLE_MUTANT))
	
	else:
		for i in range(DataManager.ELITE_ENEMY_COUNT_LATE):
			var elite_id = elite_enemies[randi() % elite_enemies.size()]
			enemies.append(DataManager.get_enemy_resource(elite_id))
	
	return enemies


static func _select_elite_enemies_rotten(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	# 🆕 Элитные враги Гнилостных Топей
	var elite_enemies = [
		DataManager.EnemyId.FLESH_HOUND,
		DataManager.EnemyId.THORNY_BLOOM,  # THORNY_BLOOM стал элитным
		DataManager.EnemyId.ROTTEN_PORTER,  # ROTTEN_PORTER стал элитным
	]
	
	if difficulty < DataManager.ELITE_DIFFICULTY_EARLY:
		var elite_id = elite_enemies[randi() % elite_enemies.size()]
		enemies.append(DataManager.get_enemy_resource(elite_id))
	
	elif difficulty < DataManager.ELITE_DIFFICULTY_LATE:
		var elite_id = elite_enemies[randi() % elite_enemies.size()]
		enemies.append(DataManager.get_enemy_resource(elite_id))
		enemies.append(DataManager.get_enemy_resource(DataManager.EnemyId.CRESTED_TOAD))  # слабый как поддержка
	
	else:
		for i in range(DataManager.ELITE_ENEMY_COUNT_LATE):
			var elite_id = elite_enemies[randi() % elite_enemies.size()]
			enemies.append(DataManager.get_enemy_resource(elite_id))
	
	return enemies


static func _select_boss_enemies(biome: DataManager.Biome, floor_level: int) -> Array[EnemyResource]:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return _select_boss_enemies_mole(biome, floor_level)
		DataManager.Biome.ROTTEN_MARSHES:
			return _select_boss_enemies_rotten(biome, floor_level)
	
	return []


static func _select_boss_enemies_mole(biome: DataManager.Biome, floor_level: int) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	enemies.append(DataManager.get_enemy_resource(DataManager.EnemyId.RODENT_MOUND))
	
	if floor_level >= DataManager.BOSS_ADD_MINIONS_FROM_FLOOR:
		enemies.append(DataManager.get_enemy_resource(DataManager.EnemyId.MOLE_MUTANT))
	
	return enemies


static func _select_boss_enemies_rotten(biome: DataManager.Biome, floor_level: int) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	enemies.append(DataManager.get_enemy_resource(DataManager.EnemyId.MASTER_OF_ROT))
	
	# 🆕 Миньоны для босса (начиная с 3-го этажа)
	if floor_level >= DataManager.BOSS_ADD_MINIONS_FROM_FLOOR:
		# Добавляем 1-2 миньона
		var minion_pool = [
			DataManager.EnemyId.TOXIC_IMP,
			DataManager.EnemyId.CRESTED_TOAD,
			DataManager.EnemyId.ROTTING_SNAIL,
		]
		var minion_count = 1 if floor_level < 5 else 2
		for i in range(minion_count):
			var minion_id = minion_pool[randi() % minion_pool.size()]
			enemies.append(DataManager.get_enemy_resource(minion_id))
	
	return enemies


static func _select_limited_enemies(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies = _select_normal_enemies(biome, floor_level, difficulty)
	
	if enemies.size() > 1:
		enemies = enemies.slice(0, 1)
	
	return enemies


static func _select_elite_enemies_after_rob(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return _select_elite_after_rob_mole(biome, floor_level, difficulty)
		DataManager.Biome.ROTTEN_MARSHES:
			return _select_elite_after_rob_rotten(biome, floor_level, difficulty)
	
	return []


static func _select_elite_after_rob_mole(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	var elite_pool = [
		DataManager.EnemyId.MANY_HEADED_MOLE,
		DataManager.EnemyId.FUNGAL_MINER,
	]
	
	var support_pool = [
		DataManager.EnemyId.STRONG_MOLE,
		DataManager.EnemyId.MOLE_FUNGUS,
	]
	
	var count = 2
	if difficulty >= 0.5:
		count = 3
	
	var elite_id = elite_pool[randi() % elite_pool.size()]
	enemies.append(DataManager.get_enemy_resource(elite_id))
	
	for i in range(count - 1):
		var support_id = support_pool[randi() % support_pool.size()]
		enemies.append(DataManager.get_enemy_resource(support_id))
	
	if floor_level >= 4 and difficulty >= 0.7:
		var second_elite = elite_pool[randi() % elite_pool.size()]
		if enemies.size() > 1:
			enemies[1] = DataManager.get_enemy_resource(second_elite)
	
	if floor_level >= 6 and difficulty >= 0.8:
		var extra = support_pool[randi() % support_pool.size()]
		enemies.append(DataManager.get_enemy_resource(extra))
	
	return enemies


static func _select_elite_after_rob_rotten(biome: DataManager.Biome, floor_level: int, difficulty: float) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	# 🆕 Элитный пул
	var elite_pool = [
		DataManager.EnemyId.FLESH_HOUND,
		DataManager.EnemyId.THORNY_BLOOM,
		DataManager.EnemyId.ROTTEN_PORTER,
	]
	
	# 🆕 Поддержка
	var support_pool = [
		DataManager.EnemyId.TOXIC_IMP,
		DataManager.EnemyId.CRESTED_TOAD,
		DataManager.EnemyId.ROTTING_SNAIL,
	]
	
	var count = 2
	if difficulty >= 0.5:
		count = 3
	
	var elite_id = elite_pool[randi() % elite_pool.size()]
	enemies.append(DataManager.get_enemy_resource(elite_id))
	
	for i in range(count - 1):
		var support_id = support_pool[randi() % support_pool.size()]
		enemies.append(DataManager.get_enemy_resource(support_id))
	
	if floor_level >= 4 and difficulty >= 0.7:
		var second_elite = elite_pool[randi() % elite_pool.size()]
		if enemies.size() > 1:
			enemies[1] = DataManager.get_enemy_resource(second_elite)
	
	if floor_level >= 6 and difficulty >= 0.8:
		var extra = support_pool[randi() % support_pool.size()]
		enemies.append(DataManager.get_enemy_resource(extra))
	
	return enemies

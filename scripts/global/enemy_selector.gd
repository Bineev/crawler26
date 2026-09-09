# scripts/room/enemy_selector.gd
extends Node

const SEGMENT_0_PATTERNS = [
	{ "composition": [DataManager.EnemySize.WEAK], "weight": 100 },
]

const SEGMENT_1_PATTERNS = [
	{ "composition": [DataManager.EnemySize.WEAK, DataManager.EnemySize.WEAK], "weight": 50 },
	{ "composition": [DataManager.EnemySize.NORMAL], "weight": 30 },
	{ "composition": [DataManager.EnemySize.WEAK, DataManager.EnemySize.NORMAL], "weight": 20 },
]

const SEGMENT_2_PATTERNS = [
	{ "composition": [DataManager.EnemySize.WEAK, DataManager.EnemySize.NORMAL], "weight": 50 },
	{ "composition": [DataManager.EnemySize.NORMAL, DataManager.EnemySize.WEAK, DataManager.EnemySize.WEAK], "weight": 30 },
	{ "composition": [DataManager.EnemySize.NORMAL, DataManager.EnemySize.NORMAL], "weight": 20 },
]

const SEGMENT_3_PATTERNS = [
	{ "composition": [DataManager.EnemySize.NORMAL, DataManager.EnemySize.WEAK, DataManager.EnemySize.WEAK], "weight": 50 },
	{ "composition": [DataManager.EnemySize.NORMAL, DataManager.EnemySize.NORMAL], "weight": 30 },
	{ "composition": [DataManager.EnemySize.NORMAL, DataManager.EnemySize.ELITE], "weight": 20 },
]

const SEGMENT_4_PATTERNS = [
	{ "composition": [DataManager.EnemySize.ELITE, DataManager.EnemySize.WEAK, DataManager.EnemySize.WEAK], "weight": 50 },
	{ "composition": [DataManager.EnemySize.ELITE, DataManager.EnemySize.NORMAL], "weight": 30 },
	{ "composition": [DataManager.EnemySize.ELITE, DataManager.EnemySize.ELITE], "weight": 20 },
]
## ============================================================
## ПОДБОР ВРАГОВ
## ============================================================

static func select_enemies(combat_type: DataManager.CombatType, biome: DataManager.Biome, floor_level: int, room_index: int = 0) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	match combat_type:
		DataManager.CombatType.NORMAL:
			enemies = _select_normal_enemies_generic(biome, floor_level, room_index)
		
		DataManager.CombatType.ELITE:
			# Элитный бой — сдвигаем на 1 сегмент вперёд (3 комнаты)
			var elite_room_index = room_index + 3
			enemies = _select_normal_enemies_generic(biome, floor_level, elite_room_index)
		
		DataManager.CombatType.BOSS:
			enemies = _select_boss_enemies(biome, floor_level)
		
		DataManager.CombatType.ELITE_AFTER_ROB:
			# Бой после ограбления — сдвигаем на 2 сегмента (6 комнат)
			var rob_room_index = room_index + 6
			enemies = _select_normal_enemies_generic(biome, floor_level, rob_room_index)
	
	return enemies



static func _select_boss_enemies(biome: DataManager.Biome, floor_level: int) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	var boss_id = _get_boss_for_biome(biome)
	var boss_resource = DataManager.get_enemy_resource(boss_id)
	if boss_resource:
		enemies.append(boss_resource)
	
	return enemies


static func _select_normal_enemies_generic(biome: DataManager.Biome, floor_level: int, room_index: int) -> Array[EnemyResource]:
	var enemies: Array[EnemyResource] = []
	
	var pools = _get_enemy_pools_for_biome(biome)
	var weak_pool = pools["weak"]
	var normal_pool = pools["normal"]
	var elite_pool = pools["elite"]
	
	if weak_pool.is_empty():
		return enemies
	
	# Определяем сегмент по индексу комнаты
	var rooms_per_segment = DataManager.FLOOR_ROOMS_PER_PATH  # 3
	var segment_index = floor(room_index / rooms_per_segment)
	
	# Ограничиваем сегмент (0-4)
	segment_index = clamp(segment_index, 0, 4)
	
	# Получаем паттерны для сегмента
	var patterns = _get_patterns_for_segment(segment_index)
	var composition = _select_pattern_by_weight(patterns)
	
	# Заполняем состав врагами (без повторений)
	var enemy_ids = _fill_composition(composition, weak_pool, normal_pool, elite_pool)
	
	for enemy_id in enemy_ids:
		var resource = DataManager.get_enemy_resource(enemy_id)
		if resource:
			enemies.append(resource)
	
	return enemies


static func _get_enemy_pools_for_biome(biome: DataManager.Biome) -> Dictionary:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return {
				"weak": [DataManager.EnemyId.MOLE_MUTANT, DataManager.EnemyId.RABID_RAT],
				"normal": [DataManager.EnemyId.MOLE_FUNGUS, DataManager.EnemyId.STRONG_MOLE],
				"elite": [DataManager.EnemyId.FUNGAL_MINER, DataManager.EnemyId.MANY_HEADED_MOLE],
			}
		
		DataManager.Biome.ROTTEN_MARSHES:
			return {
				"weak": [DataManager.EnemyId.ROTTING_SNAIL, DataManager.EnemyId.CRESTED_TOAD],
				"normal": [DataManager.EnemyId.FLESH_HOUND, DataManager.EnemyId.TOXIC_IMP],
				"elite": [DataManager.EnemyId.THORNY_BLOOM, DataManager.EnemyId.ROTTEN_PORTER],
			}
		
		DataManager.Biome.ASHEN_VAULTS:
			return {
				"weak": [DataManager.EnemyId.SMOLDERING_IMP, DataManager.EnemyId.WAX_GOLEM],
				"normal": [DataManager.EnemyId.GROTESQUE_PAIN, DataManager.EnemyId.SOOT_ACOLYTE],
				"elite": [DataManager.EnemyId.MOLTEN_ELDER, DataManager.EnemyId.ASH_HERALD],
			}
		
		_:
			return {"weak": [], "normal": [], "elite": []}


static func _get_boss_for_biome(biome: DataManager.Biome) -> DataManager.EnemyId:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return DataManager.EnemyId.RODENT_MOUND
		DataManager.Biome.ROTTEN_MARSHES:
			return DataManager.EnemyId.MASTER_OF_ROT
		DataManager.Biome.ASHEN_VAULTS:
			return DataManager.EnemyId.HELLFIRE_ABBOT
		_:
			return DataManager.EnemyId.RODENT_MOUND


static func _get_patterns_for_segment(segment_index: int) -> Array:
	match segment_index:
		0:
			return SEGMENT_0_PATTERNS
		1:
			return SEGMENT_1_PATTERNS
		2:
			return SEGMENT_2_PATTERNS
		3:
			return SEGMENT_3_PATTERNS
		4:
			return SEGMENT_4_PATTERNS
		_:
			return SEGMENT_1_PATTERNS


static func _select_pattern_by_weight(patterns: Array) -> Array:
	var total_weight = 0
	for p in patterns:
		total_weight += p["weight"]
	
	var roll = randi() % total_weight
	var accumulated = 0
	for p in patterns:
		accumulated += p["weight"]
		if roll < accumulated:
			return p["composition"]
	
	return patterns[0]["composition"]


static func _fill_composition(composition: Array, weak_pool: Array, normal_pool: Array, elite_pool: Array) -> Array[DataManager.EnemyId]:
	var result: Array[DataManager.EnemyId] = []
	
	# Копируем пулы для удаления использованных врагов
	var available_weak = weak_pool.duplicate()
	var available_normal = normal_pool.duplicate()
	var available_elite = elite_pool.duplicate()
	
	for enemy_size in composition:
		var selected_id: DataManager.EnemyId = -1
		
		match enemy_size:
			DataManager.EnemySize.WEAK:
				if available_weak.is_empty():
					available_weak = weak_pool.duplicate()
				selected_id = available_weak.pop_at(randi() % available_weak.size())
			
			DataManager.EnemySize.NORMAL:
				if available_normal.is_empty():
					available_normal = normal_pool.duplicate()
				selected_id = available_normal.pop_at(randi() % available_normal.size())
			
			DataManager.EnemySize.ELITE:
				if available_elite.is_empty():
					available_elite = elite_pool.duplicate()
				selected_id = available_elite.pop_at(randi() % available_elite.size())
		
		if selected_id != -1:
			result.append(selected_id)
	
	return result

# autoload/floor_manager.gd
extends Node

signal room_selected(room_node: RoomNode, should_increment_room_index: bool, enemies_ids: Array[DataManager.EnemyId])
signal floor_completed()

## ============================================================
## ДАННЫЕ ЭТАЖА
## ============================================================

var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

# Структура этажа
var all_rooms: Array[RoomNode] = []
var current_room_index: int = 0
var current_path_index: int = 0

# Временное хранение путей на развилке
var pending_paths: Array[Array] = []
var all_paths: Array = []  # [ [[path1_rooms], [path2_rooms]], [[path1_rooms], [path2_rooms]], ... ]
var current_path_progress: int = 0  # сколько комнат пройдено в текущем пути
var current_segment_index: int = 0  # текущий сегмент (развилка)
# Флаг, нужно ли генерировать босса
var boss_generated: bool = false

## Паттерны для генерации сегментов
const PATTERNS_FIRST = [
	{ "pattern": ["object", "combat", "object"], "weight": 50 },
	{ "pattern": ["elite", "object", "object"], "weight": 20 },
	{ "pattern": ["object", "elite", "object"], "weight": 30 },
]

const PATTERNS_MIDDLE = [
	{ "pattern": ["object", "combat", "combat"], "weight": 50 },
	{ "pattern": ["object", "elite", "combat"], "weight": 25 },
	{ "pattern": ["object", "elite", "elite"], "weight": 15 },
	{ "pattern": ["object", "elite", "object"], "weight": 7 },
	{ "pattern": ["object", "combat", "object"], "weight": 3 },
]

const PATTERNS_LAST = [
	{ "pattern": ["object", "combat", "bonfire"], "weight": 40 },
	{ "pattern": ["object", "elite", "bonfire"], "weight": 30 },
	{ "pattern": ["combat", "combat", "bonfire"], "weight": 20 },
	{ "pattern": ["combat", "elite", "bonfire"], "weight": 10 },
]
## ============================================================
## ТОЧКА ВХОДА
## ============================================================

func start_floor():
	print("=== FLOOR MANAGER START ===")
	reset()
	generate_floor(current_floor, current_biome)
	_load_current_room()


func reset():
	all_rooms.clear()
	all_paths.clear()
	current_room_index = 0
	current_path_index = 0
	current_path_progress = 0
	current_segment_index = 0
	# ❌ Убираем current_floor = 1
	pending_paths.clear()
	boss_generated = false
	print("FloorManager reset")


func next_room():
	print('next room: ' + str(current_room_index + 1))
	if current_room_index + 1 < all_rooms.size():
		current_room_index += 1
		_load_current_room()
	else:
		print("No more rooms, starting boss fight")
		_start_boss_fight()


## ============================================================
## ГЕНЕРАЦИЯ
## ============================================================

func generate_floor(floor_level: int, biome: DataManager.Biome):
	current_floor = floor_level
	current_biome = biome
	all_rooms.clear()
	current_room_index = 0
	pending_paths.clear()
	boss_generated = false
	
	print("Floor ", floor_level, " - Biome: ", DataManager.Biome.keys()[biome])
	
	# Комната 1: Бой
	_add_combat_room(DataManager.CombatType.NORMAL)
	print("  Room 0: COMBAT (NORMAL)")
	
	# 🆕 Генерируем все сегменты сразу
	_generate_all_segments()


func _add_combat_room(combat_type: DataManager.CombatType):
	var room = RoomNode.new()
	room.setup({
		"type": DataManager.RoomType.COMBAT,
		"combat_type": combat_type,
		"is_revealed": true
	})
	all_rooms.append(room)


func _add_branching_paths():
	var paths: Array[Array] = [[], []]
	
	for path_idx in range(DataManager.FLOOR_PATHS_COUNT):
		print("    Path ", path_idx + 1, ":")
		for room_idx in range(DataManager.FLOOR_ROOMS_PER_PATH):
			var is_revealed = (room_idx < DataManager.FLOOR_VISIBLE_ROOMS)
			var room = _generate_random_room(is_revealed)
			paths[path_idx].append(room)
			
			var visibility = "VISIBLE" if is_revealed else "HIDDEN"
			print("      Room ", room_idx, ": ", _get_room_type_string(room.room_type, room.combat_type), " (", visibility, ")")
	
	all_paths.append(paths)  # ← добавляем, а не перезаписываем


func _generate_random_room(is_revealed: bool) -> RoomNode:
	var room_node = RoomNode.new()
	
	var roll = randf()
	var room_type: DataManager.RoomType
	var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
	var object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST
	
	#if roll < 0.6:  # 60% бой
	if roll < 0.0:  # 60% бой
		room_type = DataManager.RoomType.COMBAT
		var combat_roll = randf()
		if combat_roll < 0.7:
			combat_type = DataManager.CombatType.NORMAL
		else:
			combat_type = DataManager.CombatType.ELITE
	#elif roll < 0.8:  # 20% эвент
	elif roll < 0.01:  # 20% эвент
		room_type = DataManager.RoomType.EVENT
	else:  # 20% объект
		#TODO раскомментировать после теста
		## Генерируем объектную комнату
		#room_type = DataManager.RoomType.OBJECT
		#var object_types = DataManager.ObjectType.values()
		#object_type = object_types[randi() % object_types.size()]
		#
		## 🆕 Если выпал SHOP и игрок — грабитель, заменяем на ELITE бой
		#if object_type == DataManager.ObjectType.SHOP and RunManager.is_robber:
			#room_type = DataManager.RoomType.COMBAT
			#combat_type = DataManager.CombatType.ELITE
			#object_type = DataManager.ObjectType.CHEST  # значение по умолчанию
		room_type = DataManager.RoomType.OBJECT
		object_type = DataManager.ObjectType.EVENT
	
	room_node.setup({
		"type": room_type,
		"combat_type": combat_type,
		"object_type": object_type,
		"is_revealed": is_revealed
	})
	
	return room_node


func _get_room_type_string(room_type: DataManager.RoomType, combat_type: DataManager.CombatType) -> String:
	match room_type:
		DataManager.RoomType.COMBAT:
			match combat_type:
				DataManager.CombatType.NORMAL:
					return "COMBAT (NORMAL)"
				DataManager.CombatType.ELITE:
					return "COMBAT (ELITE)"
				DataManager.CombatType.BOSS:
					return "COMBAT (BOSS)"
				_:
					return "COMBAT"
		DataManager.RoomType.EVENT:
			return "EVENT"
		DataManager.RoomType.OBJECT:
			return "OBJECT"
	return "UNKNOWN"


## ============================================================
## УПРАВЛЕНИЕ КОМНАТАМИ
## ============================================================

func select_path(path_index: int):
	print("=== select_path ===")
	print("path_index: ", path_index)
	print("current_segment_index: ", current_segment_index)
	
	if current_segment_index >= all_paths.size():
		print("No more segments!")
		return
	
	var current_paths = all_paths[current_segment_index]
	if current_paths.is_empty():
		return
	
	# Добавляем комнаты выбранного пути в all_rooms
	for room in current_paths[path_index]:
		all_rooms.append(room)
		print("  Added room: ", _get_room_type_string(room.room_type, room.combat_type))
	
	# Переходим к следующему сегменту для следующей развилки
	current_segment_index += 1
	
	# Загружаем первую комнату пути
	_load_current_room()


func _load_current_room():
	if current_path_progress >= all_rooms.size():
		# Если нет комнат — вызываем process_next
		process_next()
		return
	
	var room = all_rooms[current_path_progress]
	room.is_visited = true
	print("=== LOADING ROOM ", current_path_progress, ": ", _get_room_type_string(room.room_type, room.combat_type), " ===")
	room_selected.emit(room, true)


func _start_boss_fight():
	print("=== STARTING BOSS FIGHT ===")
	boss_generated = true
	
	var boss_room = RoomNode.new()
	boss_room.setup({
		"type": DataManager.RoomType.COMBAT,
		"combat_type": DataManager.CombatType.BOSS,
		"is_revealed": true
	})
	all_rooms.append(boss_room)
	room_selected.emit(boss_room, true)


## ============================================================
## ПОЛУЧЕНИЕ ДАННЫХ
## ============================================================

func get_available_paths() -> Array:
	if current_segment_index < all_paths.size():
		return all_paths[current_segment_index]
	return []


func get_current_room() -> RoomNode:
	if current_room_index < all_rooms.size():
		return all_rooms[current_room_index]
	return null


func get_visible_rooms_in_path(path_index: int) -> Array[RoomNode]:
	if pending_paths.is_empty():
		return []
	
	if path_index < 0 or path_index >= pending_paths.size():
		return []
	
	var result: Array[RoomNode] = []
	for i in range(DataManager.FLOOR_VISIBLE_ROOMS):
		if i < pending_paths[path_index].size():
			result.append(pending_paths[path_index][i])
	return result


func get_hidden_rooms_count_in_path(path_index: int) -> int:
	if pending_paths.is_empty():
		return 0
	
	if path_index < 0 or path_index >= pending_paths.size():
		return 0
	
	return pending_paths[path_index].size() - DataManager.FLOOR_VISIBLE_ROOMS


func is_boss_room(room_index: int) -> bool:
	if room_index >= all_rooms.size():
		return false
	var room = all_rooms[room_index]
	return room.room_type == DataManager.RoomType.COMBAT and room.combat_type == DataManager.CombatType.BOSS


func process_next():
	current_path_progress += 1
	
	if current_path_progress < all_rooms.size():
		current_room_index = current_path_progress
		_load_current_room()
		return
	
	if current_segment_index < all_paths.size():
		var available_paths = all_paths[current_segment_index]
		SignalManager.show_paths.emit(available_paths)
	else:
		# 🆕 Если босс уже был — завершаем биом
		if boss_generated:
			_on_biome_completed()
		else:
			_start_boss_fight()


func _on_biome_completed() -> void:
	print("=== BIOME COMPLETED ===")
	SignalManager.show_next_biome_choice.emit()

#func _generate_all_segments() -> void:
	#var rooms_per_path = DataManager.FLOOR_ROOMS_PER_PATH * DataManager.FLOOR_VISIBLE_ROOMS
	#var room_pool: Array[RoomNode] = []
	#
	## Добавляем бои
	#var total_battles = DataManager.CONSECUTIVE_BATTLES_COUNT * DataManager.FLOOR_SEGMENTS_BEFORE_BOSS
	#
	#for i in range(total_battles):
		#var combat_type = DataManager.CombatType.NORMAL
		#if i % 3 == 2:
			#combat_type = DataManager.CombatType.ELITE
		#if current_floor >= 3 and i % 3 == 1:
			#combat_type = DataManager.CombatType.ELITE
		#if current_floor >= 5 and i % 2 == 0:
			#combat_type = DataManager.CombatType.ELITE
		#
		#room_pool.append(_create_room_node(DataManager.RoomType.COMBAT, combat_type))
	#
	## Добавляем объекты согласно константам
	#for i in range(DataManager.SHOPS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.SHOP))
	#
	#for i in range(DataManager.EVENTS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.EVENT))
	#
	#for i in range(DataManager.CHESTS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.CHEST))
	#
	#for i in range(DataManager.TRAPS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.TRAP))
	#
	#for i in range(DataManager.BONFIRES_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.BONFIRE))
	#
	#for i in range(DataManager.IDOLS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.IDOL))
	#
	#for i in range(DataManager.TORTURE_RACK_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.TORTURE_RACK))
	#
	#for i in range(DataManager.CAULDRONS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.CAULDRON))
	#
	## Перемешиваем пул
	#room_pool.shuffle()
	#
	## Распределяем по двум путям
	#var path1: Array[RoomNode] = []
	#var path2: Array[RoomNode] = []
	#
	#for i in range(room_pool.size()):
		#if i % 2 == 0:
			#path1.append(room_pool[i])
		#else:
			#path2.append(room_pool[i])
	#
	## Дополняем пути до нужной длины
	#while path1.size() < rooms_per_path:
		#path1.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	#while path2.size() < rooms_per_path:
		#path2.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	#
	## Разбиваем на сегменты и записываем в all_paths
	#all_paths.clear()
	#for segment in range(DataManager.FLOOR_SEGMENTS_BEFORE_BOSS):
		#var start_idx = segment * DataManager.FLOOR_VISIBLE_ROOMS
		#var end_idx = start_idx + DataManager.FLOOR_VISIBLE_ROOMS
		#
		#var segment_paths: Array[Array] = [
			#path1.slice(start_idx, end_idx),
			#path2.slice(start_idx, end_idx)
		#]
		#
		#for path in segment_paths:
			#for i in range(path.size()):
				#path[i].is_revealed = (i < DataManager.FLOOR_VISIBLE_ROOMS - randi_range(0,2))
		#
		#all_paths.append(segment_paths)

## старый рабочий, но не очень правильный генератор этажа
#func _generate_all_segments() -> void:
	#var rooms_per_path = DataManager.FLOOR_ROOMS_PER_PATH * DataManager.FLOOR_VISIBLE_ROOMS
	#var room_pool: Array[RoomNode] = []
	#
	## Добавляем бои
	#var total_battles = DataManager.CONSECUTIVE_BATTLES_COUNT * DataManager.FLOOR_SEGMENTS_BEFORE_BOSS * 2  # ×2 для двух путей
	#
	#for i in range(total_battles):
		#var combat_type = DataManager.CombatType.NORMAL
		#if i % 3 == 2:
			#combat_type = DataManager.CombatType.ELITE
		#if current_floor >= 3 and i % 3 == 1:
			#combat_type = DataManager.CombatType.ELITE
		#if current_floor >= 5 and i % 2 == 0:
			#combat_type = DataManager.CombatType.ELITE
		#
		#room_pool.append(_create_room_node(DataManager.RoomType.COMBAT, combat_type))
	#
	## Добавляем объекты (для ОБОИХ путей)
	#for i in range(DataManager.SHOPS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.SHOP))
	#
	#for i in range(DataManager.EVENTS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.EVENT))
	#
	#for i in range(DataManager.CHESTS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.CHEST))
	#
	#for i in range(DataManager.TRAPS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.TRAP))
	#
	#for i in range(DataManager.BONFIRES_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.BONFIRE))
	#
	#for i in range(DataManager.IDOLS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.IDOL))
	#
	#for i in range(DataManager.TORTURE_RACK_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.TORTURE_RACK))
	#
	#for i in range(DataManager.CAULDRONS_ON_FLOOR_COUNT):
		#room_pool.append(_create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.CAULDRON))
	#
	## Перемешиваем пул
	#room_pool.shuffle()
	#
	## Распределяем по двум путям (ЧЕРЕДУЯ)
	#var path1: Array[RoomNode] = []
	#var path2: Array[RoomNode] = []
	#
	#var battle_counter1 = 0
	#var battle_counter2 = 0
	#
	#for room in room_pool:
		## Определяем, в какой путь положить комнату
		#if room.room_type == DataManager.RoomType.COMBAT:
			## Бои чередуем между путями, но не даём превысить CONSECUTIVE_BATTLES_COUNT
			#if battle_counter1 <= battle_counter2 and battle_counter1 < DataManager.CONSECUTIVE_BATTLES_COUNT:
				#path1.append(room)
				#battle_counter1 += 1
				#battle_counter2 = 0
			#elif battle_counter2 < DataManager.CONSECUTIVE_BATTLES_COUNT:
				#path2.append(room)
				#battle_counter2 += 1
				#battle_counter1 = 0
			#else:
				## Если оба пути достигли лимита — сбрасываем
				#battle_counter1 = 0
				#battle_counter2 = 0
				#path1.append(room)
				#battle_counter1 += 1
		#else:
			## Объекты — просто чередуем
			#if path1.size() <= path2.size():
				#path1.append(room)
			#else:
				#path2.append(room)
	#
	## Дополняем пути до нужной длины
	#while path1.size() < rooms_per_path:
		#path1.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	#while path2.size() < rooms_per_path:
		#path2.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	#
	## Разбиваем на сегменты и записываем в all_paths
	#all_paths.clear()
	#for segment in range(DataManager.FLOOR_SEGMENTS_BEFORE_BOSS):
		#var start_idx = segment * DataManager.FLOOR_VISIBLE_ROOMS
		#var end_idx = start_idx + DataManager.FLOOR_VISIBLE_ROOMS
		#
		#var segment_paths: Array[Array] = [
			#path1.slice(start_idx, end_idx),
			#path2.slice(start_idx, end_idx)
		#]
		#
		#for path in segment_paths:
			#for i in range(path.size()):
				#path[i].is_revealed = (i < DataManager.FLOOR_VISIBLE_ROOMS - randi_range(0, 2))
		#
		#all_paths.append(segment_paths)

func _create_room_node(room_type: DataManager.RoomType, combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL, object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST, is_revealed: bool = true) -> RoomNode:
	var room_node = RoomNode.new()
	room_node.setup({
		"type": room_type,
		"combat_type": combat_type,
		"object_type": object_type,
		"is_revealed": is_revealed
	})
	return room_node

# ============================================================
# ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
# ============================================================

## Выбирает паттерн случайно с учётом весов
func _select_pattern_by_weight(patterns: Array) -> Array:
	var total_weight = 0
	for p in patterns:
		total_weight += p["weight"]
	
	var roll = randi() % total_weight
	var accumulated = 0
	for p in patterns:
		accumulated += p["weight"]
		if roll < accumulated:
			return p["pattern"]
	
	return patterns[0]["pattern"]


## Получает паттерн для сегмента в зависимости от его позиции
func _get_pattern_for_segment(seg_idx: int, total_segments: int) -> Array:
	var is_first = (seg_idx == 0)
	var is_last = (seg_idx == total_segments - 1)
	
	if is_first:
		return _select_pattern_by_weight(PATTERNS_FIRST)
	elif is_last:
		return _select_pattern_by_weight(PATTERNS_LAST)
	else:
		return _select_pattern_by_weight(PATTERNS_MIDDLE)


## Создаёт комнату по типу из паттерна (без объекта)
func _create_room_from_pattern_type(pattern_type: String, object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST) -> RoomNode:
	match pattern_type:
		"combat":
			return _create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL)
		"elite":
			return _create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.ELITE)
		"bonfire":
			return _create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.BONFIRE)
		"object":
			return _create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, object_type)
		_:
			return _create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL)


# ============================================================
# ВЫБОР ОБЪЕКТОВ
# ============================================================

func _get_available_objects_for_segment(seg_idx: int, used_objects: Array[DataManager.ObjectType]) -> Array[DataManager.ObjectType]:
	var available: Array[DataManager.ObjectType] = []
	
	var all_objects = [
		DataManager.ObjectType.CHEST,
		DataManager.ObjectType.EVENT,
		DataManager.ObjectType.IDOL,
		DataManager.ObjectType.TRAP,
		DataManager.ObjectType.CAULDRON,
		DataManager.ObjectType.TORTURE_RACK,
	]
	
	# Магазин — только со 2-го сегмента
	if seg_idx >= 1:
		all_objects.append(DataManager.ObjectType.SHOP)
	
	# Привал — только со 2-го сегмента (кроме последнего, где он ставится отдельно)
	if seg_idx >= 1 and seg_idx < DataManager.FLOOR_SEGMENTS_BEFORE_BOSS - 1:
		all_objects.append(DataManager.ObjectType.BONFIRE)
	
	# Убираем использованные объекты
	for obj in all_objects:
		if obj not in used_objects:
			available.append(obj)
	
	return available


## Выбирает случайный объект из доступных
func _select_random_object(available: Array[DataManager.ObjectType]) -> DataManager.ObjectType:
	if available.is_empty():
		# Если все объекты использованы — возвращаем сундук как fallback
		return DataManager.ObjectType.CHEST
	
	return available[randi() % available.size()]


## Обновляет список использованных объектов
func _update_used_objects(used_objects: Array[DataManager.ObjectType], path_objects: Array[DataManager.ObjectType]) -> Array[DataManager.ObjectType]:
	var result = used_objects.duplicate()
	for obj in path_objects:
		if obj not in result:
			result.append(obj)
	return result


# ============================================================
# ГЕНЕРАЦИЯ ПУТЕЙ
# ============================================================

## Генерирует паттерны для всех сегментов
func _generate_segment_patterns(total_segments: int) -> Array:
	var segment_patterns: Array = []
	
	for seg_idx in range(total_segments):
		var pattern = _get_pattern_for_segment(seg_idx, total_segments)
		segment_patterns.append(pattern)
	
	return segment_patterns


## Создаёт путь из паттернов с выбором объектов
func _build_path_from_patterns(segment_patterns: Array, seg_idx_offset: int, used_objects: Array[DataManager.ObjectType]) -> Array[RoomNode]:
	var path: Array[RoomNode] = []
	var local_used = used_objects.duplicate()
	
	for seg_idx in range(segment_patterns.size()):
		var pattern = segment_patterns[seg_idx]
		var actual_seg_idx = seg_idx_offset + seg_idx
		var is_last_segment = (actual_seg_idx == segment_patterns.size() - 1)
		
		for pattern_type in pattern:
			if pattern_type == "object":
				# Выбираем объект
				var available = _get_available_objects_for_segment(actual_seg_idx, local_used)
				var object_type = _select_random_object(available)
				
				# Добавляем в список использованных
				if object_type not in local_used:
					local_used.append(object_type)
				
				var room = _create_room_from_pattern_type(pattern_type, object_type)
				path.append(room)
			else:
				var room = _create_room_from_pattern_type(pattern_type)
				path.append(room)
	
	return path


func _generate_two_paths(total_segments: int) -> Array:
	# 🆕 Генерируем отдельные паттерны для каждого пути
	var segment_patterns_a = _generate_segment_patterns(total_segments)
	var segment_patterns_b = _generate_segment_patterns(total_segments)
	
	# Путь А
	var used_objects_a: Array[DataManager.ObjectType] = []
	var path_a = _build_path_from_patterns(segment_patterns_a, 0, used_objects_a)
	
	# Путь Б
	var used_objects_b: Array[DataManager.ObjectType] = []
	var path_b = _build_path_from_patterns(segment_patterns_b, 0, used_objects_b)
	
	# Применяем перемешивание к каждому сегменту в обоих путях
	var rooms_per_segment = DataManager.FLOOR_ROOMS_PER_PATH
	
	for seg_idx in range(total_segments):
		var start_idx = seg_idx * rooms_per_segment
		var end_idx = start_idx + rooms_per_segment
		
		var segment_a = path_a.slice(start_idx, end_idx)
		# BUG
		var shuffled_a = _shuffle_object_in_segment(segment_a)
		for i in range(shuffled_a.size()):
			path_a[start_idx + i] = shuffled_a[i]
		
		var segment_b = path_b.slice(start_idx, end_idx)
		var shuffled_b = _shuffle_object_in_segment(segment_b)
		for i in range(shuffled_b.size()):
			path_b[start_idx + i] = shuffled_b[i]
	
	# Сегмент 2 (индекс 1) — обязательный магазин и привал в КОНЦЕ
	var seg2_start = 1 * rooms_per_segment
	var seg2_end = seg2_start + rooms_per_segment
	var last_pos_in_seg2 = seg2_end - 1
	
	# Путь А: магазин в конце
	var shop_room = _create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.SHOP)
	path_a[last_pos_in_seg2] = shop_room
	
	# Путь Б: привал в конце
	var bonfire_room = _create_room_node(DataManager.RoomType.OBJECT, DataManager.CombatType.NORMAL, DataManager.ObjectType.BONFIRE)
	path_b[last_pos_in_seg2] = bonfire_room
	
	return [path_a, path_b]


func _get_segment_types(path: Array, seg_idx: int, rooms_per_segment: int) -> Array:
	var start = seg_idx * rooms_per_segment
	var end = start + rooms_per_segment
	var types = []
	for i in range(start, end):
		if i < path.size():
			var room = path[i]
			if room.room_type == DataManager.RoomType.COMBAT:
				types.append("COMBAT" if room.combat_type == DataManager.CombatType.NORMAL else "ELITE")
			else:
				types.append("OBJECT")
	return types

# ============================================================
# ОСНОВНОЙ МЕТОД ГЕНЕРАЦИИ (ЗАМЕНЯЕТ СТАРЫЙ)
# ============================================================

func _generate_all_segments() -> void:
	var rooms_per_segment = DataManager.FLOOR_ROOMS_PER_PATH
	var total_segments = DataManager.FLOOR_SEGMENTS_BEFORE_BOSS
	var total_rooms_per_path = total_segments * rooms_per_segment
	
	# 1. Генерируем два пути
	var paths = _generate_two_paths(total_segments)
	var path1 = paths[0]
	var path2 = paths[1]
	
	# 2. Дополняем пути до нужной длины (на случай, если что-то пошло не так)
	var target_length = total_rooms_per_path
	while path1.size() < target_length:
		path1.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	while path2.size() < target_length:
		path2.append(_create_room_node(DataManager.RoomType.COMBAT, DataManager.CombatType.NORMAL))
	
	# 3. Разбиваем на сегменты и сохраняем в all_paths
	all_paths.clear()
	for seg_idx in range(total_segments):
		var start_idx = seg_idx * rooms_per_segment
		var end_idx = start_idx + rooms_per_segment
		
		var segment_paths: Array[Array] = [
			path1.slice(start_idx, end_idx),
			path2.slice(start_idx, end_idx)
		]
		
		# Устанавливаем видимость комнат
		for path in segment_paths:
			for i in range(path.size()):
				if seg_idx == 0:
					# Первый сегмент — все комнаты видны
					path[i].is_revealed = true
				else:
					# Остальные — часть скрыта
					path[i].is_revealed = (i < DataManager.FLOOR_VISIBLE_ROOMS - randi_range(0, 2))
		
		all_paths.append(segment_paths)
	
	print("=== FLOOR GENERATED ===")
	print("Total segments: ", total_segments)
	print("Path1 length: ", path1.size())
	print("Path2 length: ", path2.size())


## Перемещает объект внутри сегмента с вероятностью 50%
func _shuffle_object_in_segment(segment: Array[RoomNode]) -> Array[RoomNode]:
	var result = segment.duplicate()
	
	# Находим позиции объектов (не привалов)
	var object_positions: Array[int] = []
	for i in range(result.size()):
		if result[i].room_type == DataManager.RoomType.OBJECT:
			# Пропускаем привалы (они не перемещаются)
			if result[i].object_type != DataManager.ObjectType.BONFIRE:
				object_positions.append(i)
	
	# Если нет объекта — возвращаем как есть
	if object_positions.is_empty():
		return result
	
	# Решаем, перемещать ли объект (50%)
	if randf() >= DataManager.FLOOR_OBJECT_SHUFFLE_CHANCE:
		return result
	
	# Находим доступные позиции (не занятые объектами)
	var available_positions: Array[int] = []
	for i in range(result.size()):
		if result[i].room_type != DataManager.RoomType.OBJECT:
			available_positions.append(i)
	
	if available_positions.is_empty():
		return result
	
	# Берём первый объект и меняем его местами со случайной свободной позицией
	var obj_index = object_positions[0]
	var new_pos = available_positions[randi() % available_positions.size()]
	
	# Простой swap
	var temp = result[obj_index]
	result[obj_index] = result[new_pos]
	result[new_pos] = temp
	
	return result

# autoload/floor_manager.gd
extends Node

signal room_selected(room_node: RoomNode)
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
	
	# Генерируем сегменты до босса
	for segment in range(DataManager.FLOOR_SEGMENTS_BEFORE_BOSS):
		print("  Segment ", segment + 1, " - Adding branching paths...")
		_add_branching_paths()


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
		room_type = DataManager.RoomType.OBJECT
		#TODO раскомментировать после теста
		# 🆕 Выбираем случайный тип объекта
		#var object_types = DataManager.ObjectType.values()
		#object_type = object_types[randi() % object_types.size()]
		object_type = DataManager.ObjectType.TORTURE_RACK
	
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
	room_selected.emit(room)


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
	room_selected.emit(boss_room)


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
	print("=== process_next ===")
	print("current_path_progress: ", current_path_progress)
	print("all_rooms size: ", all_rooms.size())
	print("current_segment_index: ", current_segment_index)
	print("all_paths size: ", all_paths.size())
	
	# 1. Увеличиваем прогресс пути
	current_path_progress += 1
	
	# 2. Проверяем, есть ли комнаты в all_rooms
	if current_path_progress < all_rooms.size():
		# Есть следующая комната — загружаем
		current_room_index = current_path_progress
		_load_current_room()
		return
	
	# 3. Комнаты в пути закончились — переходим к следующему сегменту
	# current_segment_index уже указывает на следующий сегмент,
	# потому что мы увеличили его при выборе пути
	current_path_progress = all_rooms.size()  # сохраняем как есть
	
	# 4. Проверяем, есть ли следующий сегмент
	if current_segment_index < all_paths.size():
		# Есть развилка — показываем выбор
		var available_paths = all_paths[current_segment_index]
		SignalManager.show_paths.emit(available_paths)
	else:
		# Нет больше сегментов — босс
		_start_boss_fight()

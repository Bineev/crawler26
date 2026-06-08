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
	current_room_index = 0
	current_path_index = 0
	pending_paths.clear()
	boss_generated = false
	print("FloorManager reset")


func next_room():
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
	
	pending_paths = paths


func _generate_random_room(is_revealed: bool) -> RoomNode:
	var room_node = RoomNode.new()
	
	var roll = randf()
	var room_type: DataManager.RoomType
	var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
	
	if roll < 0.6:  # 60% бой
		room_type = DataManager.RoomType.COMBAT
		var combat_roll = randf()
		if combat_roll < 0.7:  # 70% нормальный
			combat_type = DataManager.CombatType.NORMAL
		else:  # 30% элитный
			combat_type = DataManager.CombatType.ELITE
	elif roll < 0.8:  # 20% эвент
		room_type = DataManager.RoomType.EVENT
	else:  # 20% объект
		room_type = DataManager.RoomType.OBJECT
	
	room_node.setup({
		"type": room_type,
		"combat_type": combat_type,
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
	if pending_paths.is_empty():
		print("No paths available to select!")
		return
	
	if path_index < 0 or path_index >= pending_paths.size():
		print("Invalid path index: ", path_index)
		return
	
	print("Path selected: ", path_index + 1)
	current_path_index = path_index
	
	for room in pending_paths[path_index]:
		all_rooms.append(room)
		print("  Added room: ", _get_room_type_string(room.room_type, room.combat_type))
	
	pending_paths = []
	_load_current_room()


func _load_current_room():
	# Проверяем, нужно ли генерировать босса
	if current_room_index >= all_rooms.size() and not boss_generated:
		_start_boss_fight()
		return
	
	if current_room_index >= all_rooms.size():
		print("All rooms completed!")
		floor_completed.emit()
		return
	
	var room = all_rooms[current_room_index]
	room.is_visited = true
	print("=== LOADING ROOM ", current_room_index, ": ", _get_room_type_string(room.room_type, room.combat_type), " ===")
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

func get_available_paths() -> Array[Array]:
	return pending_paths


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

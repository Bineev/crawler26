# autoload/game_test_manager.gd
extends Node

## ============================================================
## ТОЧКА ВХОДА ДЛЯ ТЕСТИРОВАНИЯ
## ============================================================

var current_room_node: Room = null
var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var current_room_index: int = 0

# Ссылка на главную сцену (куда добавлять комнаты)
var game_world: Node = null

# Загруженные сцены
var room_scene: PackedScene = preload("res://scenes/room.tscn")
var combat_room_scene: PackedScene = preload("res://scenes/combat_room.tscn")


## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func start_test(world_node: Node):
	print("=== GAME TEST START ===")
	game_world = world_node
	
	# Сбрасываем менеджеры
	FloorManager.reset()
	
	# Отключаем старые сигналы перед подключением
	if FloorManager.room_selected.is_connected(_on_room_selected):
		FloorManager.room_selected.disconnect(_on_room_selected)
	if FloorManager.floor_completed.is_connected(_on_floor_completed):
		FloorManager.floor_completed.disconnect(_on_floor_completed)
	
	# Подключаем сигналы
	FloorManager.room_selected.connect(_on_room_selected)
	FloorManager.floor_completed.connect(_on_floor_completed)
	
	# Запускаем этаж
	FloorManager.start_floor()


func reset():
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null
	
	current_room_index = 0
	FloorManager.reset()


func after_combat_victory():
	print("=== COMBAT VICTORY, LOADING NEXT ROOM ===")
	var available_paths = FloorManager.get_available_paths()
	if not available_paths.is_empty():
		# Для теста всегда выбираем первый путь (0)
		FloorManager.select_path(0)
	else:
		FloorManager.next_room()


## ============================================================
## ПРИВАТНЫЕ МЕТОДЫ
## ============================================================

func _on_room_selected(room_node: RoomNode):
	print("Room selected: ", _get_room_type_string(room_node.room_type, room_node.combat_type))
	
	# Создаём соответствующую комнату
	var room_instance = _create_room_from_node(room_node)
	
	if not room_instance:
		print("Failed to create room")
		return
	
	# Очищаем предыдущую комнату
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
	
	# Сохраняем новую комнату
	current_room_node = room_instance
	
	# Добавляем в дерево если ещё не добавлена
	if current_room_node and not current_room_node.is_inside_tree() and game_world:
		game_world.add_child(current_room_node)
		# Для Control используем anchor/offset вместо position
		current_room_node.anchor_left = 0.0
		current_room_node.anchor_top = 0.0
		current_room_node.anchor_right = 1.0
		current_room_node.anchor_bottom = 1.0
		current_room_node.offset_left = 0
		current_room_node.offset_top = 0
		current_room_node.offset_right = 0
		current_room_node.offset_bottom = 0


func _on_floor_completed():
	print("=== FLOOR COMPLETED ===")
	current_floor += 1
	current_room_index = 0
	FloorManager.start_floor()


func _create_room_from_node(room_node: RoomNode) -> Room:
	match room_node.room_type:
		DataManager.RoomType.COMBAT:
			return _create_combat_room(room_node)
		DataManager.RoomType.EVENT:
			return _create_event_room(room_node)
		DataManager.RoomType.OBJECT:
			return _create_object_room(room_node)
	
	return null


func _create_combat_room(room_node: RoomNode) -> Room:
	# Подбираем врагов
	var enemies = EnemySelector.select_enemies(
		room_node.combat_type,
		current_biome,
		current_floor,
		current_room_index
	)
	
	print("  Creating combat room with ", enemies.size(), " enemies")
	for enemy in enemies:
		print("    - ", DataManager.get_enemy_resource_name(enemy.enemy_id))
	
	# Инстанциируем комнату из сцены
	var room_instance = combat_room_scene.instantiate()
	
	# Добавляем в дерево
	if game_world:
		game_world.add_child(room_instance)
		# Растягиваем Control на весь родительский контейнер
		room_instance.position = Vector2(448, 30)
	
	# Настраиваем
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.COMBAT,
			"combat_type": room_node.combat_type,
			"biome": current_biome,
			"enemies": enemies,
		})
	else:
		print("ERROR: CombatRoom has no setup method!")
	
	current_room_index += 1
	return room_instance


func _create_event_room(room_node: RoomNode) -> Room:
	print("  Creating event room")
	
	var room_instance = room_scene.instantiate()
	
	if game_world:
		game_world.add_child(room_instance)
		# Растягиваем Control на весь родительский контейнер
		room_instance.anchor_left = 0.0
		room_instance.anchor_top = 0.0
		room_instance.anchor_right = 1.0
		room_instance.anchor_bottom = 1.0
		room_instance.offset_left = 0
		room_instance.offset_top = 0
		room_instance.offset_right = 0
		room_instance.offset_bottom = 0
	
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.EVENT,
			"biome": current_biome,
		})
	
	current_room_index += 1
	return room_instance


func _create_object_room(room_node: RoomNode) -> Room:
	print("  Creating object room")
	
	var room_instance = room_scene.instantiate()
	
	if game_world:
		game_world.add_child(room_instance)
		# Растягиваем Control на весь родительский контейнер
		room_instance.anchor_left = 0.0
		room_instance.anchor_top = 0.0
		room_instance.anchor_right = 1.0
		room_instance.anchor_bottom = 1.0
		room_instance.offset_left = 0
		room_instance.offset_top = 0
		room_instance.offset_right = 0
		room_instance.offset_bottom = 0
	
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.OBJECT,
			"biome": current_biome,
		})
	
	current_room_index += 1
	return room_instance


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

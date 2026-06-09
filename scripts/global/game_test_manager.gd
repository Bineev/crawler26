# autoload/game_test_manager.gd
extends Node

## ============================================================
## ТОЧКА ВХОДА ДЛЯ ТЕСТИРОВАНИЯ
## ============================================================

var current_room_node: Room = null
var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var current_room_index: int = 0
var hand_ui : HandUI = null
# Ссылка на главную сцену (куда добавлять комнаты)
var game_world: Node = null

# Ссылка на RoomManager (будет доступен как автолоад)
# RoomManager уже загружен как синглтон


## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func start_test(world_node: Node):
	print("=== GAME TEST START ===")
	game_world = world_node
	SignalManager.hand_ui_created.connect(_on_hand_ui_created)
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
	
	
func _on_hand_ui_created(hand_ui: HandUI):
	# Добавляем руку в game_world
	if game_world and hand_ui:
		game_world.add_child(hand_ui)

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

# autoload/game_test_manager.gd

func _on_room_selected(room_node: RoomNode):
	# Находим HandUI (один раз, можно сохранить в переменную)
	if not hand_ui:
		hand_ui = game_world.get_node_or_null("HandUI")
	
	var room_instance = RoomManager.create_room(
		room_node,
		current_floor,
		current_biome,
		current_room_index,
		hand_ui  # ← передаём HandUI
	)
	
	if not room_instance:
		print("Failed to create room")
		return
	
	# Очищаем предыдущую комнату
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
	
	# Сохраняем новую комнату
	current_room_node = room_instance
	
	# Добавляем в дерево
	if current_room_node and not current_room_node.is_inside_tree() and game_world:
		game_world.add_child(current_room_node)
		current_room_node.position = Vector2(448, 30)
		# _ready() сам вызовется и применит отложенные данные
		
		current_room_index += 1


func _on_floor_completed():
	print("=== FLOOR COMPLETED ===")
	current_floor += 1
	current_room_index = 0
	FloorManager.start_floor()


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

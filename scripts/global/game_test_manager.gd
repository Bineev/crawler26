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
var battle_log: BattleLogUI = null
# Ссылка на RoomManager (будет доступен как автолоад)
# RoomManager уже загружен как синглтон


## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================



func start_test(world_node: Node):
	print("=== GAME TEST START ===")
	game_world = world_node
	_reset_game_state()
	SignalManager.hand_ui_created.connect(_on_hand_ui_created)
	SignalManager.next_room.connect(_on_next_room)
	SignalManager.show_paths.connect(_on_show_paths)
	SignalManager.choice_panel_selected.connect(_on_choice_panel_selected)
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
	
	
func _on_hand_ui_created(created_hand_ui: HandUI):
	if not game_world:
		return
	
	# Если есть старая рука — удаляем
	if hand_ui:
		clear_ui()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	game_world.add_child(canvas_layer)
	canvas_layer.add_child(created_hand_ui)
	
	# Сохраняем ссылку
	hand_ui = created_hand_ui
	print("hand_ui saved: ", hand_ui)

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
	# Сбрасываем состояния
	_reset_game_state()
	
	# Обновляем стиль лога при смене биома
	if battle_log and current_biome:
		battle_log.set_biome_style(current_biome)
	
	# Находим HandUI (если ещё нет)
	if not hand_ui:
		hand_ui = game_world.get_node_or_null("HandUI")
	
	var room_instance = RoomManager.create_room(
		room_node,
		current_floor,
		current_biome,
		current_room_index,
		hand_ui
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
		current_room_node.position = DataManager.ROOM_POSITION
	
	current_room_index += 1
	
	_create_battle_log()
	
	SoundManager.start_gameplay_playlist()


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


func _create_battle_log():
	var log_scene = preload("res://scenes/battle_log.tscn")
	battle_log = log_scene.instantiate() as BattleLogUI
	battle_log.position = Vector2(1520, 80)  # правый верхний угол
	battle_log.size = Vector2(350, 500)
	
	# Устанавливаем стиль под биом
	battle_log.set_biome_style(current_biome)
	
	game_world.add_child(battle_log)


func _on_next_room():
	FloorManager.next_room()


func _on_show_paths(paths: Array):
	var choice_panel = preload("res://scenes/choice_panel.tscn").instantiate() as ChoicePanel
	choice_panel.setup(paths)
	game_world.add_child(choice_panel)
	choice_panel.position = DataManager.ROOM_POSITION + Vector2(0, 300)


func _on_choice_panel_selected(path_index: int):
	FloorManager.select_path(path_index)


func _reset_game_state():
	BattleManager.reset_battle()
	current_room_node = null


func clear_ui():
	# Удаляем руку и её CanvasLayer
	if hand_ui:
		var canvas_layer = hand_ui.get_parent()
		if canvas_layer is CanvasLayer:
			canvas_layer.queue_free()
		else:
			hand_ui.queue_free()
		hand_ui = null
	
	# Удаляем лог
	if battle_log:
		battle_log.queue_free()
		battle_log = null
	
	print("UI cleared")

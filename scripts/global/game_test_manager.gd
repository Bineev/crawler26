# autoload/game_test_manager.gd
extends Node

## ============================================================
## ТОЧКА ВХОДА ДЛЯ ТЕСТИРОВАНИЯ
## ============================================================

var current_room_node: Room = null
var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.ROTTEN_MARSHES
var current_room_index: int = 0
var hand_ui : HandUI = null
var blood_screen: BloodScreen = null
var game_world: Node = null
var battle_log: BattleLogUI = null
var end_turn_button : EndTurnButton = null
var player_portrait: PlayerPortrait = null
var player : PenitentStats = null
var energy_display: EnergyDisplay = null
var potion_container: HBoxContainer = null
var potion_full_label: Label = null
var death_ui: DeathUI = null
var tooltip_canvas: CanvasLayer = null
var potion_icons: Array[PotionIcon] = []
var is_ending_turn: bool = false
var gold_display: GoldDisplay = null
var key_display: KeyDisplay = null
var bone_display: BoneDisplay = null
var sub_viewport: SubViewport = null
var current_tooltip: Tooltip = null
var hit_effect: HitEffect = null

## Выбранный персонаж для текущего забега
var selected_character: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT

## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func prepare_game_initialization(world_node: Node) -> void:
	game_world = world_node
	DataManager.load_sounds()
	TranslationServer.set_locale("ru")
	
	# Подписываемся на сигналы
	SignalManager.hand_ui_created.connect(_on_hand_ui_created)
	SignalManager.next_room.connect(_on_next_room)
	SignalManager.show_paths.connect(_on_show_paths)
	SignalManager.choice_panel_selected.connect(_on_choice_panel_selected)
	SignalManager.battle_started.connect(_on_battle_started)
	SignalManager.player_turn_started.connect(_on_player_turn_started)
	SignalManager.enemy_turn_started.connect(_on_enemy_turn_started)
	SignalManager.battle_victory.connect(_on_battle_ended)
	SignalManager.battle_defeat.connect(_on_battle_ended)
	SignalManager.show_reward.connect(_on_show_reward)
	SignalManager.add_action_choice.connect(_on_add_action_choice)
	SignalManager.tooltip_requested.connect(_on_tooltip_requested)
	SignalManager.hide_tooltip.connect(_on_hide_tooltip)
	SignalManager.potion_added.connect(_on_potion_added)
	SignalManager.potion_removed.connect(_on_potion_removed)
	SignalManager.potion_used.connect(_on_potion_used)
	SignalManager.potion_discarded.connect(_on_potion_discarded)
	SignalManager.potion_deselect_all.connect(_on_potion_deselect_all)
	# Отключаем старые сигналы перед подключением
	if FloorManager.room_selected.is_connected(_on_room_selected):
		FloorManager.room_selected.disconnect(_on_room_selected)
	if FloorManager.floor_completed.is_connected(_on_floor_completed):
		FloorManager.floor_completed.disconnect(_on_floor_completed)
	
	FloorManager.room_selected.connect(_on_room_selected)
	FloorManager.floor_completed.connect(_on_floor_completed)


func create_character(character_class: DataManager.CharacterClass) -> void:
	# Проверяем, открыт ли персонаж
	if not ProgressManager.is_class_unlocked(character_class):
		printerr("Character not unlocked: ", character_class, " - using PENITENT as fallback")
		character_class = DataManager.CharacterClass.PENITENT
	
	selected_character = character_class
	
	# Создаём игрока
	player = PenitentStats.new()
	BattleManager.set_player(player)
	print("Player created: ", player)
	
	RunManager.current_character = selected_character


func initialize_new_run() -> void:
	# Очищаем состояние
	potion_icons.clear()
	_reset_game_state()
	ProgressManager.reset_available_biomes()
	
	# Устанавливаем дефолтные значения
	current_floor = 0
	current_room_index = 0
	
	# Инициализируем забег
	RunManager.initialize_run()
	


func start_new_biome() -> void:
	print("=== START NEW BIOME ===")
	
	# Поднимаем этаж
	current_floor += 1
	current_room_index = 0
	# Очищаем этаж
	_reset_game_state()
	
	# 🆕 Сбрасываем FloorManager
	FloorManager.reset()
	
	# Устанавливаем этаж для FloorManager
	FloorManager.current_floor = current_floor
	
	# Загружаем данные намерений для биома
	DataManager.load_biome_enemies(current_biome)
	
	# Запускаем музыку
	SoundManager.start_gameplay_playlist()
	
	# Создаём UI элементы (если их нет)
	if not blood_screen:
		_create_blood_screen()
	if not player_portrait:
		_create_player_portrait()
	if not gold_display:
		_create_gold_display()
	if not key_display:
		_create_key_display()
	if not bone_display:
		_create_bone_display()
	if not potion_container:
		_create_potion_display()
	
	if current_floor == 1:
		# 🆕 Сохраняем снимок прогресса на старте забега
		ProgressManager.save_run_start_snapshot()
		for potion in DataManager.get_random_potions(1):
			RunManager.add_potion(potion)
		
	
	# Запускаем этаж
	FloorManager.start_floor()

func start_test(world_node: Node):
	print("=== GAME TEST START ===")
	DataManager.load_sounds()
	TranslationServer.set_locale("ru")
	game_world = world_node
	
	# Проверяем, открыт ли выбранный персонаж
	if not ProgressManager.is_class_unlocked(selected_character):
		printerr("Character not unlocked: ", selected_character, " - using PENITENT as fallback")
		selected_character = DataManager.CharacterClass.PENITENT
	
	potion_icons.clear()
	_reset_game_state()
	current_room_index = 0
	# 🆕 Устанавливаем биом
	DataManager.load_biome_enemies(current_biome)
	
	# Создаём игрока
	player = PenitentStats.new()
	BattleManager.set_player(player)
	print("Player created in start_test: ", player)
	
	# Инициализируем забег с выбранным персонажем
	RunManager.current_character = selected_character
	RunManager.initialize_run()
	print("Run initialized with character: ", selected_character, " deck size: ", RunManager.get_player_deck().master_cards.size())
	
	# Подписываемся на сигналы
	SignalManager.hand_ui_created.connect(_on_hand_ui_created)
	SignalManager.next_room.connect(_on_next_room)
	SignalManager.show_paths.connect(_on_show_paths)
	SignalManager.choice_panel_selected.connect(_on_choice_panel_selected)
	SignalManager.battle_started.connect(_on_battle_started)
	SignalManager.player_turn_started.connect(_on_player_turn_started)
	SignalManager.enemy_turn_started.connect(_on_enemy_turn_started)
	SignalManager.battle_victory.connect(_on_battle_ended)
	SignalManager.battle_defeat.connect(_on_battle_ended)
	SignalManager.show_reward.connect(_on_show_reward)
	SignalManager.add_action_choice.connect(_on_add_action_choice)
	SignalManager.tooltip_requested.connect(_on_tooltip_requested)
	SignalManager.hide_tooltip.connect(_on_hide_tooltip)

	
	# Сбрасываем менеджеры
	FloorManager.reset()
	SoundManager.start_gameplay_playlist()
	
	_create_blood_screen()
	_create_player_portrait()
	_create_gold_display()
	_create_key_display()
	_create_bone_display()
	_create_potion_display()
	
	for potion in DataManager.get_random_potions(1):
		RunManager.add_potion(potion)
	
	# Отключаем старые сигналы перед подключением
	if FloorManager.room_selected.is_connected(_on_room_selected):
		FloorManager.room_selected.disconnect(_on_room_selected)
	if FloorManager.floor_completed.is_connected(_on_floor_completed):
		FloorManager.floor_completed.disconnect(_on_floor_completed)
	
	FloorManager.room_selected.connect(_on_room_selected)
	FloorManager.floor_completed.connect(_on_floor_completed)
	
	FloorManager.start_floor()

func select_character(character_class: DataManager.CharacterClass) -> bool:
	if not ProgressManager.is_class_unlocked(character_class):
		printerr("Character not unlocked: ", character_class)
		return false
	
	selected_character = character_class
	print("Character selected: ", selected_character)
	return true

func get_available_characters() -> Array[DataManager.CharacterClass]:
	return ProgressManager.unlocked_classes.duplicate()

func _on_hand_ui_created(created_hand_ui: HandUI):
	if not game_world:
		return
	
	if hand_ui:
		clear_ui()
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	game_world.add_child(canvas_layer)
	canvas_layer.add_child(created_hand_ui)
	
	hand_ui = created_hand_ui
	print("hand_ui saved: ", hand_ui)
	_create_end_turn_button()

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
		FloorManager.select_path(0)
	else:
		FloorManager.next_room()

## ============================================================
## ПРИВАТНЫЕ МЕТОДЫ
## ============================================================

func _on_room_selected(room_node: RoomNode, should_increment_room_index: bool = true, enemies_ids: Array[DataManager.EnemyId] = []):
	_clean_empty_canvas_layers()
	_reset_game_state()
	
	if battle_log and current_biome:
		battle_log.set_biome_style(current_biome)
	
	if not hand_ui:
		hand_ui = game_world.get_node_or_null("HandUI")
	
	var room_instance = RoomManager.create_room(
		room_node,
		current_floor,
		current_biome,
		current_room_index,
		hand_ui,
		enemies_ids
	)
	
	if not room_instance:
		print("Failed to create room")
		return
	
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
	
	current_room_node = room_instance
	
	if current_room_node and not current_room_node.is_inside_tree() and game_world:
		game_world.add_child(current_room_node)
		current_room_node.position = DataManager.ROOM_POSITION * DataManager.SCALE_FACTOR
	
	# 🆕 Сохраняем ТЕКУЩУЮ комнату (если это не конкретный бой)
	if room_node.room_type == DataManager.RoomType.COMBAT and room_node.combat_type == DataManager.CombatType.CONCRETE_COMBAT:
		pass
	else:
		SaveManager.save_game()
	# мы сохранили комнату, а затем увеличился индекс
	# значит при загрузке индекс будет не увеличенный, но увеличится когда загрузится комната
	# следующая комната (сохраняется опять старый индекс, затем увеличивается)
	# выходим из игры 
	# загружаемся (индекс старый, затем увеличивается) - вроде все нормально
	if should_increment_room_index:
		current_room_index += 1
	
	if current_room_node.room_type == DataManager.RoomType.COMBAT:
		_create_battle_log()

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
	battle_log.position = Vector2(1520, 80) * DataManager.SCALE_FACTOR
	battle_log.size = Vector2(350, 350)
	battle_log.set_biome_style(current_biome)
	game_world.add_child(battle_log)

func _on_next_room():
	FloorManager.next_room()

func _on_show_paths(paths: Array):
	var choice_panel = preload("res://scenes/choice_panel.tscn").instantiate() as ChoicePanel
	choice_panel.setup(paths)
	game_world.add_child(choice_panel)
	choice_panel.position = DataManager.ROOM_POSITION + Vector2(0, 300) * DataManager.SCALE_FACTOR

func _on_choice_panel_selected(path_index: int):
	FloorManager.select_path(path_index)

func clear_ui():
	if hand_ui:
		var canvas_layer = hand_ui.get_parent()
		if canvas_layer is CanvasLayer:
			canvas_layer.queue_free()
		else:
			hand_ui.queue_free()
		hand_ui = null
	
	if battle_log:
		battle_log.queue_free()
		battle_log = null
		
	# BUG
	## 🆕 Очищаем массив иконок зелий
	#potion_icons.clear()
	
	print("UI cleared")

func _create_end_turn_button():
	var button_scene = preload("res://scenes/end_turn_button.tscn")
	end_turn_button = button_scene.instantiate()
	
	var canvas_layer = hand_ui.get_parent()
	if canvas_layer:
		canvas_layer.add_child(end_turn_button)
		end_turn_button.position = DataManager.END_BUTTON_POSITION * DataManager.SCALE_FACTOR

func _on_battle_started():
	if end_turn_button:
		end_turn_button.visible = true

func _on_player_turn_started():
	if end_turn_button:
		end_turn_button.visible = true
		end_turn_button.is_ending_turn = false

func _on_enemy_turn_started():
	if end_turn_button:
		end_turn_button.visible = false
		end_turn_button.is_ending_turn = true

func _on_battle_ended():
	if end_turn_button:
		end_turn_button.visible = false
		end_turn_button.is_ending_turn = false

func _create_blood_screen():
	var screen_scene = preload("res://scenes/blood_screen.tscn")
	blood_screen = screen_scene.instantiate() as BloodScreen
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	game_world.add_child(canvas_layer)
	canvas_layer.add_child(blood_screen)

func _create_player_portrait():
	var portrait_scene = preload("res://scenes/player_portrait.tscn")
	player_portrait = portrait_scene.instantiate() as PlayerPortrait
	player_portrait.position = Vector2(50, 80) * DataManager.SCALE_FACTOR
	game_world.add_child(player_portrait)
	player_portrait.setup(BattleManager.get_player())

func _create_energy_display():
	var energy_scene = preload("res://scenes/energy_display.tscn")
	energy_display = energy_scene.instantiate() as EnergyDisplay
	energy_display.position = (DataManager.END_BUTTON_POSITION + Vector2(10, 70)) * DataManager.SCALE_FACTOR
	game_world.add_child(energy_display)

func get_player_portrait() -> PlayerPortrait:
	return player_portrait

func _on_show_reward(reward_panel: RewardPanel):
	add_reward_panel(reward_panel)

func add_reward_panel(reward_panel: RewardPanel):
	clear_ui()
	if reward_panel and not reward_panel.is_inside_tree():
		var canvas_layer = CanvasLayer.new()
		canvas_layer.layer = 200
		game_world.add_child(canvas_layer)
		canvas_layer.add_child(reward_panel)

func _on_add_action_choice(action_choice: Control, title: String, actions: Array[DataManager.ActionType]) -> void:
	add_action_choice(action_choice, title, actions)

func add_action_choice(action_choice: Control, title: String, actions: Array[DataManager.ActionType]) -> void:
	if not action_choice:
		return
	
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 300
	game_world.add_child(canvas_layer)
	canvas_layer.add_child(action_choice)
	action_choice.global_position = DataManager.ROOM_POSITION * DataManager.SCALE_FACTOR
	action_choice.setup(title, actions)

func _create_gold_display() -> void:
	gold_display = preload("res://scenes/gold_display.tscn").instantiate() as GoldDisplay
	game_world.add_child(gold_display)
	gold_display.global_position = DataManager.COINS_SCREEN_POSITION * DataManager.SCALE_FACTOR

func _create_key_display() -> void:
	key_display = preload("res://scenes/key_display.tscn").instantiate() as KeyDisplay
	game_world.add_child(key_display)
	key_display.global_position = DataManager.KEYS_SCREEN_POSITION * DataManager.SCALE_FACTOR

func _create_bone_display() -> void:
	bone_display = preload("res://scenes/bone_display.tscn").instantiate() as BoneDisplay
	game_world.add_child(bone_display)
	bone_display.global_position = DataManager.BONES_SCREEN_POSITION * DataManager.SCALE_FACTOR

func _clean_empty_canvas_layers() -> void:
	if not game_world:
		return
	
	for child in game_world.get_children():
		if child is CanvasLayer:
			var has_children = false
			for sub_child in child.get_children():
				has_children = true
				break
			
			if not has_children:
				child.queue_free()

func _create_potion_display() -> void:
	_clear_potions()
	potion_container = HBoxContainer.new()
	potion_container.global_position = DataManager.POTION_CONTAINER_POSITION * DataManager.SCALE_FACTOR
	potion_container.add_theme_constant_override("separation", 10)
	game_world.add_child(potion_container)
	potion_container.scale *= DataManager.SCALE_FACTOR
	
	potion_full_label = Label.new()
	potion_full_label.text = tr("potion_inventory_full")
	potion_full_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	potion_full_label.add_theme_font_size_override("font_size", 16)
	potion_full_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	potion_full_label.global_position = DataManager.POTION_CONTAINER_POSITION + Vector2(110, 90)
	potion_full_label.visible = false
	game_world.add_child(potion_full_label)
	
	for potion in RunManager.get_potions():
		_add_potion_icon(potion)
	
	_update_full_label()


func _clear_potions() -> void:
	# Очищаем массив иконок
	potion_icons.clear()
	
	# Удаляем все иконки из контейнера
	if potion_container:
		for child in potion_container.get_children():
			if is_instance_valid(child):
				child.queue_free()
	
	# Скрываем надпись "Инвентарь полон"
	if potion_full_label:
		potion_full_label.visible = false


func _add_potion_icon(potion: PotionResource) -> void:
	var icon = preload("res://scenes/potion_icon.tscn").instantiate() as PotionIcon
	potion_container.add_child(icon)
	icon.setup(potion)
	potion_icons.append(icon)
	icon.update_state()

func _on_potion_added(potion: PotionResource) -> void:
	_add_potion_icon(potion)
	_update_full_label()

func _on_potion_removed(index: int) -> void:
	# 🆕 Проверяем, что индекс валидный
	if index < 0 or index >= potion_icons.size():
		_clean_null_icons()
		_update_full_label()
		return
	
	var icon = potion_icons[index]
	potion_icons.remove_at(index)
	
	if is_instance_valid(icon):
		icon.queue_free()
	
	_update_full_label()


func _clean_null_icons() -> void:
	var i = 0
	while i < potion_icons.size():
		if not is_instance_valid(potion_icons[i]):
			potion_icons.remove_at(i)
		else:
			i += 1

func _on_potion_used(potion_icon: PotionIcon) -> void:
	var index = potion_icons.find(potion_icon)
	if index == -1:
		# 🆕 Если не найден — возможно, уже удалён
		_clean_null_icons()
		return
	
	var player = BattleManager.get_player()
	if not player:
		return
	
	for effect in potion_icon.potion_data.effects:
		var targets: Array = []
		
		match effect.target:
			DataManager.EffectTarget.SELF:
				targets = [player]
			DataManager.EffectTarget.ENEMY:
				var enemies = BattleManager.get_enemies()
				if not enemies.is_empty():
					targets = [enemies[0]]
			DataManager.EffectTarget.ALL_ENEMIES:
				targets = BattleManager.get_enemies()
			DataManager.EffectTarget.ALL_ALLIES:
				targets = [player]
			DataManager.EffectTarget.ANY:
				var enemies = BattleManager.get_enemies()
				targets = enemies + [player]
		
		if not targets.is_empty():
			EffectExecutor.execute(effect, player, targets)
	
	RunManager.remove_potion(index)


func _on_potion_deselect_all() -> void:
	## 🆕 Сначала очищаем null
	#_clean_null_icons()
	
	for icon in potion_icons:
		if is_instance_valid(icon):
			icon.deselect()

func get_current_room() -> Room:
	return current_room_node

func _on_potion_discarded(potion_icon: PotionIcon) -> void:
	var index = potion_icons.find(potion_icon)
	if index == -1:
		_clean_null_icons()
		return
	
	RunManager.remove_potion(index)
	SignalManager.log_message.emit("Зелье выброшено!")


func _update_full_label() -> void:
	if potion_full_label:
		potion_full_label.visible = RunManager.get_potions().size() >= DataManager.POTION_MAX_COUNT

func restart_run():
	print("=== RESTART RUN ===")
	
	_reset_game_state()
	clear_ui()
	
	for child in game_world.get_children():
		child.queue_free()
	
	_disconnect_all_signals()
	
	BattleManager.reset_battle()
	RunManager.reset_run()
	
	start_test(game_world)

func _disconnect_all_signals():
	if SignalManager.hand_ui_created.is_connected(_on_hand_ui_created):
		SignalManager.hand_ui_created.disconnect(_on_hand_ui_created)
	if SignalManager.next_room.is_connected(_on_next_room):
		SignalManager.next_room.disconnect(_on_next_room)
	if SignalManager.show_paths.is_connected(_on_show_paths):
		SignalManager.show_paths.disconnect(_on_show_paths)
	if SignalManager.choice_panel_selected.is_connected(_on_choice_panel_selected):
		SignalManager.choice_panel_selected.disconnect(_on_choice_panel_selected)
	if SignalManager.battle_started.is_connected(_on_battle_started):
		SignalManager.battle_started.disconnect(_on_battle_started)
	if SignalManager.player_turn_started.is_connected(_on_player_turn_started):
		SignalManager.player_turn_started.disconnect(_on_player_turn_started)
	if SignalManager.enemy_turn_started.is_connected(_on_enemy_turn_started):
		SignalManager.enemy_turn_started.disconnect(_on_enemy_turn_started)
	if SignalManager.battle_victory.is_connected(_on_battle_ended):
		SignalManager.battle_victory.disconnect(_on_battle_ended)
	if SignalManager.battle_defeat.is_connected(_on_battle_ended):
		SignalManager.battle_defeat.disconnect(_on_battle_ended)
	if SignalManager.show_reward.is_connected(_on_show_reward):
		SignalManager.show_reward.disconnect(_on_show_reward)
	if SignalManager.add_action_choice.is_connected(_on_add_action_choice):
		SignalManager.add_action_choice.disconnect(_on_add_action_choice)
	if SignalManager.potion_added.is_connected(_on_potion_added):
		SignalManager.potion_added.disconnect(_on_potion_added)
	if SignalManager.potion_removed.is_connected(_on_potion_removed):
		SignalManager.potion_removed.disconnect(_on_potion_removed)
	if SignalManager.potion_used.is_connected(_on_potion_used):
		SignalManager.potion_used.disconnect(_on_potion_used)
	if SignalManager.potion_discarded.is_connected(_on_potion_discarded):
		SignalManager.potion_discarded.disconnect(_on_potion_discarded)
	if SignalManager.potion_deselect_all.is_connected(_on_potion_deselect_all):
		SignalManager.potion_deselect_all.disconnect(_on_potion_deselect_all)
	if SignalManager.tooltip_requested.is_connected(_on_tooltip_requested):
		SignalManager.tooltip_requested.disconnect(_on_tooltip_requested)
	if SignalManager.hide_tooltip.is_connected(_on_hide_tooltip):
		SignalManager.hide_tooltip.disconnect(_on_hide_tooltip)

func create_death_ui():
	death_ui = preload("res://scenes/death_ui.tscn").instantiate() as DeathUI
	game_world.add_child(death_ui)
	death_ui.global_position = Vector2.ZERO
	
	# 🆕 Сохраняем игру с флагом is_run_ended = true
	SaveManager.save_game_with_run_ended()

func clear_ui_after_death():
	clear_ui()
	if potion_container:
		potion_container.hide()
	if bone_display:
		bone_display.hide()
	if gold_display:
		gold_display.hide()
	if key_display:
		key_display.hide()

func _reset_game_state():
	BattleManager.reset_battle()
	
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null
	
	clear_ui()

func _on_tooltip_requested(tooltip_data: Dictionary, position: Vector2):
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null
	
	if not tooltip_canvas:
		tooltip_canvas = CanvasLayer.new()
		tooltip_canvas.layer = 1000
		game_world.add_child(tooltip_canvas)
	
	var tooltip = preload("res://scenes/tooltip.tscn").instantiate() as Tooltip
	tooltip_canvas.add_child(tooltip)
	tooltip.setup(tooltip_data)
	tooltip.show_at(position)
	current_tooltip = tooltip

func _on_hide_tooltip():
	if current_tooltip:
		current_tooltip.queue_free()
		current_tooltip = null


# Устанавливает биом и обновляет все зависимости
func set_biome(biome: DataManager.Biome) -> void:
	current_biome = biome
	RunManager.current_biome = biome
	FloorManager.current_biome = biome
	DataManager.load_biome_enemies(biome)
	
	# Удаляем биом из доступных в ProgressManager
	ProgressManager.select_biome(biome)
	
	print("Biome set to: ", DataManager.Biome.keys()[biome])


func load_current_run() -> void:
	print("=== LOAD CURRENT RUN ===")
	
	# 1. Игрок уже создан в restore_player()
	var player = BattleManager.get_player()
	if not player:
		printerr("CRITICAL: No player found after restore!")
		return
	
	# 2. Загружаем данные намерений для биома
	DataManager.load_biome_enemies(current_biome)
	
	# 3. Очищаем UI
	clear_ui()
	
	# 4. Создаём UI элементы
	_create_blood_screen()
	_create_player_portrait()
	_create_gold_display()
	_create_key_display()
	_create_bone_display()
	_create_potion_display()
	
	# 5. Подключаем сигналы FloorManager
	if FloorManager.room_selected.is_connected(_on_room_selected):
		FloorManager.room_selected.disconnect(_on_room_selected)
	if FloorManager.floor_completed.is_connected(_on_floor_completed):
		FloorManager.floor_completed.disconnect(_on_floor_completed)
	
	FloorManager.room_selected.connect(_on_room_selected)
	FloorManager.floor_completed.connect(_on_floor_completed)

	# отладка
	print("=== LOAD CURRENT RUN DEBUG ===")
	print("current_room_index: ", current_room_index)
	print("FloorManager.all_rooms.size(): ", FloorManager.all_rooms.size())
	print("FloorManager.all_paths.size(): ", FloorManager.all_paths.size())
	
	for i in range(FloorManager.all_rooms.size()):
		var room = FloorManager.all_rooms[i]
		var type_str = "COMBAT" if room.room_type == DataManager.RoomType.COMBAT else "OBJECT" if room.room_type == DataManager.RoomType.OBJECT else "EVENT"
		print("  Room ", i, ": ", type_str, " visited=", room.is_visited, " revealed=", room.is_revealed)

	# 6. Загружаем сохранённую комнату
	var room_index = current_room_index
	if room_index < FloorManager.all_rooms.size() and room_index >= 0:
		var room_node = FloorManager.all_rooms[room_index]
		room_node.is_visited = true
		_on_room_selected(room_node, true)  # 🆕 true вместо false
	else:
		printerr("Room index invalid, starting new biome...")
		start_new_biome()

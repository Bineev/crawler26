# scripts/battle/battle_manager.gd
extends Node

## ============================================================
## СОСТОЯНИЕ БОЯ (используем enum из DataManager)
## ============================================================

var current_state: DataManager.BattleState = DataManager.BattleState.IDLE

## ============================================================
## УЧАСТНИКИ БОЯ
## ============================================================

var player: CharacterStats = null
var enemies: Array = []  # Array[EnemyInstance]
var current_room_node: Node = null  # ссылка на комнату для уведомлений

## ============================================================
## КОЛОДА
## ============================================================

var battle_deck: BattleDeck = null
var hand_ui: HandUI = null

## ============================================================
## ИНИЦИАЛИЗАЦИЯ БОЯ
## ============================================================

func _get_target_at_position(pos: Vector2) -> Node:
	# Проверяем всех врагов на коллизию
	for enemy in enemies:
		var enemy_ui = enemy.get_node("EnemyUI")
		if enemy_ui and enemy_ui.get_rect().has_point(enemy_ui.to_local(pos)):
			return enemy
	return null


func start_battle(player_stats: CharacterStats, enemy_instances: Array, battle_deck: BattleDeck, hand_ui_node: HandUI, floor_level: int = 1, biome_index: int = 1, room_node: Node = null):
	print("бой стартует")
	SignalManager.battle_victory.connect(_on_battle_victory)
	SignalManager.battle_defeat.connect(_on_battle_defeat)
	
	player = player_stats
	enemies = enemy_instances
	hand_ui = hand_ui_node
	current_room_node = room_node
	battle_deck = battle_deck
	
	# Инициализация врагов
	for enemy in enemies:
		if enemy.has_method("init"):
			enemy.init(floor_level, biome_index)
		if enemy.has_method("load_intents"):
			enemy.load_intents()
	
	# Раздаём карты (внутри вызывается add_card для каждой карты)
	battle_deck.draw_initial_hand()
	
	# НЕ вызываем update_hand повторно! Карты уже отрисованы в draw_initial_hand
	
	SignalManager.battle_started.emit()
	start_player_turn()


## ============================================================
## ХОД ИГРОКА
## ============================================================

func start_player_turn():
	if current_state != DataManager.BattleState.IDLE and current_state != DataManager.BattleState.ENEMY_TURN:
		return
	
	current_state = DataManager.BattleState.PLAYER_TURN
	
	if player and player.has_method("restore_energy"):
		player.restore_energy()
	
	if battle_deck:
		battle_deck.start_turn()
	
	SignalManager.player_turn_started.emit()
	SignalManager.turn_started.emit()

## ============================================================
## ХОД ВРАГА
## ============================================================

func start_enemy_turn():
	current_state = DataManager.BattleState.ENEMY_TURN
	SignalManager.enemy_turn_started.emit()
	SignalManager.turn_started.emit()
	
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		
		# Враг выбирает намерение
		var intent = null
		if enemy.has_method("select_next_intent"):
			intent = enemy.select_next_intent()
		
		if intent:
			SignalManager.enemy_intent_changed.emit(enemy, intent)
			execute_enemy_action(enemy, intent)
		
		# Проверка на смерть игрока после каждого врага
		if player and player.get_health() <= 0:
			defeat()
			return
		
		# Проверка победы после каждого врага
		check_victory()
		if current_state == DataManager.BattleState.VICTORY:
			return
	
	# Обработка конца хода для всех существ
	process_end_of_turn()
	
	SignalManager.turn_ended.emit()
	
	# Проверка победы/поражения после тиков
	check_defeat()
	check_victory()
	
	if current_state == DataManager.BattleState.VICTORY or current_state == DataManager.BattleState.DEFEAT:
		return
	
	# Все враги сходили — ход игрока
	start_player_turn()


func execute_enemy_action(enemy, intent: IntentEntry):
	for effect in intent.effects:
		EffectExecutor.execute(effect, enemy.stats if enemy.has_method("get_stats") else enemy, [player])


## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	# Тик статусов игрока
	if player and player.has_method("process_end_of_turn"):
		player.process_end_of_turn()
	
	# Тик статусов врагов
	for enemy in enemies:
		if enemy.is_alive() and enemy.has_method("process_end_of_turn"):
			enemy.process_end_of_turn()


## ============================================================
## ПОБЕДА / ПОРАЖЕНИЕ
## ============================================================

func victory():
	if current_state == DataManager.BattleState.VICTORY:
		return
	current_state = DataManager.BattleState.VICTORY
	SignalManager.battle_victory.emit()


func defeat():
	if current_state == DataManager.BattleState.DEFEAT:
		return
	current_state = DataManager.BattleState.DEFEAT
	SignalManager.battle_defeat.emit()


## ============================================================
## ПРОВЕРКИ
## ============================================================

func check_victory():
	if current_state != DataManager.BattleState.ENEMY_TURN and current_state != DataManager.BattleState.PLAYER_TURN:
		return
	
	var all_dead = true
	for enemy in enemies:
		if enemy.is_alive():
			all_dead = false
			break
	
	if all_dead:
		victory()


func check_defeat():
	if player and player.get_health() <= 0:
		defeat()
		SignalManager.log_message.emit(tr("msg_defeat"))


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func is_player_turn() -> bool:
	return current_state == DataManager.BattleState.PLAYER_TURN


func is_enemy_turn() -> bool:
	return current_state == DataManager.BattleState.ENEMY_TURN


func is_battle_active() -> bool:
	return current_state == DataManager.BattleState.PLAYER_TURN or current_state == DataManager.BattleState.ENEMY_TURN


func get_player() -> CharacterStats:
	return player


func get_enemies() -> Array:
	return enemies


func get_battle_deck() -> BattleDeck:
	return battle_deck


func get_current_state() -> DataManager.BattleState:
	return current_state


## ============================================================
## СИГНАЛЫ ПОБЕДЫ/ПОРАЖЕНИЯ
## ============================================================

func _on_battle_victory():
	SignalManager.battle_victory.disconnect(_on_battle_victory)
	SignalManager.battle_defeat.disconnect(_on_battle_defeat)
	
	if current_room_node and current_room_node.has_method("on_battle_victory"):
		current_room_node.on_battle_victory()


func _on_battle_defeat():
	SignalManager.battle_victory.disconnect(_on_battle_victory)
	SignalManager.battle_defeat.disconnect(_on_battle_defeat)
	
	if current_room_node and current_room_node.has_method("on_battle_defeat"):
		current_room_node.on_battle_defeat()


## ============================================================
## УПРАВЛЕНИЕ ИГРОКОМ
## ============================================================

func set_player(player_stats: CharacterStats):
	player = player_stats

func get_player_health() -> int:
	return player.get_health() if player else 0


func get_player_max_health() -> int:
	return player.get_max_health() if player else 0


func get_player_block() -> int:
	return player.get_block() if player else 0


func get_player_energy() -> int:
	return player.get_energy() if player else 0


func get_player_atonement() -> int:
	return player.get_atonement() if player else 0


func end_player_turn():
	if current_state != DataManager.BattleState.PLAYER_TURN:
		return
	
	# Сбрасываем руку
	if battle_deck:
		battle_deck.discard_hand()
	
	SignalManager.turn_ended.emit()
	start_enemy_turn()

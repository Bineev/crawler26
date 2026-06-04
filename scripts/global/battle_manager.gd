# scripts/battle/battle_manager.gd
extends Node

## ============================================================
## СОСТОЯНИЕ БОЯ
## ============================================================

enum BattleState {
	IDLE,           # вне боя
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}

var current_state: BattleState = BattleState.IDLE

## ============================================================
## УЧАСТНИКИ БОЯ
## ============================================================

var player: CharacterStats = null
var enemies: Array = []  # Array[EnemyInstance]

## ============================================================
## КОЛОДА
## ============================================================

var battle_deck: BattleDeck = null
var hand_ui: HandUI = null


## ============================================================
## ИНИЦИАЛИЗАЦИЯ БОЯ
## ============================================================

func start_battle(player_stats: CharacterStats, enemy_instances: Array, master_deck: DeckData, hand_ui_node: HandUI, floor_level: int = 1, biome_index: int = 1):
	player = player_stats
	enemies = enemy_instances
	hand_ui = hand_ui_node
	
	# Инициализируем каждого врага с учётом скейлинга
	for enemy in enemies:
		if enemy.has_method("init"):
			enemy.init(floor_level, biome_index)
		if enemy.has_method("load_intents"):
			enemy.load_intents()
	
	# Создаём колоду для боя
	battle_deck = master_deck.create_battle_copy()
	battle_deck.hand_ui = hand_ui
	battle_deck.draw_initial_hand()
	
	SignalManager.battle_started.emit()
	
	# Начинаем ход игрока
	start_player_turn()


## ============================================================
## ХОД ИГРОКА
## ============================================================

func start_player_turn():
	if current_state != BattleState.IDLE and current_state != BattleState.ENEMY_TURN:
		return
	
	current_state = BattleState.PLAYER_TURN
	
	# Восстанавливаем энергию
	if player and player.has_method("restore_energy"):
		player.restore_energy()
	
	# Добираем карты
	if battle_deck:
		battle_deck.start_turn()
	
	SignalManager.player_turn_started.emit()
	SignalManager.turn_started.emit()


func end_player_turn():
	if current_state != BattleState.PLAYER_TURN:
		return
	
	# Сбрасываем руку
	if battle_deck:
		battle_deck.discard_hand()
	
	SignalManager.turn_ended.emit()
	
	# Начинаем ход врага
	start_enemy_turn()


## ============================================================
## ХОД ВРАГА
## ============================================================

func start_enemy_turn():
	current_state = BattleState.ENEMY_TURN
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
		if current_state == BattleState.VICTORY:
			return
	
	# Обработка конца хода для всех существ
	process_end_of_turn()
	
	SignalManager.turn_ended.emit()
	
	# Проверка победы/поражения после тиков
	check_defeat()
	check_victory()
	
	if current_state == BattleState.VICTORY or current_state == BattleState.DEFEAT:
		return
	
	# Все враги сходили — ход игрока
	start_player_turn()


func execute_enemy_action(enemy, intent: IntentEntry):
	for effect in intent.effects:
		EffectExecutor.execute(effect, enemy.stats, [player])


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
	if current_state == BattleState.VICTORY:
		return
	current_state = BattleState.VICTORY
	SignalManager.battle_victory.emit()


func defeat():
	if current_state == BattleState.DEFEAT:
		return
	current_state = BattleState.DEFEAT
	SignalManager.battle_defeat.emit()


## ============================================================
## ПРОВЕРКИ
## ============================================================

func check_victory():
	if current_state != BattleState.ENEMY_TURN and current_state != BattleState.PLAYER_TURN:
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


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func is_player_turn() -> bool:
	return current_state == BattleState.PLAYER_TURN


func is_enemy_turn() -> bool:
	return current_state == BattleState.ENEMY_TURN


func is_battle_active() -> bool:
	return current_state == BattleState.PLAYER_TURN or current_state == BattleState.ENEMY_TURN


func get_player() -> CharacterStats:
	return player


func get_enemies() -> Array:
	return enemies


func get_battle_deck() -> BattleDeck:
	return battle_deck


func get_current_state() -> BattleState:
	return current_state

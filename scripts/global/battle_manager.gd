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

var next_card_damage_multiplier: float = 1.0
## ============================================================
## ИНИЦИАЛИЗАЦИЯ БОЯ
## ============================================================

func _ready():
	SignalManager.enemy_died.connect(_on_enemy_died)
	SignalManager.player_died.connect(_on_player_died)
	SignalManager.player_death_animation_finished.connect(_on_player_death_animation_finished)


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
	
	self.player = player_stats
	self.enemies = enemy_instances
	self.hand_ui = hand_ui_node
	self.current_room_node = room_node
	self.battle_deck = battle_deck
	
	# 🆕 Применяем проклятие идола
	var player = BattleManager.get_player()
	if player:
		RunManager.apply_idol_curse_to_player(player)
	# 🆕 Уменьшаем счётчик баффа энергии (если активен)
	RunManager.decrement_energy_buff()
	# Инициализация врагов
	for enemy in enemies:
		if enemy.has_method("load_intents"):
			enemy.load_intents()
	
	# Раздаём карты (внутри вызывается add_card для каждой карты)
	#battle_deck.draw_initial_hand()
	
	# НЕ вызываем update_hand повторно! Карты уже отрисованы в draw_initial_hand

	# 🆕 Обрабатываем артефакты с триггером ON_START_FIGHT
	RunManager.process_artifacts_on_start_fight()

	SignalManager.battle_started.emit()
	start_player_turn()


## ============================================================
## ХОД ИГРОКА
## ============================================================

func start_player_turn():
	if current_state != DataManager.BattleState.IDLE and current_state != DataManager.BattleState.ENEMY_TURN:
		return
	
	current_state = DataManager.BattleState.PLAYER_TURN
	
	# Восстанавливаем энергию
	if player and player.has_method("restore_energy"):
		player.restore_energy()

	# === ОБРАБОТКА ЗАМОРОЗКИ ===
	var is_frozen = player and player.has_status(DataManager.Status.FROZEN)
	
	if is_frozen:
		# Отмечаем, что игрок начал ход замороженным
		player._frozen_at_turn_start = true
		# Уменьшаем энергию на 2 (но не меньше 0)
		var current_energy = player.get_energy()
		player.set_energy(max(0, current_energy - 2))
		SignalManager.log_message.emit("Вы заморожены! Энергия уменьшена на 2. Статусы приостановлены.")
		
		# Выбираем намерения врагов (чтобы игрок видел, что они собираются делать)
		for enemy in enemies:
			if enemy.is_alive():
				var intent = enemy.select_next_intent()
				if intent:
					SignalManager.enemy_intent_changed.emit(enemy, intent)
		
		# Добираем карты (игрок всё равно может играть)
		if battle_deck:
			battle_deck.start_turn()
		
		SignalManager.player_turn_started.emit()
		SignalManager.turn_started.emit()
		SignalManager.log_message.emit("--- Ход игрока (заморожен) ---")
		return
	
	# === НОРМАЛЬНЫЙ ХОД ===
	
	# Тик статусов игрока (только если не заморожен)
	if player:
		await player.process_start_of_turn()
	
	# Выбираем намерения для всех врагов
	for enemy in enemies:
		if enemy.is_alive():
			var intent = enemy.select_next_intent()
			if intent:
				SignalManager.enemy_intent_changed.emit(enemy, intent)
	
	# Восстанавливаем энергию
	if player and player.has_method("restore_energy"):
		player.restore_energy()
	
	# Добираем карты
	if battle_deck:
		battle_deck.start_turn()
	
	SignalManager.player_turn_started.emit()
	SignalManager.turn_started.emit()
	SignalManager.log_message.emit("--- Ход игрока ---")

## ============================================================
## ХОД ВРАГА
## ============================================================

func start_enemy_turn():
	print("=== ENEMY TURN START ===")
	
	enemies = enemies.filter(func(e): return e != null and is_instance_valid(e) and e.is_alive())
	print("Enemies alive: ", enemies.size())
	
	current_state = DataManager.BattleState.ENEMY_TURN
	SignalManager.enemy_turn_started.emit()
	SignalManager.turn_started.emit()
	
	for enemy in enemies:
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		
		if enemy.has_status(DataManager.Status.FROZEN):
			SignalManager.log_message.emit("%s заморожен и пропускает ход!" % enemy.get_display_name())
			await get_tree().create_timer(DataManager.ENEMY_STEP_DELAY).timeout
			continue
		
		# ШАГ 1: Начало хода врага (пассивки, статусы)
		await enemy.process_start_of_turn()
		
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		
		# ШАГ 2: Действие врага
		var intent = enemy.current_intent
		if intent:
			await enemy.execute_intent_with_animation(player)
		else:
			await get_tree().create_timer(DataManager.ENEMY_STEP_DELAY).timeout
		
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		
		# ШАГ 3: Конец хода врага (уменьшение длительности статусов)
		enemy.process_end_of_turn()
		
		if player and player.get_health() <= 0:
			defeat()
			return
		
		await get_tree().create_timer(DataManager.ENEMY_STEP_DELAY).timeout
	
	# 🆕 Только проверяем победу/поражение
	check_defeat()
	if current_state == DataManager.BattleState.VICTORY or current_state == DataManager.BattleState.DEFEAT:
		return
	
	# Передаём ход игроку
	start_player_turn()
	
	check_defeat()
	if current_state == DataManager.BattleState.VICTORY or current_state == DataManager.BattleState.DEFEAT:
		return
	
	start_player_turn()
## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	# Тик статусов игрока
	# Если заморожен — длительность статусов не уменьшается
	#if player and player.has_method("process_end_of_turn"):
		#player.process_end_of_turn()
	
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
			SignalManager.log_message.emit("%s повержен!" % enemy.name)
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
	return enemies  # теперь это массив EnemyInstance (Node2D)


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
	if player:
		player.clear_all_statuses()
	if current_room_node and current_room_node.has_method("on_battle_victory"):
		current_room_node.on_battle_victory()


func _on_battle_defeat():
	SignalManager.battle_victory.disconnect(_on_battle_victory)
	SignalManager.battle_defeat.disconnect(_on_battle_defeat)
	if player:
		player.clear_all_statuses()
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
	
	# Снимаем заморозку с игрока в конце хода
	if player:
		player.process_end_of_turn()  # внутри сам проверит FROZENатусы восстановлены.")
	
	# Сбрасываем руку
	if battle_deck:
		battle_deck.discard_hand()

	# 🆕 Обрабатываем артефакты с триггером TURN_COUNT_END
	RunManager.process_artifacts_on_turn_end()

	SignalManager.turn_ended.emit()
	start_enemy_turn()


func _on_enemy_died(enemy: CharacterStats):
	print("Enemy died: ", enemy.get_display_name())
	enemies.erase(enemy)
	
	# Проверяем, остались ли живые враги
	var all_dead = true
	for e in enemies:
		if e.is_alive():
			all_dead = false
			break
	
	if all_dead:
		victory()


func _on_player_died(player: CharacterStats):
	defeat()


func reset_battle():
	current_state = DataManager.BattleState.IDLE
	# Очищаем статусы и пассивки у игрока
	if player:
		_clear_all_statuses(player)
		_clear_all_passives(player)
	
	# Очищаем статусы и пассивки у врагов
	for enemy in enemies:
		if enemy:
			_clear_all_statuses(enemy)
			_clear_all_passives(enemy)
	enemies = []
	#battle_deck = null
	hand_ui = null
	current_room_node = null
	print("BattleManager reset")


func _clear_all_statuses(target: CharacterStats):
	if not target:
		return
	
	var statuses = target.active_statuses.keys()
	for status_id in statuses:
		target.remove_status(status_id)


func _clear_all_passives(target: CharacterStats):
	if not target:
		return
	
	var passives = target.active_passives.duplicate()
	for passive in passives:
		target.remove_passive(passive)


func get_hand_ui() -> HandUI:
	return hand_ui


func _on_player_death_animation_finished():
	# Показываем экран поражения после анимации
	defeat()

func set_next_card_damage_multiplier(multiplier: float) -> void:
	next_card_damage_multiplier = multiplier

func get_next_card_damage_multiplier() -> float:
	var multiplier = next_card_damage_multiplier
	next_card_damage_multiplier = 1.0  # сбрасываем после получения
	return multiplier

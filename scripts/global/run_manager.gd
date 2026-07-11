# autoload/run_manager.gd
extends Node

var player_deck_data: DeckData = null
var current_character: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT
var poison_damage_per_stack: int = DataManager.POISON_BASE_DAMAGE_PER_STACK
var bleed_damage_per_stack: int = DataManager.BLEED_BASE_DAMAGE_PER_STACK
var burn_damage_per_stack: int = DataManager.BURN_BASE_DAMAGE_PER_STACK
var regen_heal_per_stack: int = DataManager.REGEN_HEAL_PER_STACK

var coins: int = DataManager.STARTING_COINS
var bones: int = DataManager.STARTING_BONES

## Массив артефактов, которые есть у игрока в текущем забеге
var artifacts: Array[ArtifactResource] = []

## Счётчики для артефактов (например, для CARD_PLAYED_COUNTER)
var artifact_counters: Dictionary = {}  # key: ArtifactId, value: int

var keys: int = 0

func _ready():
	initialize_run()
	SignalManager.add_artifact.connect(_on_add_artifact)
	SignalManager.add_card_to_deck.connect(add_card)


func initialize_run():
	player_deck_data = DeckData.new()
	player_deck_data.master_cards = DataManager.get_starting_deck().duplicate()
	DeckManager._load_cards_data()
	DeckManager._init_unlocked_cards()
	print("RunManager initialized with deck size: ", player_deck_data.master_cards.size())


func get_player_deck() -> DeckData:
	if not player_deck_data:
		initialize_run()
	return player_deck_data


func add_card(card: CardData):
	if player_deck_data:
		player_deck_data.master_cards.append(card)
		SignalManager.log_message.emit("Карта добавлена в колоду: %s" % card.get_localized_name())


func remove_card(card: CardData):
	if player_deck_data:
		player_deck_data.master_cards.erase(card)


func reset_deck():
	player_deck_data = null
	initialize_run()


func modify_poison_damage(modifier: int):
	poison_damage_per_stack += modifier


func modify_bleed_damage(modifier: int):
	bleed_damage_per_stack += modifier


func modify_burn_damage(modifier: int):
	burn_damage_per_stack += modifier


func reset_status_values():
	poison_damage_per_stack = DataManager.POISON_BASE_DAMAGE_PER_STACK
	bleed_damage_per_stack = DataManager.BLEED_BASE_DAMAGE_PER_STACK
	burn_damage_per_stack = DataManager.BURN_BASE_DAMAGE_PER_STACK
	regen_heal_per_stack = DataManager.REGEN_HEAL_PER_STACK


func add_coins(amount: int) -> void:
	coins += amount
	SignalManager.coins_changed.emit(coins)

func add_bones(amount: int) -> void:
	bones += amount
	SignalManager.bones_changed.emit(bones)

func get_coins() -> int:
	return coins

func get_bones() -> int:
	return bones

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		SignalManager.coins_changed.emit(coins)
		return true
	return false

func spend_bones(amount: int) -> bool:
	if bones >= amount:
		bones -= amount
		SignalManager.bones_changed.emit(bones)
		return true
	return false


func add_artifact(artifact: ArtifactResource) -> void:
	var instance = artifact.duplicate_for_instance()
	artifacts.append(instance)
	artifact_counters[instance.id] = 0
	
	# 🆕 Обрабатываем ONE_TIME триггер сразу при получении
	_process_one_time_trigger(instance)
	
	# 🆕 Обрабатываем CUSTOM триггер
	_process_custom_trigger(instance)
	
	SignalManager.artifact_added.emit(instance)
	print("Артефакт добавлен: ", instance.get_localized_name())

func remove_artifact(artifact_id: DataManager.ArtifactId) -> void:
	for i in range(artifacts.size()):
		if artifacts[i].id == artifact_id:
			artifacts.remove_at(i)
			artifact_counters.erase(artifact_id)
			SignalManager.artifact_removed.emit(artifact_id)
			return

func get_artifacts_by_trigger(trigger: DataManager.ArtifactTrigger) -> Array[ArtifactResource]:
	var result: Array[ArtifactResource] = []
	for artifact in artifacts:
		if artifact.has_trigger(trigger):
			result.append(artifact)
	return result

func increment_artifact_counter(artifact_id: DataManager.ArtifactId) -> void:
	if artifact_counters.has(artifact_id):
		artifact_counters[artifact_id] += 1
		SignalManager.artifact_counter_changed.emit(artifact_id, artifact_counters[artifact_id])

func reset_artifact_counter(artifact_id: DataManager.ArtifactId) -> void:
	if artifact_counters.has(artifact_id):
		artifact_counters[artifact_id] = 0
		SignalManager.artifact_counter_changed.emit(artifact_id, artifact_counters[artifact_id])

func get_artifact_counter(artifact_id: DataManager.ArtifactId) -> int:
	return artifact_counters.get(artifact_id, 0)


func _process_one_time_trigger(artifact: ArtifactResource) -> void:
	var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.ONE_TIME)
	if trigger_index == -1:
		return
	
	# Проверяем, что есть эффект для этого триггера
	if trigger_index < artifact.effects.size():
		var effect = artifact.effects[trigger_index]
		
		# Выполняем эффект (источник — игрок)
		var player = BattleManager.get_player()
		if player:
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт активирован: %s" % artifact.get_localized_name())
		
		# 🆕 Удаляем триггер ONE_TIME из массива
		artifact.triggers.remove_at(trigger_index)
		
		# 🆕 Удаляем соответствующий эффект
		artifact.effects.remove_at(trigger_index)
		
		SignalManager.artifact_triggered.emit(artifact)
		print("ONE_TIME эффект артефакта выполнен: ", artifact.get_localized_name())


## Обрабатывает артефакты с триггером ON_START_FIGHT
func process_artifacts_on_start_fight() -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.ON_START_FIGHT)
		if trigger_index == -1:
			continue
		
		# Проверяем, что есть эффект для этого триггера
		if trigger_index < artifact.effects.size():
			var effect = artifact.effects[trigger_index]
			
			# Выполняем эффект (источник — игрок)
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт сработал в начале боя: %s" % artifact.get_localized_name())
			
			# Если триггер ONE_TIME уже удалён, а ON_START_FIGHT должен срабатывать каждый бой
			# Проверяем, нужно ли удалять триггер после использования
			var trigger_type = artifact.triggers[trigger_index]
			if trigger_type == DataManager.ArtifactTrigger.ON_START_FIGHT:
				# Оставляем триггер, так как он должен срабатывать каждый бой
				# Но если артефакт должен сработать только один раз в бою — ничего не делаем
				pass
			
			SignalManager.artifact_triggered.emit(artifact)


func _on_add_artifact(artifact: ArtifactResource) -> void:
	add_artifact(artifact)


# В RunManager.gd

## Обрабатывает артефакты с триггером TURN_COUNT_START
func process_artifacts_on_turn_start() -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.TURN_COUNT_START)
		if trigger_index == -1:
			continue
		
		# Увеличиваем счётчик
		var counter = get_artifact_counter(artifact.id) + 1
		artifact_counters[artifact.id] = counter
		
		# Если превысили порог — сбрасываем до 1
		if counter > artifact.trigger_count:
			artifact_counters[artifact.id] = 1
			counter = 1
		
		SignalManager.artifact_counter_changed.emit(artifact.id, counter)
		
		# Если достигли порога — срабатываем
		if counter == artifact.trigger_count:
			if trigger_index < artifact.effects.size():
				var effect = artifact.effects[trigger_index]
				EffectExecutor.execute(effect, player, [player])
				SignalManager.log_message.emit("Артефакт сработал: %s" % artifact.get_localized_name())
				SignalManager.artifact_triggered.emit(artifact)


## Обрабатывает артефакты с триггером TURN_COUNT_END
func process_artifacts_on_turn_end() -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.TURN_COUNT_END)
		if trigger_index == -1:
			continue
		
		# Увеличиваем счётчик ходов для артефакта
		var counter = get_artifact_counter(artifact.id)
		counter += 1
		artifact_counters[artifact.id] = counter
		SignalManager.artifact_counter_changed.emit(artifact.id, counter)
		# Проверяем, достигнут ли порог
		if counter >= artifact.trigger_count:
			# Сбрасываем счётчик
			artifact_counters[artifact.id] = 0
			
			# Выполняем эффект
			if trigger_index < artifact.effects.size():
				var effect = artifact.effects[trigger_index]
				EffectExecutor.execute(effect, player, [player])
				SignalManager.log_message.emit("Артефакт сработал: %s" % artifact.get_localized_name())
				SignalManager.artifact_triggered.emit(artifact)


## Обрабатывает артефакты с триггером CARD_PLAYED_COUNTER
func process_artifacts_on_card_played(card_data: CardData) -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER)
		if trigger_index == -1:
			continue
		
		# Увеличиваем счётчик
		var counter = get_artifact_counter(artifact.id) + 1
		artifact_counters[artifact.id] = counter
		
		# Если превысили порог — сбрасываем до 1
		if counter > artifact.card_count_threshold:
			artifact_counters[artifact.id] = 0
			counter = 0
		
		SignalManager.artifact_counter_changed.emit(artifact.id, counter)
		
		# Если достигли порога — срабатываем
		if counter == artifact.card_count_threshold:
			if trigger_index < artifact.effects.size():
				var effect = artifact.effects[trigger_index]
				EffectExecutor.execute(effect, player, [player])
				SignalManager.log_message.emit("Артефакт сработал: %s" % artifact.get_localized_name())
				SignalManager.artifact_triggered.emit(artifact)


func _process_custom_trigger(artifact: ArtifactResource) -> void:
	var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.CUSTOM)
	if trigger_index == -1:
		return
	
	# Проверяем, что есть эффект для этого триггера
	if trigger_index < artifact.effects.size():
		var effect = artifact.effects[trigger_index]
		
		# Проверяем, есть ли кастомный скрипт
		if effect.custom_script:
			var custom_instance = effect.custom_script.new()
			if custom_instance.has_method("apply"):
				var player = BattleManager.get_player()
				if player:
					custom_instance.apply(effect, player, [player], {}, null)
					SignalManager.log_message.emit("Артефакт активирован (CUSTOM): %s" % artifact.get_localized_name())
			else:
				printerr("CUSTOM script missing 'apply' method: ", effect.custom_script.resource_path)
		else:
			printerr("CUSTOM trigger has no custom_script in effect")
		
		# 🆕 Удаляем триггер CUSTOM из массива
		artifact.triggers.remove_at(trigger_index)
		
		# 🆕 Удаляем соответствующий эффект
		artifact.effects.remove_at(trigger_index)
		
		SignalManager.artifact_triggered.emit(artifact)
		print("CUSTOM эффект артефакта выполнен: ", artifact.get_localized_name())


## Обрабатывает артефакты с триггером HEALTH_DROPPED_BELOW
func process_health_dropped_below(health_before: int, health_after: int, percent_before: float, percent_after: float) -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	var artifacts_to_remove: Array[ArtifactResource] = []
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.HEALTH_DROPPED_BELOW)
		if trigger_index == -1:
			continue
		
		if trigger_index >= artifact.effects.size():
			continue
		
		# Проверяем условие
		var condition_met = false
		if artifact.is_amount_check_percent:
			if percent_before >= artifact.amount_check_conditional and percent_after < artifact.amount_check_conditional:
				condition_met = true
		else:
			if health_before >= artifact.amount_check_conditional and health_after < artifact.amount_check_conditional:
				condition_met = true
		
		if not condition_met:
			continue
		
		# Выполняем эффект
		var effect = artifact.effects[trigger_index]
		EffectExecutor.execute(effect, player, [player])
		SignalManager.log_message.emit("Артефакт сработал (здоровье упало ниже): %s" % artifact.get_localized_name())
		SignalManager.artifact_triggered.emit(artifact)
		
		if artifact.is_one_time_conditional:
			artifact.triggers.remove_at(trigger_index)
			artifact.effects.remove_at(trigger_index)
			
			if artifact.triggers.is_empty():
				artifacts_to_remove.append(artifact)
	
	for artifact in artifacts_to_remove:
		remove_artifact(artifact.id)

func add_keys(amount: int) -> void:
	keys += amount
	SignalManager.keys_changed.emit(keys)

func use_key() -> bool:
	if keys > 0:
		keys -= 1
		SignalManager.keys_changed.emit(keys)
		return true
	return false

func get_keys() -> int:
	return keys

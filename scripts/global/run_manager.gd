# autoload/run_manager.gd
extends Node

var player_deck_data: DeckData = null
var current_character: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
# === Статусы ===
var poison_damage_per_stack: int = DataManager.POISON_BASE_DAMAGE_PER_STACK
var bleed_damage_per_stack: int = DataManager.BLEED_BASE_DAMAGE_PER_STACK
var burn_damage_per_stack: int = DataManager.BURN_BASE_DAMAGE_PER_STACK
var burn_threshold_stacks: int = DataManager.BURN_THRESHOLD_STACKS
# === Статусы (для игрока) ===
var player_poison_damage_per_stack: int = DataManager.POISON_BASE_DAMAGE_PER_STACK
var player_bleed_damage_per_stack: int = DataManager.BLEED_BASE_DAMAGE_PER_STACK
var player_burn_damage_per_stack: int = DataManager.BURN_BASE_DAMAGE_PER_STACK
var player_regen_heal_per_stack: int = DataManager.REGEN_HEAL_PER_STACK
var player_bleed_duration_bonus: int = 0

var has_lucky_pick: bool = false

var cold_freeze_threshold: int = DataManager.COLD_FREEZE_THRESHOLD
var cold_effect_percent: float = DataManager.COLD_EFFECT_PERCENT_PER_STACK
var cold_min_multiplier: float = DataManager.COLD_MIN_EFFECT_MULTIPLIER
var regen_heal_per_stack: int = DataManager.REGEN_HEAL_PER_STACK
var strength_bonus_per_stack: int = DataManager.STRENGTH_FLAT_BONUS_PER_STACK
var weakness_damage_multiplier: float = DataManager.WEAKNESS_DAMAGE_MULTIPLIER
var vulnerability_damage_multiplier: float = DataManager.VULNERABILITY_DAMAGE_MULTIPLIER
var poison_healing_reduction: float = DataManager.POISON_HEALING_REDUCTION
var shame_damage_taken_multiplier: float = DataManager.SHAME_DAMAGE_TAKEN_MULTIPLIER
var shame_atonement_multiplier: float = DataManager.SHAME_ATONEMENT_MULTIPLIER
var frozen_energy_loss: int = DataManager.FROZEN_ENERGY_LOSS
var infection_bleed_multiplier: int = DataManager.INFECTION_BLEED_MULTIPLIER
# === Балансные константы ===
var starting_hand_size: int = DataManager.STARTING_HAND_SIZE
var cards_to_draw_per_turn: int = DataManager.CARDS_TO_DRAW_PER_TURN
var max_energy: int = DataManager.MAX_ENERGY

# === Ресурсы ===
var default_item_cost: int = DataManager.DEFAULT_ITEM_COST
var reward_gold_default: int = DataManager.REWARD_GOLD_DEFAULT
var reward_damage_default: int = DataManager.REWARD_DAMAGE_DEFAULT
var energy_buff_reward_amount: int = DataManager.ENERGY_BUFF_REWARD_AMOUNT
var rest_default_heal: int = DataManager.REST_DEFAULT_HEAL

# === Стартовые валюты ===
var starting_coins: int = DataManager.STARTING_COINS
var starting_bones: int = DataManager.STARTING_BONES
var starting_keys: int = DataManager.STARTING_KEYS

var coins: int = 0
var bones: int = 0
var keys: int = 0

# === Взаимодействия статусов ===
var is_bleed_poison_interaction_enabled: bool = true   # Bleed + Poison → Мука
var is_poison_burn_interaction_enabled: bool = false    # Poison + Burn → Взрыв
var is_bleed_cold_interaction_enabled: bool = false     # Bleed + Cold → Гангрена

var attacks_this_turn: int = 0

## Массив артефактов, которые есть у игрока в текущем забеге
var artifacts: Array[ArtifactResource] = []
## Счётчики для артефактов (например, для CARD_PLAYED_COUNTER)
var artifact_counters: Dictionary = {}  # key: ArtifactId, value: int
var potions: Array[PotionResource] = []
## Структура: { "max_energy_buff": количество оставшихся боёв, "bonus_energy": сколько добавлено }
var temp_buffs: Dictionary = {
	"max_energy_buff": 0,
	"bonus_energy": 0
}
var idol_curse_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var idol_curse_remaining: int = 0  # сколько боёв осталось
var is_robber: bool = false
var deck_size_buff_remaining: int = 0
var deck_size_bonus: int = 0

## Отложенные статусы для наложения в начале следующего боя
var pending_statuses: Array[Dictionary] = []

func _ready():
	initialize_run()
	SignalManager.add_artifact.connect(_on_add_artifact)
	SignalManager.add_card_to_deck.connect(add_card)
	SignalManager.add_coins.connect(add_coins)
	SignalManager.spend_coins.connect(spend_bones)
	SignalManager.add_potion.connect(add_potion)


func initialize_run():
	# Сбрасываем константы до базовых значений
	reset_run_constants()
	
	# Создаём новую колоду
	player_deck_data = DeckData.new()
	
	# Получаем стартовую колоду для выбранного персонажа
	var starting_deck = DeckManager.get_starting_deck(current_character)
	player_deck_data.master_cards = starting_deck.duplicate()
	
	# Устанавливаем стартовые валюты
	coins = starting_coins
	bones = starting_bones
	keys = starting_keys
	
	# Очищаем другие данные забега
	artifacts.clear()
	potions.clear()
	temp_buffs = {
		"max_energy_buff": 0,
		"bonus_energy": 0
	}
	deck_size_buff_remaining = 0
	deck_size_bonus = 0
	idol_curse_remaining = 0
	is_robber = false
	
	print("RunManager initialized with deck size: ", player_deck_data.master_cards.size())


func reset_attacks_counter() -> void:
	attacks_this_turn = 0

func get_player_deck() -> DeckData:
	if not player_deck_data:
		initialize_run()
	return player_deck_data


func add_pending_status(status_id: DataManager.Status, stacks: int, duration: int) -> void:
	pending_statuses.append({
		"status_id": status_id,
		"stacks": stacks,
		"duration": duration,
	})
	SignalManager.log_message.emit("Статус будет наложен в начале следующего боя: %s" % DataManager.get_status_name(status_id))


func apply_pending_statuses(player: CharacterStats) -> void:
	if pending_statuses.is_empty():
		return
	
	for status_data in pending_statuses:
		var status_resource = DataManager.get_status_resource(status_data["status_id"])
		if status_resource:
			player.add_status(
				status_resource,
				status_data["stacks"],
				status_data["duration"],
				player
			)
			SignalManager.log_message.emit("Наложен отложенный статус: %s" % status_resource.get_localized_name())
	
	pending_statuses.clear()


func add_card(card: CardData):
	if player_deck_data:
		player_deck_data.master_cards.append(card)
		
		# 🆕 Звук получения карты
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.GET_SOMETHING))
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
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.GET_GOLD))
	SignalManager.coins_changed.emit(coins)

func add_bones(amount: int) -> void:
	bones += amount
	SignalManager.bones_changed.emit(bones)

func spend_bones(amount: int) -> bool:
	if bones >= amount:
		bones -= amount
		SignalManager.bones_changed.emit(bones)
		return true
	return false


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


func add_artifact(artifact: ArtifactResource) -> void:
	var instance = artifact.duplicate_for_instance()
	artifacts.append(instance)
	artifact_counters[instance.id] = 0

	# 🆕 Звук получения артефакта
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.GET_SOMETHING))

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
	var indices_to_remove: Array[int] = []
	
	# Находим все индексы ONE_TIME триггеров
	for i in range(artifact.triggers.size()):
		if artifact.triggers[i] == DataManager.ArtifactTrigger.ONE_TIME:
			indices_to_remove.append(i)
	
	if indices_to_remove.is_empty():
		return
	
	var player = BattleManager.get_player()
	if not player:
		return
	
	# Проходим по индексам в обратном порядке, чтобы не сбить индексы
	for i in range(indices_to_remove.size() - 1, -1, -1):
		var trigger_index = indices_to_remove[i]
		
		# Проверяем, что есть эффект для этого триггера
		if trigger_index < artifact.effects.size():
			var effect = artifact.effects[trigger_index]
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт активирован (ONE_TIME): %s" % artifact.get_localized_name())
			
			# Удаляем триггер и эффект
			artifact.triggers.remove_at(trigger_index)
			artifact.effects.remove_at(trigger_index)
			
			SignalManager.artifact_triggered.emit(artifact)
			print("ONE_TIME эффект артефакта выполнен: ", artifact.get_localized_name())


### Обрабатывает артефакты с триггером ON_START_FIGHT
#func process_artifacts_on_start_fight() -> void:
	#var player = BattleManager.get_player()
	#if not player:
		#return
	#
	#for artifact in artifacts:
		#var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.ON_START_FIGHT)
		#if trigger_index == -1:
			#continue
		#
		## Проверяем, что есть эффект для этого триггера
		#if trigger_index < artifact.effects.size():
			#var effect = artifact.effects[trigger_index]
			#
			## Выполняем эффект (источник — игрок)
			#EffectExecutor.execute(effect, player, [player])
			#SignalManager.log_message.emit("Артефакт сработал в начале боя: %s" % artifact.get_localized_name())
			#
			## Если триггер ONE_TIME уже удалён, а ON_START_FIGHT должен срабатывать каждый бой
			## Проверяем, нужно ли удалять триггер после использования
			#var trigger_type = artifact.triggers[trigger_index]
			#if trigger_type == DataManager.ArtifactTrigger.ON_START_FIGHT:
				## Оставляем триггер, так как он должен срабатывать каждый бой
				## Но если артефакт должен сработать только один раз в бою — ничего не делаем
				#pass
			#
			#SignalManager.artifact_triggered.emit(artifact)

func process_artifacts_on_start_fight() -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		for i in range(artifact.triggers.size()):
			if artifact.triggers[i] == DataManager.ArtifactTrigger.ON_START_FIGHT:
				if i < artifact.effects.size():
					var effect = artifact.effects[i]
					EffectExecutor.execute(effect, player, [player])
					SignalManager.log_message.emit("Артефакт сработал в начале боя: %s" % artifact.get_localized_name())
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


func apply_energy_buff(bonus: int, duration: int) -> void:
	var old_bonus = temp_buffs["bonus_energy"]
	var old_duration = temp_buffs["max_energy_buff"]
	
	if old_bonus == 0:
		# Если баффа нет — просто применяем
		temp_buffs["bonus_energy"] = bonus
		temp_buffs["max_energy_buff"] = duration
	else:
		if bonus == old_bonus:
			# Одинаковые значения — суммируем длительность
			temp_buffs["max_energy_buff"] = old_duration + duration
		else:
			# Разные значения — берём максимум бонуса и максимум длительности
			temp_buffs["bonus_energy"] = max(bonus, old_bonus)
			temp_buffs["max_energy_buff"] = max(duration, old_duration)
	
	# 🆕 Звук получения баффа
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.HEAL))
	
	var player = BattleManager.get_player()
	if player:
		var current_max = player.get_max_energy()
		var new_max = DataManager.MAX_ENERGY + temp_buffs["bonus_energy"]
		player.set_flat(DataManager.FlatStat.MAX_ENERGY, new_max)
		player.restore_energy()
		SignalManager.log_message.emit("Максимальная энергия: +%d на %d боёв!" % [temp_buffs["bonus_energy"], temp_buffs["max_energy_buff"]])

func decrement_energy_buff() -> void:
	if temp_buffs["max_energy_buff"] <= 0:
		return
	
	temp_buffs["max_energy_buff"] -= 1
	
	if temp_buffs["max_energy_buff"] <= 0:
		# Снимаем временный бафф
		var player = BattleManager.get_player()
		if player:
			# 🆕 Вычитаем только бонус от временного баффа
			var current_max = player.get_max_energy()
			var new_max = current_max - temp_buffs["bonus_energy"]
			player.set_flat(DataManager.FlatStat.MAX_ENERGY, new_max)
			if player.get_energy() != new_max:
				player.set_energy(new_max)
			SignalManager.log_message.emit("Временный бафф энергии закончился! Максимальная энергия восстановлена до %d" % new_max)
		temp_buffs["bonus_energy"] = 0


func get_energy_buff_remaining() -> int:
	return temp_buffs["max_energy_buff"]

func get_energy_bonus() -> int:
	return temp_buffs["bonus_energy"]


func apply_idol_curse(biome: DataManager.Biome, duration: int) -> void:
	if idol_curse_remaining > 0:
		# Если проклятие уже есть — суммируем длительность
		idol_curse_remaining += duration
		SignalManager.log_message.emit("Проклятие идола продлено на %d боёв! Всего осталось %d." % [duration, idol_curse_remaining])
	else:
		# Новое проклятие
		idol_curse_biome = biome
		idol_curse_remaining = duration
		SignalManager.log_message.emit("На вас проклятие идола на %d боя!" % duration)

func apply_idol_curse_to_player(player: CharacterStats) -> void:
	if idol_curse_remaining <= 0:
		return
	
	match idol_curse_biome:
		DataManager.Biome.MOLE_TUNNELS:
			var bleed_status = DataManager.get_status_resource(DataManager.Status.BLEED)
			if bleed_status:
				player.add_status(bleed_status, 2, 3, player)
				SignalManager.log_message.emit("Проклятие идола: Кровотечение!")
		# TODO: другие биомы
	
	idol_curse_remaining -= 1

func get_idol_curse_remaining() -> int:
	return idol_curse_remaining


func add_potion(potion: PotionResource) -> void:
	var instance = potion.duplicate_for_instance()
	
	# Если инвентарь полон — удаляем самое первое зелье
	if potions.size() >= DataManager.POTION_MAX_COUNT:
		remove_potion(0)
	
	potions.append(instance)
	# 🆕 Звук получения зелья
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.GET_POTION))
	SignalManager.potion_added.emit(instance)


func remove_potion(index: int) -> void:
	if index < potions.size():
		potions.remove_at(index)
		SignalManager.potion_removed.emit(index)


func get_potions() -> Array[PotionResource]:
	return potions


func set_robber(value: bool) -> void:
	is_robber = value


func get_robber() -> bool:
	return is_robber

func apply_deck_size_buff(amount: int, duration: int) -> void:
	var old_amount = deck_size_bonus
	var old_duration = deck_size_buff_remaining
	
	if old_amount == 0:
		# Если баффа нет — просто применяем
		deck_size_bonus = amount
		deck_size_buff_remaining = duration
	else:
		if amount == old_amount:
			# Одинаковые значения — суммируем длительность
			deck_size_buff_remaining = old_duration + duration
		else:
			# Разные значения — берём максимум бонуса и максимум длительности
			deck_size_bonus = max(amount, old_amount)
			deck_size_buff_remaining = max(duration, old_duration)

	# 🆕 Звук получения баффа
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.HEAL))

	var player = BattleManager.get_player()
	if player:
		var current_hand_size = player.get_flat(DataManager.FlatStat.HAND_SIZE)
		var new_hand_size = DataManager.STARTING_HAND_SIZE + deck_size_bonus
		player.set_flat(DataManager.FlatStat.HAND_SIZE, new_hand_size)
		SignalManager.log_message.emit("Размер руки: +%d на %d боёв!" % [deck_size_bonus, deck_size_buff_remaining])



func decrement_deck_size_buff() -> void:
	if deck_size_buff_remaining <= 0:
		return
	
	deck_size_buff_remaining -= 1
	
	if deck_size_buff_remaining <= 0:
		var player = BattleManager.get_player()
		if player:
			var current_hand_size = player.get_flat(DataManager.FlatStat.HAND_SIZE)
			player.set_flat(DataManager.FlatStat.HAND_SIZE, current_hand_size - deck_size_bonus)
			SignalManager.log_message.emit("Бафф размера руки закончился!")
		deck_size_bonus = 0


func reset_run():
	# Сбрасываем все данные забега
	player_deck_data = null
	potions.clear()
	artifacts.clear()
	coins = 0
	bones = 0
	keys = 0
	is_robber = false
	temp_buffs = {
		"max_energy_buff": 0,
		"bonus_energy": 0
	}
	deck_size_buff_remaining = 0
	deck_size_bonus = 0
	idol_curse_remaining = 0
	initialize_run()


# autoload/run_manager.gd

func process_artifact_on_status_applied_to_enemy(status_id: DataManager.Status, player: CharacterStats) -> void:
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.ADD_ACTION_WHEN_APPLY_CONCRETE_STATUS_TO_ENEMY)
		if trigger_index == -1:
			continue
		
		# Проверяем, что статус совпадает с отслеживаемым
		if artifact.tracked_status != status_id:
			continue
		
		if trigger_index < artifact.effects.size():
			var effect = artifact.effects[trigger_index]
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт сработал при наложении статуса: %s" % artifact.get_localized_name())
			SignalManager.artifact_triggered.emit(artifact)
			
			# Если триггер ONE_TIME — удаляем
			var trigger_type = artifact.triggers[trigger_index]
			if trigger_type == DataManager.ArtifactTrigger.ADD_ACTION_WHEN_APPLY_CONCRETE_STATUS_TO_ENEMY:
				# Проверяем, нужно ли удалять триггер после использования
				# Если артефакт должен сработать только один раз — удаляем
				# Пока оставляем — срабатывает каждый раз при наложении статуса
				pass


func process_artifact_on_attack_threshold(player: CharacterStats) -> void:
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.ATTACKS_THRESHOLD)
		if trigger_index == -1:
			continue
		
		if attacks_this_turn < artifact.attack_threshold:
			continue
		
		if trigger_index < artifact.effects.size():
			var effect = artifact.effects[trigger_index]
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт сработал: %s" % artifact.get_localized_name())
			SignalManager.artifact_triggered.emit(artifact)
			
			# Сбрасываем счётчик после активации
			attacks_this_turn = 0


func process_artifact_on_damage_threshold(damage_taken: int) -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	for artifact in artifacts:
		var trigger_index = artifact.triggers.find(DataManager.ArtifactTrigger.DAMAGE_THRESHOLD)
		if trigger_index == -1:
			continue
		
		# Проверяем порог
		if damage_taken < artifact.damage_threshold:
			continue
		
		if trigger_index < artifact.effects.size():
			var effect = artifact.effects[trigger_index]
			EffectExecutor.execute(effect, player, [player])
			SignalManager.log_message.emit("Артефакт сработал: %s" % artifact.get_localized_name())
			SignalManager.artifact_triggered.emit(artifact)
			
			# Проверяем, нужно ли удалить триггер
			# Если артефакт одноразовый — удаляем
			# Пока оставляем — срабатывает каждый раз при превышении порога


func reset_run_constants():
	# === Статусы ===
	poison_damage_per_stack = DataManager.POISON_BASE_DAMAGE_PER_STACK
	bleed_damage_per_stack = DataManager.BLEED_BASE_DAMAGE_PER_STACK
	burn_damage_per_stack = DataManager.BURN_BASE_DAMAGE_PER_STACK
	burn_threshold_stacks = DataManager.BURN_THRESHOLD_STACKS
	# === Статусы (игрок) ===
	player_poison_damage_per_stack = DataManager.POISON_BASE_DAMAGE_PER_STACK
	player_bleed_damage_per_stack = DataManager.BLEED_BASE_DAMAGE_PER_STACK
	player_burn_damage_per_stack = DataManager.BURN_BASE_DAMAGE_PER_STACK
	player_regen_heal_per_stack = DataManager.REGEN_HEAL_PER_STACK
	
	# === Бонусы игрока (артефакты) ===
	player_bleed_duration_bonus = 0  # 🆕
	
	has_lucky_pick = false  # 🆕

	cold_freeze_threshold = DataManager.COLD_FREEZE_THRESHOLD
	cold_effect_percent = DataManager.COLD_EFFECT_PERCENT_PER_STACK
	cold_min_multiplier = DataManager.COLD_MIN_EFFECT_MULTIPLIER
	regen_heal_per_stack = DataManager.REGEN_HEAL_PER_STACK
	strength_bonus_per_stack = DataManager.STRENGTH_FLAT_BONUS_PER_STACK
	weakness_damage_multiplier = DataManager.WEAKNESS_DAMAGE_MULTIPLIER
	vulnerability_damage_multiplier = DataManager.VULNERABILITY_DAMAGE_MULTIPLIER
	poison_healing_reduction = DataManager.POISON_HEALING_REDUCTION
	shame_damage_taken_multiplier = DataManager.SHAME_DAMAGE_TAKEN_MULTIPLIER
	shame_atonement_multiplier = DataManager.SHAME_ATONEMENT_MULTIPLIER
	frozen_energy_loss = DataManager.FROZEN_ENERGY_LOSS
	infection_bleed_multiplier = DataManager.INFECTION_BLEED_MULTIPLIER
	# === Балансные константы ===
	starting_hand_size = DataManager.STARTING_HAND_SIZE
	cards_to_draw_per_turn = DataManager.CARDS_TO_DRAW_PER_TURN
	max_energy = DataManager.MAX_ENERGY
	
	# === Стартовые валюты ===
	starting_coins = DataManager.STARTING_COINS + 100
	starting_bones = DataManager.STARTING_BONES
	starting_keys = DataManager.STARTING_KEYS
	
	# === Ресурсы ===
	default_item_cost = DataManager.DEFAULT_ITEM_COST
	reward_gold_default = DataManager.REWARD_GOLD_DEFAULT
	reward_damage_default = DataManager.REWARD_DAMAGE_DEFAULT
	energy_buff_reward_amount = DataManager.ENERGY_BUFF_REWARD_AMOUNT
	rest_default_heal = DataManager.REST_DEFAULT_HEAL

	# === Взаимодействия статусов ===
	is_bleed_poison_interaction_enabled = false
	is_poison_burn_interaction_enabled = false
	is_bleed_cold_interaction_enabled = false

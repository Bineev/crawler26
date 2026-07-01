# executors/effect_executor.gd
extends Node

## ============================================================
## ГЛОБАЛЬНЫЙ ИСПОЛНИТЕЛЬ ЭФФЕКТОВ
## ============================================================
## Выполняет эффекты из карт, пассивок, статусов и т.д.
## Единая точка входа для всех эффектов в игре.
## Поддерживает:
## - вложенные эффекты (CONDITIONAL)
## - рост значений (grow_type, grow_target, grow_value)
## - масштабируемые значения (SCALED_VALUE) по tier ресурса
## - кастомные скрипты (CUSTOM)
## - модификаторы источника и цели
## - копии ресурсов для уникальных экземпляров
## - передачу контекста пассивки для счётчиков роста
## ============================================================


## Выполняет эффект
## @param effect: EffectEntry - выполняемый эффект
## @param source: Node - источник эффекта (кто применяет)
## @param targets: Array - список целей
## @param card_info: Dictionary - дополнительная информация (например, сожжённая карта)
## @param passive_context: PassiveResource - пассивка, из которой вызван эффект (опционально)
func execute(effect: EffectEntry, source: Node, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not effect:
		return
	
	if effect.has_growth():
		_apply_effect_growth(effect, passive_context)
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			_execute_damage(effect, source, targets)
		
		DataManager.EffectCategory.BLOCK:
			_execute_block(effect, source, targets)
		
		DataManager.EffectCategory.HEAL:
			_execute_heal(effect, source, targets)
		
		DataManager.EffectCategory.SCALED_VALUE:
			_execute_scaled_value(effect, source, targets)
		
		DataManager.EffectCategory.APPLY_STATUS:
			_execute_apply_status(effect, source, targets, passive_context)
		
		DataManager.EffectCategory.APPLY_PASSIVE:
			_execute_apply_passive(effect, source, targets)
		
		DataManager.EffectCategory.MODIFY_STAT:
			_execute_modify_stat(effect, source, targets)
		
		DataManager.EffectCategory.MODIFY_MODIFIER:
			_execute_modify_modifier(effect, source, targets)
		
		DataManager.EffectCategory.DRAW_CARD:
			_execute_draw_card(effect, source)
		
		DataManager.EffectCategory.GAIN_ENERGY:
			_execute_gain_energy(effect, source)
		
		DataManager.EffectCategory.SACRIFICE_CARD:
			_execute_sacrifice_card(effect, source, card_info)
		
		DataManager.EffectCategory.CONVERT:
			_execute_convert(effect, source, targets)
		
		DataManager.EffectCategory.CONVERT_EXCESS_TO_BLOCK:
			_execute_convert_excess_to_block(effect, source, targets)
			
		DataManager.EffectCategory.CONVERT_STATUS:
			_execute_convert_status(effect, source, targets)
		
		DataManager.EffectCategory.CONDITIONAL:
			_execute_conditional(effect, source, targets, card_info, passive_context)
		
		DataManager.EffectCategory.CUSTOM:
			_execute_custom(effect, source, targets, card_info, passive_context)
		
		_:
			printerr("Unknown effect category: ", effect.category)


## ============================================================
## ПРИВАТНЫЕ МЕТОДЫ ВЫПОЛНЕНИЯ
## ============================================================

func _execute_damage(effect: EffectEntry, source, targets: Array) -> void:
	var damage = effect.base_value
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source and source.has_method("get_stat"):
			var stat_value = source.get_stat(effect.stat_multiplier)
			damage += stat_value / effect.stat_divisor
	
	if source and source.has_method("get_strength_bonus"):
		damage += source.get_strength_bonus()
	
	if source and source.has_method("get_modifier"):
		damage += source.get_modifier(DataManager.ModifierStat.DAMAGE_FLAT_BONUS)
		damage *= source.get_modifier(DataManager.ModifierStat.DAMAGE_DEALT_PERCENT)
	
	for target in targets:
		if target and target.has_method("take_damage"):
			var final_damage = damage
			if target.has_method("get_modifier"):
				final_damage *= target.get_modifier(DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT)
			# Передаём source как атакующего
			target.take_damage(floor(final_damage), false, source)


func _execute_block(effect: EffectEntry, source, targets: Array) -> void:
	var block = effect.base_value
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source and source.has_method("get_flat"):
			block += source.get_flat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("add_block"):
			target.add_block(block)
			var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
			SignalManager.log_message.emit("%s получил %d блока" % [target_name, block])


func _execute_heal(effect: EffectEntry, source, targets: Array) -> void:
	var heal = effect.base_value
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			heal += source.get_stat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("heal"):
			target.heal(heal)
			var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
			SignalManager.log_message.emit("%s восстановил %d HP" % [target_name, heal])


func _execute_scaled_value(effect: EffectEntry, source, targets: Array) -> void:
	var resource_value = 0
	
	# Получаем значение ресурса
	match effect.scaled_resource:
		DataManager.ScaledResource.ATONEMENT:
			if source.has_method("get_flat"):
				resource_value = source.get_flat(DataManager.FlatStat.ATONEMENT)
			elif source.has_method("get_atonement"):
				resource_value = source.get_atonement()
		
		DataManager.ScaledResource.HEALTH:
			if source.has_method("get_health"):
				resource_value = source.get_health()
			elif source.has_method("get_flat"):
				resource_value = source.get_flat(DataManager.FlatStat.HEALTH)
		
		DataManager.ScaledResource.MAX_HEALTH:
			if source.has_method("get_max_health"):
				resource_value = source.get_max_health()
			elif source.has_method("get_flat"):
				resource_value = source.get_flat(DataManager.FlatStat.MAX_HEALTH)
		
		DataManager.ScaledResource.ENERGY:
			if source.has_method("get_energy"):
				resource_value = source.get_energy()
			elif source.has_method("get_flat"):
				resource_value = source.get_flat(DataManager.FlatStat.ENERGY)
		
		DataManager.ScaledResource.BLOCK:
			if source.has_method("get_block"):
				resource_value = source.get_block()
			elif source.has_method("get_status_stacks"):
				resource_value = source.get_status_stacks(DataManager.Status.SHIELD)
		
		DataManager.ScaledResource.ENEMY_STATUSES:
			var count = 0
			for target in targets:
				if target.has_method("get_applied_statuses"):
					count += target.get_applied_statuses().size()
				elif target.has_method("active_statuses"):
					count += target.active_statuses.keys().size()
			resource_value = count
		
		DataManager.ScaledResource.PLAYER_STATUSES:
			if source.has_method("get_applied_statuses"):
				resource_value = source.get_applied_statuses().size()
			elif source.has_method("active_statuses"):
				resource_value = source.active_statuses.keys().size()
		
		DataManager.ScaledResource.BURN_STACKS:
			if source.has_method("get_status_stacks"):
				resource_value = source.get_status_stacks(DataManager.Status.BURN)
		
		DataManager.ScaledResource.POISON_STACKS:
			if source.has_method("get_status_stacks"):
				resource_value = source.get_status_stacks(DataManager.Status.POISON)
		
		DataManager.ScaledResource.BLEED_STACKS:
			if source.has_method("get_status_stacks"):
				resource_value = source.get_status_stacks(DataManager.Status.BLEED)
		
		_:
			printerr("Unknown scaled_resource: ", effect.scaled_resource)
			return
	
	# Если нужно потратить ресурс
	if effect.scaled_spend_resource:
		_spend_scaled_resource(effect, source, resource_value)
	# Получаем значение по порогам
	var value = effect.get_scaled_value(resource_value)
	
	# Применяем эффект
	match effect.scaled_type:
		DataManager.ScaledType.DAMAGE:
			for target in targets:
				if target.has_method("take_damage"):
					target.take_damage(value)
					var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
					SignalManager.log_message.emit("%s получил %d урона (scaled)" % [target_name, value])
		
		DataManager.ScaledType.BLOCK:
			for target in targets:
				if target.has_method("add_block"):
					target.add_block(value)
					var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
					SignalManager.log_message.emit("%s получил %d блока (scaled)" % [target_name, value])
		
		DataManager.ScaledType.HEAL:
			for target in targets:
				if target.has_method("heal"):
					target.heal(value)
					var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
					SignalManager.log_message.emit("%s восстановил %d HP (scaled)" % [target_name, value])
		
		DataManager.ScaledType.GAIN_ENERGY:
			if source.has_method("gain_energy"):
				source.gain_energy(value)
				SignalManager.log_message.emit("Получено %d энергии (scaled)" % value)
		
		DataManager.ScaledType.DRAW_CARD:
			var battle_deck = BattleManager.get_battle_deck()
			if battle_deck:
				battle_deck.draw_cards(value, true)  # ignore_hand_limit = true
				SignalManager.log_message.emit("Добрано %d карт (scaled)" % value)
			else:
				printerr("BattleDeck not found for DRAW_CARD")
		
		DataManager.ScaledType.APPLY_STATUS:
			for target in targets:
				if target.has_method("add_status") and effect.status:
					target.add_status(effect.status, value, effect.duration, source)
					var target_name = target.get_display_name() if target.has_method("get_display_name") else "Цель"
					SignalManager.log_message.emit("%s получил статус %s: %d стаков (scaled)" % [target_name, effect.status.get_localized_name(), value])
		
		_:
			printerr("Unknown scaled_type: ", effect.scaled_type)


func _execute_apply_status(effect: EffectEntry, source, targets: Array, passive_context: PassiveResource = null) -> void:
	var value = effect.get_current_value()
	var duration = effect.get_current_duration()
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source and source.has_method("get_flat"):
			var stat_value = source.get_flat(effect.stat_multiplier)
			duration += stat_value / effect.stat_divisor
	
	for target in targets:
		if target and target.has_method("add_status"):
			target.add_status(effect.status, value, max(1, duration), source, passive_context)


func _execute_apply_passive(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("apply_passive"):
			var passive_copy = effect.passive.duplicate_for_instance() if effect.passive else null
			if passive_copy:
				passive_copy.init_instance()
			target.apply_passive(passive_copy, effect.passive_duration)


func _execute_modify_stat(effect: EffectEntry, source, targets: Array) -> void:
	var delta = effect.delta
	
	for target in targets:
		if target and target.has_method("modify_flat"):
			target.modify_flat(effect.target_stat, delta)


func _execute_modify_modifier(effect: EffectEntry, source, targets: Array) -> void:
	var delta = effect.delta_percent
	
	for target in targets:
		if target.has_method("modify_modifier"):
			target.modify_modifier(effect.target_modifier, delta, effect.modifier_duration)


func _execute_draw_card(effect: EffectEntry, source) -> void:
	var battle_deck = BattleManager.get_battle_deck()
	if battle_deck:
		battle_deck.draw_cards(effect.amount, true)


func _execute_gain_energy(effect: EffectEntry, source) -> void:
	if source and source.has_method("gain_energy"):
		source.gain_energy(effect.amount)
		SignalManager.log_message.emit("Получено %d энергии" % effect.amount)
	else:
		printerr("GAIN_ENERGY: source cannot gain energy!")


func _execute_convert(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		# Для CONVERT из ATONEMENT в SHIELD (или HEALTH)
		if effect.from_stat == DataManager.FlatStat.ATONEMENT:
			var value = target.get_flat(effect.from_stat)
			var converted = floor(value * effect.conversion_ratio)
			
			if effect.to_stat == DataManager.FlatStat.HEALTH:
				target.modify_flat(DataManager.FlatStat.HEALTH, converted)
			elif effect.to_stat == DataManager.FlatStat.ATONEMENT:
				target.modify_flat(DataManager.FlatStat.ATONEMENT, converted)
			# CONVERT_EXCESS_TO_BLOCK отдельноrted)


func _execute_convert_excess_to_block(effect: EffectEntry, source, targets: Array) -> void:
	if not source.has_method("get_flat") or not source.has_method("modify_flat"):
		return
	
	var current = source.get_flat(DataManager.FlatStat.ATONEMENT)
	var max_val = source.get_flat(DataManager.FlatStat.MAX_ATONEMENT)
	var excess = max(0, current - max_val)
	
	print("_execute_convert_excess_to_block: current=", current, " max_val=", max_val, " excess=", excess)  # ← отладка
	
	if excess > 0:
		source.modify_flat(DataManager.FlatStat.ATONEMENT, -excess)
		source.add_block(excess)
		print("Excess converted to block: ", excess)  # ← отладка


func _execute_conditional(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not effect.condition_script:
		return
	
	var condition_instance = effect.condition_script.new()
	var condition_met = condition_instance.check(source, targets)
	
	if condition_met and effect.true_effect:
		execute(effect.true_effect, source, targets, card_info, passive_context)
	elif not condition_met and effect.false_effect:
		execute(effect.false_effect, source, targets, card_info, passive_context)


func _execute_custom(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not effect.custom_script:
		printerr("CUSTOM effect has no custom_script")
		return
	
	var custom_instance = effect.custom_script.new()
	if custom_instance.has_method("apply"):
		custom_instance.apply(effect, source, targets, card_info, passive_context)
	else:
		printerr("CUSTOM script missing 'apply' method")


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func _apply_effect_growth(effect: EffectEntry, passive_context: PassiveResource = null) -> void:
	if not effect.has_growth():
		return
	
	if passive_context:
		var counter = passive_context.get_effect_counter(effect)
		effect.application_counter = counter
	
	effect.apply_growth()
	
	if passive_context:
		passive_context.increment_effect_counter(effect)


func _apply_growth_to_value(current_value: int, grow_type: int, grow_value: int) -> int:
	match grow_type:
		DataManager.GrowType.ADD:
			return current_value + grow_value
		DataManager.GrowType.SUBTRACT:
			return max(0, current_value - grow_value)
		DataManager.GrowType.MULTIPLY:
			return current_value * grow_value
		DataManager.GrowType.DIVIDE:
			return max(1, current_value / grow_value)
		_:
			return current_value


func _spend_scaled_resource(effect: EffectEntry, source, resource_value: int) -> void:
	match effect.scaled_resource:
		DataManager.ScaledResource.ATONEMENT:
			if source.has_method("modify_flat"):
				source.modify_flat(DataManager.FlatStat.ATONEMENT, -resource_value)
				SignalManager.log_message.emit("Потрачено %d Искупления" % resource_value)
		
		DataManager.ScaledResource.ENERGY:
			if source.has_method("modify_flat"):
				source.modify_flat(DataManager.FlatStat.ENERGY, -resource_value)
				SignalManager.log_message.emit("Потрачено %d энергии" % resource_value)
		
		DataManager.ScaledResource.HEALTH:
			if source.has_method("take_damage"):
				source.take_damage(resource_value)
				SignalManager.log_message.emit("Потрачено %d здоровья" % resource_value)
		
		DataManager.ScaledResource.MAX_HEALTH:
			if source.has_method("modify_flat"):
				source.modify_flat(DataManager.FlatStat.MAX_HEALTH, -resource_value)
				SignalManager.log_message.emit("Максимальное здоровье уменьшено на %d" % resource_value)
		
		DataManager.ScaledResource.BLOCK:
			# Блок — статус SHIELD
			if source.has_method("reduce_status_stacks"):
				var current_block = source.get_status_stacks(DataManager.Status.SHIELD)
				var to_spend = min(resource_value, current_block)
				source.reduce_status_stacks(DataManager.Status.SHIELD, to_spend)
				SignalManager.log_message.emit("Потрачено %d блока" % to_spend)
		_:
			printerr("Cannot spend resource: ", effect.scaled_resource)


func _execute_convert_status(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if not target.has_method("get_status_stacks") or not target.has_method("reduce_status_stacks"):
			continue
		
		var stacks = target.get_status_stacks(effect.convert_from_status)
		if stacks <= 0:
			continue
		
		var converted = floor(stacks * effect.convert_conversion_ratio)
		
		# Снимаем статус
		target.reduce_status_stacks(effect.convert_from_status, stacks)
		
		# Применяем к цели
		match effect.convert_to_stat:
			DataManager.FlatStat.HEALTH:
				# Лечение
				if target.has_method("heal"):
					target.heal(converted)
					var status_name = DataManager.get_status_name(effect.convert_from_status)
					SignalManager.log_message.emit("Конвертировано %d стаков %s в %d здоровья" % [stacks, status_name, converted])
			
			DataManager.FlatStat.ATONEMENT:
				if target.has_method("modify_flat"):
					target.modify_flat(DataManager.FlatStat.ATONEMENT, converted)
					var status_name = DataManager.get_status_name(effect.convert_from_status)
					SignalManager.log_message.emit("Конвертировано %d стаков %s в %d Искупления" % [stacks, status_name, converted])
			
			DataManager.FlatStat.ENERGY:
				if target.has_method("modify_flat"):
					target.modify_flat(DataManager.FlatStat.ENERGY, converted)
					var status_name = DataManager.get_status_name(effect.convert_from_status)
					SignalManager.log_message.emit("Конвертировано %d стаков %s в %d энергии" % [stacks, status_name, converted])
			
			DataManager.FlatStat.MAX_HEALTH:
				if target.has_method("modify_flat"):
					target.modify_flat(DataManager.FlatStat.MAX_HEALTH, converted)
					var status_name = DataManager.get_status_name(effect.convert_from_status)
					SignalManager.log_message.emit("Конвертировано %d стаков %s в %d максимального здоровья" % [stacks, status_name, converted])
			
			_:
				printerr("Unknown convert_to_stat: ", effect.convert_to_stat)


func _execute_sacrifice_card(effect: EffectEntry, source, card_info: Dictionary) -> void:
	var current_card_data = card_info.get("card_data")
	var current_card_ui = card_info.get("card")
	var amount_to_sacrifice = effect.amount  # сколько карт нужно сжечь
	
	var battle_deck = BattleManager.get_battle_deck()
	if not battle_deck:
		return
	
	var hand = battle_deck.get_hand()
	
	# Проверяем, что в руке достаточно карт:
	# нужно: текущая карта + amount_to_sacrifice других карт
	if hand.size() <= amount_to_sacrifice:
		SignalManager.log_message.emit("Нужно сжечь %d карт, но в руке недостаточно!" % amount_to_sacrifice)
		return
	
	# Собираем карты для сожжения (исключаем текущую)
	var available_cards = []
	for card in hand:
		if card != current_card_data:
			available_cards.append(card)
	
	if available_cards.size() < amount_to_sacrifice:
		SignalManager.log_message.emit("Недостаточно других карт для сожжения! Нужно: %d, доступно: %d" % [amount_to_sacrifice, available_cards.size()])
		return
	
	# Сжигаем amount_to_sacrifice случайных карт
	var cards_to_sacrifice = []
	for i in range(amount_to_sacrifice):
		var random_index = randi() % available_cards.size()
		var random_card = available_cards[random_index]
		cards_to_sacrifice.append(random_card)
		available_cards.remove_at(random_index)
	
	# Находим CardUI для каждой карты
	var card_uis_to_sacrifice = []
	var hand_ui = BattleManager.get_hand_ui()
	if hand_ui:
		var card_uis = hand_ui.get_card_uis()
		for card_data in cards_to_sacrifice:
			for ui in card_uis:
				if ui.card_data == card_data:
					card_uis_to_sacrifice.append(ui)
					break
	
	# Сжигаем все выбранные карты
	for i in range(cards_to_sacrifice.size()):
		var card_ui = card_uis_to_sacrifice[i] if i < card_uis_to_sacrifice.size() else null
		await battle_deck.sacrifice_card(card_ui, cards_to_sacrifice[i])

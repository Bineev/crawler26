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
	
	# Если эффект имеет рост, применяем его с учётом контекста пассивки
	if effect.has_growth():
		_apply_effect_growth(effect, passive_context)
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			_execute_damage(effect, source, targets)
		
		DataManager.EffectCategory.BLOCK:
			_execute_block(effect, source, targets)
		
		DataManager.EffectCategory.HEAL:
			_execute_heal(effect, source, targets)
		
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
		
		DataManager.EffectCategory.CONDITIONAL:
			_execute_conditional(effect, source, targets, card_info, passive_context)
		
		_:
			printerr("Unknown effect category: ", effect.category)


## ============================================================
## ПРИВАТНЫЕ МЕТОДЫ ВЫПОЛНЕНИЯ
## ============================================================

func _execute_damage(effect: EffectEntry, source, targets: Array) -> void:
	var damage = effect.base_value
	
	# Применяем множитель от стата (если указан)
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			var stat_value = source.get_stat(effect.stat_multiplier)
			damage += stat_value / effect.stat_divisor
	
	# Применяем модификаторы источника (Сила, +% урона)
	if source.has_method("get_modifier"):
		var flat_bonus = source.get_modifier(DataManager.ModifierStat.DAMAGE_FLAT_BONUS)
		damage += flat_bonus
		damage *= source.get_modifier(DataManager.ModifierStat.DAMAGE_DEALT_PERCENT)
	
	for target in targets:
		if target.has_method("take_damage"):
			var final_damage = damage
			# Применяем модификаторы цели (Уязвимость)
			if target.has_method("get_modifier"):
				final_damage *= target.get_modifier(DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT)
			target.take_damage(floor(final_damage))


func _execute_block(effect: EffectEntry, source, targets: Array) -> void:
	var block = effect.base_value
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			block += source.get_stat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("add_block"):
			target.add_block(block)


func _execute_heal(effect: EffectEntry, source, targets: Array) -> void:
	var heal = effect.base_value
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			heal += source.get_stat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("heal"):
			target.heal(heal)


func _execute_apply_status(effect: EffectEntry, source, targets: Array, passive_context: PassiveResource = null) -> void:
	var value = effect.get_current_value()
	var duration = effect.get_current_duration()
	
	# Применяем множитель от стата к длительности
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			duration += source.get_stat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("add_status"):
			target.add_status(effect.status, value, max(1, duration), passive_context)


func _execute_apply_passive(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("apply_passive"):
			# Создаём копию пассивки для цели
			var passive_copy = effect.passive.duplicate_for_instance() if effect.passive else null
			if passive_copy:
				passive_copy.init_instance()
			target.apply_passive(passive_copy, effect.passive_duration)


func _execute_modify_stat(effect: EffectEntry, source, targets: Array) -> void:
	var delta = effect.delta
	
	for target in targets:
		if target.has_method("modify_stat"):
			target.modify_stat(effect.target_stat, delta)


func _execute_modify_modifier(effect: EffectEntry, source, targets: Array) -> void:
	var delta = effect.delta_percent
	
	for target in targets:
		if target.has_method("modify_modifier"):
			target.modify_modifier(effect.target_modifier, delta, effect.modifier_duration)


func _execute_draw_card(effect: EffectEntry, source) -> void:
	if source.has_method("draw_cards"):
		source.draw_cards(effect.amount)


func _execute_gain_energy(effect: EffectEntry, source) -> void:
	if source.has_method("gain_energy"):
		source.gain_energy(effect.amount)


func _execute_sacrifice_card(effect: EffectEntry, source, card_info: Dictionary) -> void:
	if source.has_method("sacrifice_card") and card_info.has("card"):
		source.sacrifice_card(card_info["card"])


func _execute_convert(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("get_stat") and target.has_method("modify_stat"):
			var value = target.get_stat(effect.from_stat)
			target.modify_stat(effect.from_stat, -value)
			target.modify_stat(effect.to_stat, value)


func _execute_conditional(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not effect.condition_script:
		return
	
	var condition_instance = effect.condition_script.new()
	var condition_met = condition_instance.check(source, targets)
	
	if condition_met and effect.true_effect:
		execute(effect.true_effect, source, targets, card_info, passive_context)
	elif not condition_met and effect.false_effect:
		execute(effect.false_effect, source, targets, card_info, passive_context)


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

## Применяет рост эффекта с учётом контекста пассивки
func _apply_effect_growth(effect: EffectEntry, passive_context: PassiveResource = null) -> void:
	if not effect.has_growth():
		return
	
	# Если есть контекст пассивки, используем счётчик из неё
	if passive_context:
		var counter = passive_context.get_effect_counter(effect)
		effect.application_counter = counter
	
	# Применяем рост
	effect.apply_growth()
	
	# Обновляем счётчик в контексте
	if passive_context:
		passive_context.increment_effect_counter(effect)


## Применяет математическую операцию роста к значению
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

# executors/effect_executor.gd
extends Node

## ============================================================
## ГЛОБАЛЬНЫЙ ИСПОЛНИТЕЛЬ ЭФФЕКТОВ
## ============================================================
## Выполняет эффекты из карт, пассивок, статусов и т.д.
## Единая точка входа для всех эффектов в игре.
## ============================================================


## Выполняет эффект
## @param effect: EffectEntry - выполняемый эффект
## @param source: Node - источник эффекта (кто применяет, например, игрок или враг)
## @param targets: Array - список целей (можно передать одну цель как [target])
## @param card_info: Dictionary - дополнительная информация (например, сожжённая карта)
func execute(effect: EffectEntry, source: Node, targets: Array, card_info: Dictionary = {}) -> void:
	if not effect:
		return
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			_execute_damage(effect, source, targets)
		
		DataManager.EffectCategory.BLOCK:
			_execute_block(effect, source, targets)
		
		DataManager.EffectCategory.HEAL:
			_execute_heal(effect, source, targets)
		
		DataManager.EffectCategory.APPLY_STATUS:
			_execute_apply_status(effect, source, targets)
		
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
			_execute_conditional(effect, source, targets)
		
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
	
	# Применяем модификаторы источника (Сила, и т.д.)
	if source.has_method("get_modifier"):
		var flat_bonus = source.get_modifier(DataManager.ModifierStat.DAMAGE_FLAT_BONUS)
		damage += flat_bonus
		damage *= source.get_modifier(DataManager.ModifierStat.DAMAGE_DEALT_PERCENT)
	
	for target in targets:
		if target.has_method("take_damage"):
			var target_damage = damage
			# Применяем модификаторы цели (Уязвимость)
			if target.has_method("get_modifier"):
				target_damage *= target.get_modifier(DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT)
			target.take_damage(floor(target_damage))


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


func _execute_apply_status(effect: EffectEntry, source, targets: Array) -> void:
	var duration = effect.status_duration
	
	if effect.stat_multiplier != null and effect.stat_divisor > 0:
		if source.has_method("get_stat"):
			duration += source.get_stat(effect.stat_multiplier) / effect.stat_divisor
	
	for target in targets:
		if target.has_method("add_status"):
			target.add_status(effect.status, effect.stacks, max(1, duration))


func _execute_apply_passive(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("apply_passive"):
			target.apply_passive(effect.passive, effect.passive_duration)


func _execute_modify_stat(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("modify_stat"):
			target.modify_stat(effect.target_stat, effect.delta)


func _execute_modify_modifier(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("modify_modifier"):
			target.modify_modifier(effect.target_modifier, effect.delta_percent, effect.duration)


func _execute_draw_card(effect: EffectEntry, source) -> void:
	if source.has_method("draw_cards"):
		source.draw_cards(effect.amount)


func _execute_gain_energy(effect: EffectEntry, source) -> void:
	if source.has_method("gain_energy"):
		source.gain_energy(effect.amount)


func _execute_sacrifice_card(effect: EffectEntry, source, card_info: Dictionary) -> void:
	# Сжигаем карту (удаляем из колоды на этот забег)
	if source.has_method("sacrifice_card") and card_info.has("card"):
		source.sacrifice_card(card_info["card"])


func _execute_convert(effect: EffectEntry, source, targets: Array) -> void:
	for target in targets:
		if target.has_method("get_stat") and target.has_method("modify_stat"):
			var value = target.get_stat(effect.from_stat)
			target.modify_stat(effect.from_stat, -value)
			target.modify_stat(effect.to_stat, value)


func _execute_conditional(effect: EffectEntry, source, targets: Array) -> void:
	if not effect.condition_script:
		return
	
	# Создаём экземпляр скрипта условия
	var condition_instance = effect.condition_script.new()
	var condition_met = condition_instance.check(source, targets)
	
	if condition_met and effect.true_effect:
		execute(effect.true_effect, source, targets)
	elif not condition_met and effect.false_effect:
		execute(effect.false_effect, source, targets)

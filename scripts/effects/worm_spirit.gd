# scripts/card_effects/worm_spirit.gd
extends Resource
class_name WormSpiritEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var status_count = source.active_statuses.size()
	var passive_count = source.active_passives.size()
	var total_effects = status_count + passive_count
	
	var statuses_to_remove = source.active_statuses.keys()
	var passives_to_remove = source.active_passives.duplicate()
	
	for status_id in statuses_to_remove:
		source.remove_status(status_id)
	
	for passive in passives_to_remove:
		source.remove_passive(passive)
	
	var base_heal = effect.value
	var total_regen = base_heal + total_effects
	
	var regen_status = effect.status
	if regen_status:
		source.add_status(regen_status, total_regen, effect.duration, source)
		SignalManager.log_message.emit("Снято %d эффектов. Дух червя даёт Регенерацию %d на %d ходов." % [total_effects, total_regen, effect.duration])
	else:
		SignalManager.log_message.emit("Ошибка: статус Регенерации не найден!")

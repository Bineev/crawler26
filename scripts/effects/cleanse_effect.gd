# scripts/effects/cleanse_effect.gd
extends Resource
class_name CleanseEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	for target in targets:
		# Снимаем все статусы
		var statuses = target.active_statuses.keys()
		for status_id in statuses:
			target.remove_status(status_id)
		
		# Снимаем все пассивки
		var passives = target.active_passives.duplicate()
		for passive in passives:
			target.remove_passive(passive)
		
		SignalManager.log_message.emit("Все статусы и пассивки сняты!")

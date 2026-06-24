# scripts/card_effects/rotten_cut.gd
extends Resource
class_name RottenCutEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	for target in targets:
		if target.has_status(DataManager.Status.BLEED):
			var current_stacks = target.get_status_stacks(DataManager.Status.BLEED)
			target.reduce_status_stacks(DataManager.Status.BLEED, -current_stacks)  # удваиваем
			SignalManager.log_message.emit("Кровотечение на %s удвоено! (%d стаков)" % [target.get_display_name(), current_stacks * 2])
		else:
			SignalManager.log_message.emit("На %s нет Кровотечения для удвоения!" % target.get_display_name())

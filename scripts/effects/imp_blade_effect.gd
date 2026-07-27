extends Resource
class_name ImpBladeEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	RunManager.is_poison_burn_interaction_enabled = true
	SignalManager.log_message.emit("Клинок Импа: взаимодействие Яда и Горения активировано!")

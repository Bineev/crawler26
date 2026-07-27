extends Resource
class_name PlagueAmuletEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	RunManager.is_bleed_poison_interaction_enabled = true
	SignalManager.log_message.emit("Чумной амулет: взаимодействие Кровотечения и Яда активировано!")

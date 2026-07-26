extends Resource
class_name TrollBladeEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	RunManager.is_bleed_cold_interaction_enabled = true
	SignalManager.log_message.emit("Клинок троля: взаимодействие Кровотечения и Холода активировано!")

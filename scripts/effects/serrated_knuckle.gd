extends Node
class_name SerratedKnuckleEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	RunManager.player_bleed_duration_bonus += 1
	SignalManager.log_message.emit("Длительность Кровотечения увеличена на 1 (Зазубренный кастет)!")

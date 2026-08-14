extends Node
class_name LuckyPickEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	RunManager.has_lucky_pick = true
	SignalManager.log_message.emit("Счастливая отмычка! Взлом сундуков всегда удачен и приносит больше монет!")

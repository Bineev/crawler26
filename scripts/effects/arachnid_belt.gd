extends Node
class_name ArachnidBeltEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	# Увеличиваем урон от яда для игрока
	RunManager.player_poison_damage_per_stack += 1
	SignalManager.log_message.emit("Урон от яда увеличен на 1 (Паучий ремень)!")

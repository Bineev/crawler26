extends Node
class_name FatumEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	# Устанавливаем флаг игнорирования блока
	source.is_direct_ignore_shield = true
	SignalManager.log_message.emit("Фатум активирован! Атаки игнорируют блок в этом ходу.")

extends Node
class_name BitterVengeanceEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	if targets.is_empty():
		return
	
	var target = targets[0]
	if not is_instance_valid(target):
		return
	
	if not target.has_method("take_damage"):
		return
	
	# Получаем текущее количество Искупления у игрока
	var atonement = source.get_flat(DataManager.FlatStat.ATONEMENT)
	
	if atonement <= 0:
		SignalManager.log_message.emit("Нет Искупления для Горькой мести!")
		return
	
	# Наносим урон, равный количеству Искупления
	target.take_damage(atonement, false, source, true)
	SignalManager.log_message.emit("Горькая месть: нанесено %d урона!" % atonement)

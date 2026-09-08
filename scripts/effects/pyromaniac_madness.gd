extends Node
class_name PyromaniacMadness

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	if targets.is_empty():
		SignalManager.log_message.emit("Нет цели для Безумия пиромана!")
		return
	
	var target = targets[0]
	
	# 1. Накладываем Горючесть на себя
	var combustible_status = DataManager.get_status_resource(DataManager.Status.COMBUSTIBLE)
	if combustible_status:
		source.add_status(combustible_status, 1, 2, source)
		SignalManager.log_message.emit("Безумие пиромана: Горючесть наложена на себя!")
	
	# 2. Накладываем Горючесть на цель
	if combustible_status and is_instance_valid(target):
		target.add_status(combustible_status, 1, 2, source)
		SignalManager.log_message.emit("Безумие пиромана: Горючесть наложена на цель!")
	
	# 3. Удваиваем стаки Горения на цели
	if is_instance_valid(target) and target.has_method("has_status") and target.has_status(DataManager.Status.BURN):
		var current_burn_stacks = target.get_status_stacks(DataManager.Status.BURN)
		if current_burn_stacks > 0:
			# Удваиваем стаки
			var new_stacks = current_burn_stacks * 2
			target.modify_status_stacks(DataManager.Status.BURN, new_stacks - current_burn_stacks)
			SignalManager.log_message.emit("Безумие пиромана: Горение удвоено до %d стаков!" % new_stacks)
	else:
		SignalManager.log_message.emit("На цели нет Горения для удвоения.")

extends Node
class_name HealByPoisonDuration

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	var target = targets[0]
	
	# Проверяем, есть ли у цели активные статусы
	if not target.has_method("active_statuses"):
		return
	
	# Получаем длительность POISON
	var poison_duration = 0
	if target.active_statuses.has(DataManager.Status.POISON):
		poison_duration = target.active_statuses[DataManager.Status.POISON].duration
	
	if poison_duration <= 0:
		SignalManager.log_message.emit("Благословение гнили: нет яда для преобразования")
		return
	
	# Запоминаем длительность
	var heal_amount = poison_duration
	
	# Снимаем яд
	target.remove_status(DataManager.Status.POISON)
	
	# Лечим
	if target.has_method("heal"):
		target.heal(heal_amount)
		SignalManager.log_message.emit("Благословение гнили: восстановлено %d здоровья" % heal_amount)

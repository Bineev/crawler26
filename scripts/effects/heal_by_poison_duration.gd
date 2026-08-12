extends Node
class_name HealByPoisonDuration

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	var target = targets[0]
	if not is_instance_valid(target) or not target.has_method("remove_status") or not target.has_method("heal"):
		return
	
	# Проверяем наличие POISON через словарь
	var poison_duration = 0
	if target.active_statuses.has(DataManager.Status.POISON):
		poison_duration = target.active_statuses[DataManager.Status.POISON].duration
	
	if poison_duration <= 0:
		SignalManager.log_message.emit("Благословение гнили: нет яда для преобразования")
		return
	
	var heal_amount = poison_duration
	
	# Снимаем яд
	target.remove_status(DataManager.Status.POISON)
	
	# Лечим
	target.heal(heal_amount)
	SignalManager.log_message.emit("Благословение гнили: восстановлено %d здоровья" % heal_amount)

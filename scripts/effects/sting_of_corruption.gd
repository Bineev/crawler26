extends Node
class_name StingOfCorruption

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	var target = targets[0]
	if not target or not target.has_method("take_damage"):
		return
	
	if not source or not source.has_method("remove_status"):
		return
	
	var total_poison_duration = 0
	
	# 🔹 1. Собираем POISON со всех врагов
	var enemies = BattleManager.get_enemies()
	for enemy in enemies:
		if not enemy.is_alive():
			continue
		
		# Проверяем наличие POISON через словарь
		if enemy.active_statuses.has(DataManager.Status.POISON):
			var duration = enemy.active_statuses[DataManager.Status.POISON].duration
			total_poison_duration += duration
			enemy.remove_status(DataManager.Status.POISON)
	
	# 🔹 2. Собираем POISON с себя
	if source.active_statuses.has(DataManager.Status.POISON):
		var duration = source.active_statuses[DataManager.Status.POISON].duration
		total_poison_duration += duration
		source.remove_status(DataManager.Status.POISON)
	
	# 🔹 3. Наносим урон, если есть что
	if total_poison_duration > 0:
		target.take_damage(total_poison_duration)
		SignalManager.log_message.emit("Укол скверны: нанесено %d урона" % total_poison_duration)
	else:
		SignalManager.log_message.emit("Нет яда для поглощения")

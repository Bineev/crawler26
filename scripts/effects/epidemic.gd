extends Node
class_name Epidemic

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	# Выбранный враг (цель)
	var target_enemy = targets[0]
	if not target_enemy or not target_enemy.has_method("active_statuses"):
		return
	
	# Получаем всех врагов в комнате
	var all_enemies = BattleManager.get_enemies()
	if all_enemies.is_empty():
		return
	
	# Проверяем, есть ли у цели статусы
	var statuses_to_transfer = []
	for status_id in target_enemy.active_statuses.keys():
		# Пропускаем SHIELD (он сбрасывается в конце хода)
		if status_id == DataManager.Status.SHIELD:
			continue
		
		var status_data = target_enemy.active_statuses[status_id]
		statuses_to_transfer.append({
			"id": status_id,
			"stacks": status_data.stacks,
			"duration": status_data.duration,
			"resource": status_data.resource
		})
	
	if statuses_to_transfer.is_empty():
		SignalManager.log_message.emit("Нет статусов для распространения")
		return
	
	# Переносим статусы на остальных врагов (кроме цели)
	var spread_count = 0
	for enemy in all_enemies:
		# Пропускаем цель
		if enemy == target_enemy:
			continue
		
		if not enemy.is_alive():
			continue
		
		for status_info in statuses_to_transfer:
			var status_resource = status_info["resource"]
			var stacks = status_info["stacks"]
			var duration = status_info["duration"]
			
			# Если статус не стакается — стаки всегда 1
			if not status_resource.is_stacking:
				stacks = 1
			
			enemy.add_status(status_resource, stacks, duration, source)
			spread_count += 1
		
		SignalManager.log_message.emit("Статусы распространены на %s" % enemy.get_display_name())
	
	if spread_count > 0:
		# 🆕 Снимаем статусы с исходной цели
		for status_info in statuses_to_transfer:
			target_enemy.remove_status(status_info["id"])
		
		SignalManager.log_message.emit("Эпидемия: статусы перенесены на %d врагов" % (spread_count / len(statuses_to_transfer)))
	else:
		SignalManager.log_message.emit("Нет целей для распространения")

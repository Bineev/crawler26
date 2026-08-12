func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	var target_enemy = targets[0]
	if not target_enemy or not target_enemy.has_method("remove_status") or not target_enemy.has_method("add_status"):
		return
	
	var all_enemies = BattleManager.get_enemies()
	if all_enemies.is_empty():
		return
	
	# Проверяем наличие статусов у цели через словарь
	if target_enemy.active_statuses.is_empty():
		SignalManager.log_message.emit("Нет статусов для распространения")
		return
	
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
	
	# Распространяем статусы на других врагов (цель сохраняет статусы)
	var enemies_affected = 0
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue
		
		if enemy == target_enemy:
			continue
		
		if not enemy.is_alive():
			continue
		
		enemies_affected += 1
		for status_info in statuses_to_transfer:
			var status_resource = status_info["resource"]
			var stacks = status_info["stacks"]
			var duration = status_info["duration"]
			
			# Если статус не стакается — стаки всегда 1
			if not status_resource.is_stacking:
				stacks = 1
			
			enemy.add_status(status_resource, stacks, duration, source)
		
		SignalManager.log_message.emit("Статусы распространены на %s" % enemy.get_display_name())
	
	if enemies_affected > 0:
		SignalManager.log_message.emit("Эпидемия: статусы распространены на %d врагов" % enemies_affected)
	else:
		SignalManager.log_message.emit("Нет целей для распространения")

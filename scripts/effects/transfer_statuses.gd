extends Node
class_name TransferStatuses

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if targets.is_empty():
		return
	
	var target = targets[0]
	if not is_instance_valid(source) or not is_instance_valid(target):
		return
	
	if not source.has_method("remove_status") or not target.has_method("add_status"):
		return
	
	# Проверяем наличие статусов через словарь
	if source.active_statuses.is_empty():
		SignalManager.log_message.emit("Нет статусов для переноса")
		return
	
	var statuses_to_transfer = []
	for status_id in source.active_statuses.keys():
		# Пропускаем SHIELD (он сбрасывается в конце хода)
		if status_id == DataManager.Status.SHIELD:
			continue
		
		var status_data = source.active_statuses[status_id]
		statuses_to_transfer.append({
			"id": status_id,
			"stacks": status_data.stacks,
			"duration": status_data.duration,
			"resource": status_data.resource
		})
	
	if statuses_to_transfer.is_empty():
		SignalManager.log_message.emit("Нет статусов для переноса")
		return
	
	# Переносим статусы на цель
	for status_info in statuses_to_transfer:
		var status_resource = status_info["resource"]
		var stacks = status_info["stacks"]
		var duration = status_info["duration"]
		
		# Если статус не стакается — стаки всегда 1
		if not status_resource.is_stacking:
			stacks = 1
		
		if is_instance_valid(target) and target.has_method("add_status"):
			target.add_status(status_resource, stacks, duration, source)
			SignalManager.log_message.emit("Перенесён статус: %s (%d стаков, %d ходов)" % [status_resource.get_localized_name(), stacks, duration])
		
		# Снимаем статус с источника
		if is_instance_valid(source) and source.has_method("remove_status"):
			source.remove_status(status_info["id"])
	
	SignalManager.log_message.emit("Все статусы перенесены на цель!")

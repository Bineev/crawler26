extends Node
class_name ScorchedEarth

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	if targets.is_empty():
		SignalManager.log_message.emit("Нет цели для Выженной земли!")
		return
	
	var target = targets[0]
	if not target.has_method("add_status"):
		return
	
	# 1. Собираем всех живых существ в комнате (игрок + враги)
	var all_creatures: Array = []
	
	# Добавляем игрока
	var player = BattleManager.get_player()
	if is_instance_valid(player) and player.is_alive():
		all_creatures.append(player)
	
	# Добавляем всех живых врагов
	var enemies = BattleManager.get_enemies()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			all_creatures.append(enemy)
	
	# 2. Считаем общее количество статусов (не пассивок!)
	var total_statuses = 0
	for creature in all_creatures:
		if creature.has_method("get_applied_statuses"):
			total_statuses += creature.get_applied_statuses().size()
	
	if total_statuses == 0:
		SignalManager.log_message.emit("Нет статусов для сжигания!")
		return
	
	# 3. Снимаем все статусы со всех существ (НЕ трогаем пассивки!)
	for creature in all_creatures:
		# active_statuses — это переменная, а не метод
		if creature is CharacterStats and creature.active_statuses:
			var statuses = creature.active_statuses.keys().duplicate()
			for status_id in statuses:
				creature.remove_status(status_id)
	
	# 4. Накладываем Горение на цель (стаки = количество статусов × 3)
	var burn_stacks = total_statuses * 3
	var burn_status = DataManager.get_status_resource(DataManager.Status.BURN)
	if burn_status:
		target.add_status(burn_status, burn_stacks, 3, source)
		SignalManager.log_message.emit("Выженная земля: сожжено %d статусов, наложено %d Горения!" % [total_statuses, burn_stacks])
	else:
		printerr("Burn status not found!")

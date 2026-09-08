extends Node
class_name AshesOfWar

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
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
	
	# 2. Собираем все стаки Горения со всех существ
	var total_burn_stacks = 0
	
	for creature in all_creatures:
		if creature.has_method("has_status") and creature.has_status(DataManager.Status.BURN):
			var stacks = creature.get_status_stacks(DataManager.Status.BURN)
			if stacks > 0:
				total_burn_stacks += stacks
				# Снимаем Горение с существа
				creature.remove_status(DataManager.Status.BURN)
				SignalManager.log_message.emit("Поглощено %d стаков Горения с %s" % [stacks, creature.get_display_name() if creature.has_method("get_display_name") else "существа"])
	
	if total_burn_stacks == 0:
		SignalManager.log_message.emit("Нет Горения для поглощения!")
		return
	
	# 3. Накладываем щит равный количеству поглощённых стаков
	source.add_block(total_burn_stacks)
	SignalManager.log_message.emit("Пепел войны: поглощено %d стаков Горения, получено %d щита!" % [total_burn_stacks, total_burn_stacks])

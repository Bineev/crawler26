extends Node
class_name BlessingOfRot

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	var player = source
	if not player.has_method("get_health") or not player.has_method("heal"):
		return
	
	# 1. Собираем весь яд в комнате
	var total_poison_duration = 0
	var targets_to_cleanse = []
	
	# Добавляем игрока
	if player.active_statuses.has(DataManager.Status.POISON):
		total_poison_duration += player.active_statuses[DataManager.Status.POISON].duration
		targets_to_cleanse.append(player)
	
	# Добавляем всех врагов
	var enemies = BattleManager.get_enemies()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			if enemy.active_statuses.has(DataManager.Status.POISON):
				total_poison_duration += enemy.active_statuses[DataManager.Status.POISON].duration
				targets_to_cleanse.append(enemy)
	
	# 2. Если яда нет — ничего не делаем
	if total_poison_duration <= 0:
		SignalManager.log_message.emit("Благословение гнили: нет яда для преобразования")
		return
	
	# 3. Снимаем яд со всех целей
	for target in targets_to_cleanse:
		if is_instance_valid(target) and target.has_method("remove_status"):
			target.remove_status(DataManager.Status.POISON)
	
	# 4. Лечим игрока на суммарную длительность
	player.heal(total_poison_duration)
	SignalManager.log_message.emit("Благословение гнили: поглощено %d яда, восстановлено %d здоровья" % [total_poison_duration, total_poison_duration])

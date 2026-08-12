extends Node
class_name GrantDenialByEnemyCount

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not source:
		return
	
	if not source.has_method("apply_passive"):
		return
	
	# Получаем всех живых врагов
	var enemies = BattleManager.get_enemies()
	var alive_count = 0
	for enemy in enemies:
		if enemy.is_alive():
			alive_count += 1
	
	if alive_count == 0:
		SignalManager.log_message.emit("Нет врагов для получения Denial")
		return
	
	# Загружаем Denial пассивку
	var denial_resource = load("res://resources/passives/denial.tres")
	if not denial_resource:
		printerr("Denial passive not found!")
		return
	
	# Применяем Denial с количеством зарядов = количество врагов
	var denial_instance = denial_resource.duplicate_for_instance()
	denial_instance.init_instance()
	denial_instance.current_charges = alive_count
	
	source.apply_passive(denial_instance)
	
	SignalManager.log_message.emit("Получен Denial (%d зарядов) за %d врагов" % [alive_count, alive_count])

extends Node
class_name FlameRitual

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	# 1. Накладываем Flame Barrier на себя
	var flame_barrier_passive = DataManager.get_passive_resource(DataManager.Passive.FLAME_BARRIER)
	if flame_barrier_passive:
		var passive_instance = flame_barrier_passive.duplicate_for_instance()
		passive_instance.init_instance()
		source.apply_passive(passive_instance)
		SignalManager.log_message.emit("Пламенный обряд: Flame Barrier активирован!")
	else:
		printerr("Flame Barrier passive not found!")
	
	# 2. Считаем врагов с Горением
	var enemies = BattleManager.get_enemies()
	var burning_enemies = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive() and enemy.has_status(DataManager.Status.BURN):
			burning_enemies += 1
	
	if burning_enemies == 0:
		SignalManager.log_message.emit("Нет врагов с Горением!")
		return
	
	# 3. Даём 2 силы за каждого врага с Горением
	var strength_stacks = burning_enemies * 2
	var strength_status = DataManager.get_status_resource(DataManager.Status.STRENGTH)
	if strength_status:
		source.add_status(strength_status, strength_stacks, 1, source)
		SignalManager.log_message.emit("Пламенный обряд: %d Силы получено (за %d врагов с Горением)!" % [strength_stacks, burning_enemies])
	else:
		printerr("Strength status not found!")

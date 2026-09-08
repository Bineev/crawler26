extends Node
class_name RandomBurst

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	# 50% шанс
	var is_self = randf() < 0.5
	
	if is_self:
		# Урон себе
		source.take_damage(10, false, source, true)
		SignalManager.log_message.emit("Случайная вспышка: урон нанесён себе!")
	else:
		# Урон всем врагам
		var enemies = BattleManager.get_enemies()
		var enemies_hit = 0
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive():
				enemy.take_damage(10, false, source, true)
				enemies_hit += 1
		
		if enemies_hit > 0:
			SignalManager.log_message.emit("Случайная вспышка: урон нанесён %d врагам!" % enemies_hit)
		else:
			SignalManager.log_message.emit("Нет живых врагов для атаки!")

extends Node
class_name TimeToDieEffect

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	var damage = DataManager.TIME_TO_DIE_DAMAGE
	var heal_per_kill = DataManager.TIME_TO_DIE_HEAL_PER_KILL
	
	# 1. Получаем всех врагов
	var enemies = BattleManager.get_enemies()
	
	# 2. Считаем живых врагов ДО
	var alive_before = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			alive_before += 1
	
	# 3. Наносим урон ВСЕМ ВРАГАМ
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			enemy.take_damage(damage, false, source, true)
	
	# 4. Наносим урон СЕБЕ (игроку)
	if is_instance_valid(source) and source.has_method("take_damage"):
		source.take_damage(damage, false, source, true)
	
	# 5. Ждём, пока урон применится
	await Engine.get_main_loop().create_timer(0.5).timeout
	
	# 6. Проверяем, жив ли игрок
	if not is_instance_valid(source):
		SignalManager.log_message.emit("Время умирать: вы погибли!")
		return
	
	if not source.has_method("is_alive") or not source.is_alive():
		SignalManager.log_message.emit("Время умирать: вы погибли!")
		return
	
	# 7. Считаем живых врагов ПОСЛЕ
	enemies = BattleManager.get_enemies()
	var alive_after = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			alive_after += 1
	
	# 8. Вычисляем количество убитых
	var killed = alive_before - alive_after
	
	# 9. Лечимся за каждого убитого
	if killed > 0:
		var heal_amount = killed * heal_per_kill
		if is_instance_valid(source) and source.has_method("heal"):
			source.heal(heal_amount)
			SignalManager.log_message.emit("Время умирать: %d врагов убито, восстановлено %d HP!" % [killed, heal_amount])
	else:
		SignalManager.log_message.emit("Время умирать: никто не погиб, вы получили урон!")

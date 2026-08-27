extends Node
class_name BlindVengeance

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	# Получаем текущее Искупление
	var atonement = 0
	if source.has_method("get_atonement"):
		atonement = source.get_atonement()
	elif source.has_method("get_flat"):
		atonement = source.get_flat(DataManager.FlatStat.ATONEMENT)
	else:
		return
	
	# Если Искупления меньше 10 — ничего не происходит
	if atonement < 10:
		SignalManager.log_message.emit("Недостаточно Искупления для Слепой расплаты! (нужно 10)")
		return
	
	# Количество ударов: за каждые 10 Искупления
	var hits = floor(atonement / 10.0)
	hits = min(hits, 10)
	
	var damage_per_hit = 5
	var cost_per_hit = 10
	
	# Получаем живых врагов
	var alive_enemies = _get_alive_enemies()
	
	if alive_enemies.is_empty():
		SignalManager.log_message.emit("Нет живых врагов для Слепой расплаты!")
		return
	
	var total_damage = 0
	var atonement_spent = 0
	var successful_hits = 0
	
	for i in range(hits):
		# Обновляем список живых врагов перед каждым ударом
		alive_enemies = _get_alive_enemies()
		
		if alive_enemies.is_empty():
			break
		
		# Проверяем, хватает ли Искупления для удара
		var current_atonement = 0
		if source.has_method("get_atonement"):
			current_atonement = source.get_atonement()
		elif source.has_method("get_flat"):
			current_atonement = source.get_flat(DataManager.FlatStat.ATONEMENT)
		
		if current_atonement < cost_per_hit:
			break
		
		# Выбираем случайного живого врага
		var target = alive_enemies[randi() % alive_enemies.size()]
		
		# Проверяем, жив ли враг (дополнительная страховка)
		if not is_instance_valid(target) or not target.is_alive():
			# Пропускаем этот удар, но продолжаем цикл — враг мог умереть между проверками
			continue
		
		# Тратим 10 Искупления за удар
		if source.has_method("modify_flat"):
			source.modify_flat(DataManager.FlatStat.ATONEMENT, -cost_per_hit)
			atonement_spent += cost_per_hit
		
		# Наносим урон
		target.take_damage(damage_per_hit, false, source, true)
		total_damage += damage_per_hit
		successful_hits += 1
		
		# Небольшая задержка между ударами для визуального эффекта
		await Engine.get_main_loop().create_timer(0.15).timeout
	
	# Лог результата
	if successful_hits > 0:
		SignalManager.log_message.emit("Слепая расплата: %d ударов по %d урона, потрачено %d Искупления" % [successful_hits, damage_per_hit, atonement_spent])
	else:
		SignalManager.log_message.emit("Слепая расплата не нанесла урона")


func _get_alive_enemies() -> Array:
	var result = []
	var enemies = BattleManager.get_enemies()
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			result.append(enemy)
	return result

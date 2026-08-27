extends Node
class_name GripOfDespair

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	if targets.is_empty():
		SignalManager.log_message.emit("Нет цели для Хватки отчаяния!")
		return
	
	var target = targets[0]
	
	# Проверяем, что цель — враг
	if not target is EnemyInstance:
		SignalManager.log_message.emit("Хватка отчаяния может быть применена только к врагу!")
		return
	
	if not is_instance_valid(target) or not target.is_alive():
		SignalManager.log_message.emit("Цель уже мертва!")
		return
	
	# Сохраняем здоровье до удара
	var health_before = target.get_health()
	
	# Наносим 10 урона (прямой, НЕ игнорирует блок)
	target.take_damage(10, false, source, true)
	
	# Небольшая задержка для визуального эффекта
	await Engine.get_main_loop().create_timer(0.2).timeout
	
	# Проверяем, жив ли враг после удара
	if not is_instance_valid(target) or not target.is_alive():
		# Враг мёртв — даём 20 Искупления
		if source.has_method("modify_flat"):
			source.modify_flat(DataManager.FlatStat.ATONEMENT, 20)
			SignalManager.log_message.emit("Хватка отчаяния добила врага! +20 Искупления")
		elif source.has_method("gain_atonement"):
			source.gain_atonement(20)
			SignalManager.log_message.emit("Хватка отчаяния добила врага! +20 Искупления")
	else:
		# Враг выжил
		SignalManager.log_message.emit("Хватка отчаяния нанесла 10 урона, но враг выжил")

extends Resource
class_name BlisterExplosionEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	# Получаем данные о пузыре из source
	var status_data = source.active_statuses.get(DataManager.Status.BLISTER)
	if not status_data or not status_data.has("blister_data"):
		return
	
	var blister_data = status_data["blister_data"]
	var current_health = blister_data.current_health
	
	if current_health > 0:
		# Пузырь лопается — наносит урон ВСЕМ в комнате (игрок + враги)
		var damage = current_health
		SignalManager.log_message.emit("Чёрный пузырь лопнул! %d урона всем в комнате!" % damage)
		
		var all_targets: Array = []
		var enemies = BattleManager.get_enemies()
		for enemy in enemies:
			if is_instance_valid(enemy) and enemy.is_alive():
				all_targets.append(enemy)
		
		var player = BattleManager.get_player()
		if is_instance_valid(player) and player.is_alive():
			all_targets.append(player)
		
		for target in all_targets:
			if is_instance_valid(target):
				target.take_damage(damage, true)
	
	# Удаляем статус
	source.remove_status(DataManager.Status.BLISTER)

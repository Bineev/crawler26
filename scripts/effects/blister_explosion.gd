# scripts/effects/blister_explosion.gd
extends Resource
class_name BlisterExplosionEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	# Получаем данные из эффекта
	var current_health = effect.value
	var burn_amount = effect.base_value
	var burn_stacks_on_create = effect.amount
	
	# Проверяем, был ли пузырь сбит до тика
	var status_data = source.active_statuses.get(DataManager.Status.BLISTER)
	if status_data and status_data.has("blister_data"):
		var blister_data = status_data["blister_data"]
		current_health = blister_data.current_health
		burn_amount = blister_data.burn_stacks_on_create * blister_data.poison_duration_on_create
	
	if current_health > 0:
		# Пузырь лопается — наносит урон всем в комнате
		var damage = current_health
		SignalManager.log_message.emit("Чёрный пузырь лопнул! %d урона всем!" % damage)
		
		var all_targets = BattleManager.get_enemies()
		var player = BattleManager.get_player()
		if player:
			all_targets.append(player)
		for target in all_targets:
			if is_instance_valid(target) and target != source:
				target.take_damage(damage, true)
	else:
		# Пузырь уже был сбит — накладываем BURN
		if burn_amount > 0:
			var burn_status = DataManager.get_status_resource(DataManager.Status.BURN)
			var is_player = source is PenitentStats
			var targets_to_burn: Array = []
			
			if is_player:
				targets_to_burn = [source]  # игрок получает BURN
			else:
				targets_to_burn = BattleManager.get_enemies()  # враги получают BURN
			
			for target in targets_to_burn:
				if is_instance_valid(target):
					target.add_status(burn_status, burn_amount, 2, source)
			
			SignalManager.log_message.emit("Чёрный пузырь сбит! %d стаков Горения наложено!" % burn_amount)

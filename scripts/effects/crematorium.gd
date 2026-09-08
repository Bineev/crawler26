extends Node
class_name Crematorium

func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary = {}, passive_context: PassiveResource = null) -> void:
	if not is_instance_valid(source):
		return
	
	var burn_status = DataManager.get_status_resource(DataManager.Status.BURN)
	if not burn_status:
		printerr("Burn status not found!")
		return
	
	var burn_stacks = 4
	var burn_duration = 2
	
	# 1. Накладываем Горение на игрока
	var player = BattleManager.get_player()
	if is_instance_valid(player) and player.is_alive():
		player.add_status(burn_status, burn_stacks, burn_duration, source)
		SignalManager.log_message.emit("Крематорий: на игрока наложено %d Горения на %d хода" % [burn_stacks, burn_duration])
	
	# 2. Накладываем Горение на всех живых врагов
	var enemies = BattleManager.get_enemies()
	var enemies_affected = 0
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_alive():
			enemy.add_status(burn_status, burn_stacks, burn_duration, source)
			enemies_affected += 1
	
	if enemies_affected > 0:
		SignalManager.log_message.emit("Крематорий: на %d врагов наложено %d Горения на %d хода" % [enemies_affected, burn_stacks, burn_duration])

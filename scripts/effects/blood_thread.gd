# scripts/card_effects/blood_thread.gd
extends Resource
class_name BloodThreadEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var enemies = BattleManager.get_enemies()
	var alive_enemies = enemies.filter(func(e): return e.is_alive())
	var enemy_count = alive_enemies.size()
	
	if enemy_count == 0:
		SignalManager.log_message.emit("Нет живых врагов для получения Силы!")
		return
	
	var strength_per_enemy = 3
	var total_strength = enemy_count * strength_per_enemy
	
	var strength_status = DataManager.get_status_resource(DataManager.Status.STRENGTH)
	if strength_status:
		source.add_status(strength_status, total_strength, 0, source)
		SignalManager.log_message.emit("Кровавые нити дают %d Силы (%d врагов × 3)" % [total_strength, enemy_count])

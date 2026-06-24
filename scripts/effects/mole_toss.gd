# scripts/card_effects/mole_toss.gd
extends Resource
class_name MoleTossEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var max_damage = effect.base_value  # берём из эффекта
	var damage = randi() % max_damage + 1  # от 1 до max_damage
	
	for target in targets:
		target.take_damage(damage, false, source)
		SignalManager.log_message.emit("Бросок слепыша нанёс %d урона!" % damage)

# scripts/card_effects/mole_toss.gd
extends Resource
class_name MoleTossEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var max_damage = effect.base_value
	var damage = randi() % max_damage + 1
	
	# 🆕 Создаём эффект урона
	var damage_effect = EffectEntry.new()
	damage_effect.category = DataManager.EffectCategory.DAMAGE
	damage_effect.target = DataManager.EffectTarget.ENEMY
	damage_effect.base_value = damage
	
	# Выполняем через EffectExecutor
	EffectExecutor.execute(damage_effect, source, targets, card_info, passive_context)

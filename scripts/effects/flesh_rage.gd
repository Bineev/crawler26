# scripts/card_effects/flesh_rage.gd
extends Resource
class_name FleshRageEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var has_bleed = source.has_status(DataManager.Status.BLEED)
	
	if has_bleed:
		source.modify_flat(DataManager.FlatStat.ENERGY, 1)
		SignalManager.log_message.emit("Ярость плоти: кровотечение даёт +1 энергию!")
	else:
		var battle_deck = BattleManager.get_battle_deck()
		if battle_deck:
			battle_deck.draw_cards(1, false)
			SignalManager.log_message.emit("Ярость плоти: нет кровотечения — добор 1 карты.")

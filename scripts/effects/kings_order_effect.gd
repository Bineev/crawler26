# scripts/effects/kings_order_effect.gd
extends Resource
class_name KingsOrderEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	# Устанавливаем флаг, что следующая карта нанесёт двойной урон
	# Можно использовать глобальную переменную в BattleManager или SignalManager
	#BUG (срабатывает на любой урон)
	BattleManager.set_next_card_damage_multiplier(2.0)
	SignalManager.log_message.emit("Приказ короля: следующая карта нанесёт двойной урон!")

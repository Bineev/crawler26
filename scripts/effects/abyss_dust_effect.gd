# scripts/effects/abyss_dust_effect.gd
extends Resource
class_name AbyssDustEffect

static func apply(effect: EffectEntry, source, targets: Array, card_info: Dictionary, passive_context: PassiveResource = null):
	var deck_data = RunManager.get_player_deck()
	if not deck_data:
		SignalManager.log_message.emit("Ошибка: колода не найдена!")
		return
	
	var master_cards = deck_data.master_cards
	if master_cards.is_empty():
		SignalManager.log_message.emit("Колода пуста!")
		return
	
	# 🆕 Собираем карты, у которых стоимость > 0
	var valid_cards: Array[CardData] = []
	for card in master_cards:
		if card.cost > 0:
			valid_cards.append(card)
	
	if valid_cards.is_empty():
		SignalManager.log_message.emit("Нет карт со стоимостью > 0! Пыль бездны не сработала.")
		return
	
	# Выбираем случайную карту из отфильтрованного списка
	var random_card = valid_cards[randi() % valid_cards.size()]
	
	# Устанавливаем стоимость в 0
	random_card.cost = 0
	
	SignalManager.log_message.emit("Пыль бездны: стоимость карты '%s' стала равна 0!" % random_card.get_localized_name())

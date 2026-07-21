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
	
	# Собираем карты, у которых стоимость > 0
	var valid_cards: Array[CardData] = []
	for card in master_cards:
		if card.cost > 0:
			valid_cards.append(card)
	
	if valid_cards.is_empty():
		SignalManager.log_message.emit("Нет карт со стоимостью > 0! Пыль бездны не сработала.")
		return
	
	# Выбираем случайную карту из отфильтрованного списка
	var random_card = valid_cards[randi() % valid_cards.size()]
	
	# 🆕 Создаём копию карты
	var new_card = random_card.duplicate_for_instance()
	new_card.cost = 0
	
	# 🆕 Находим индекс оригинальной карты
	var index = master_cards.find(random_card)
	if index != -1:
		# 🆕 Заменяем оригинальную карту на копию
		master_cards[index] = new_card
		
		SignalManager.log_message.emit("Пыль бездны: стоимость карты '%s' стала равна 0!" % random_card.get_localized_name())
	else:
		SignalManager.log_message.emit("Ошибка: карта не найдена в колоде!")

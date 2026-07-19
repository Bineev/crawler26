# scripts/deck/battle_deck.gd
extends Node
class_name BattleDeck

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var hand_ui: HandUI = null
var card_ui_scene: PackedScene = preload("res://scenes/card.tscn")


func initialize(cards: Array[CardData]):
	draw_pile = cards.duplicate()
	hand.clear()
	discard_pile.clear()
	shuffle_draw_pile()


func shuffle_draw_pile():
	draw_pile.shuffle()


func draw_initial_hand():
	# Раздаём карты без анимации
	for i in range(BattleManager.get_player().get_flat(DataManager.FlatStat.HAND_SIZE)):
		draw_card_silent()
	
	# После раздачи применяем layout с анимацией
	if hand_ui:
		hand_ui.apply_layout(true)
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.CARD_DRAW))
		


func draw_card(ignore_hand_limit: bool = false) -> bool:
	if not ignore_hand_limit and hand.size() >= BattleManager.get_player().get_flat(DataManager.FlatStat.HAND_SIZE):
		return false
	
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		reshuffle_discard_into_draw()
	
	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	SignalManager.log_message.emit("Добрана карта: %s" % card_data.get_localized_name())
	
	SignalManager.card_drawn.emit(card_data)
	
	# Добавляем карту без перестроения
	if hand_ui:
		hand_ui.add_card_silent(card_data, card_ui_scene)
		# Перестраиваем все карты с анимацией
		hand_ui.rearrange_cards_with_animation()
	
	SignalManager.deck_size_changed.emit(draw_pile.size())
	return true


func reshuffle_discard_into_draw():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_draw_pile()
	SignalManager.deck_size_changed.emit(draw_pile.size())
	SignalManager.discard_size_changed.emit(discard_pile.size())


func start_turn():
	draw_initial_hand()


func discard_card(card_ui: CardUI, card_data: CardData):
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
		discard_pile.append(card_data)
		SignalManager.card_discarded.emit(card_data)
		
		if hand_ui:
			hand_ui.remove_card(card_ui)
		
		SignalManager.discard_size_changed.emit(discard_pile.size())


func discard_hand():
	# Анимируем улёт карт
	if hand_ui:
		hand_ui.fly_hand_away()
	
	# Перемещаем карты в сброс (без ожидания)
	for card_data in hand:
		discard_pile.append(card_data)
		SignalManager.card_discarded.emit(card_data)
	
	hand.clear()
	
	SignalManager.discard_size_changed.emit(discard_pile.size())
	print("Hand discarded, discard pile size: ", discard_pile.size())


func draw_new_hand():
	if hand_ui:
		hand_ui.clear_hand()
	
	hand.clear()
	
	# Добавляем все карты (без анимации)
	for i in range(BattleManager.get_player().get_flat(DataManager.FlatStat.HAND_SIZE)):
		draw_card_silent()
	
	# Применяем layout с анимацией после раздачи
	if hand_ui:
		hand_ui.apply_layout(true)


func play_card(card_ui: CardUI, card_data: CardData, target = null):
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
	
	if card_data.has_tag(DataManager.CardTag.BURNS):
		card_ui.queue_free()
		return
	
	discard_pile.append(card_data)
	SignalManager.card_discarded.emit(card_data)
	SignalManager.discard_size_changed.emit(discard_pile.size())
	
	if hand_ui:
		hand_ui.remove_card(card_ui)


func sacrifice_card(card_ui: CardUI, card_data: CardData):
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
		
		if card_ui:
			card_ui.state = DataManager.CardState.BURNED
			# Перемещаем в burn контейнер
			if hand_ui:
				hand_ui.move_card_to_burn(card_ui)
			card_ui.play_burn_animation()
		else:
			pass
		
		print("Card sacrificed: ", card_data.get_localized_name())
		
		# Перестраиваем руку после сжигания
		if hand_ui:
			hand_ui.layout_cards()
	

func draw_cards(amount: int, ignore_hand_limit: bool = false):
	var drawn = 0
	for i in range(amount):
		if draw_card(ignore_hand_limit):
			drawn += 1
		else:
			break
	print("Drawn ", drawn, " cards")


func get_hand() -> Array[CardData]:
	return hand


func draw_card_without_layout() -> bool:
	if hand.size() >= BattleManager.get_player().get_flat(DataManager.FlatStat.HAND_SIZE):
		return false
	
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		reshuffle_discard_into_draw()
	
	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	
	SignalManager.card_drawn.emit(card_data)
	
	if hand_ui:
		hand_ui.add_card(card_data, card_ui_scene)
	
	SignalManager.deck_size_changed.emit(draw_pile.size())
	return true


func draw_card_silent() -> bool:
	if hand.size() >= BattleManager.get_player().get_flat(DataManager.FlatStat.HAND_SIZE):
		return false
	
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		reshuffle_discard_into_draw()
	
	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	
	SignalManager.card_drawn.emit(card_data)
	
	# Добавляем карту в UI без вызова layout
	if hand_ui:
		hand_ui.add_card_silent(card_data, card_ui_scene)
	
	SignalManager.deck_size_changed.emit(draw_pile.size())
	return true

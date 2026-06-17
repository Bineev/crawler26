# scripts/deck/battle_deck.gd
extends Node
class_name BattleDeck

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []

var max_hand_size: int = DataManager.MAX_HAND_SIZE
var cards_to_draw_per_turn: int = DataManager.CARDS_TO_DRAW_PER_TURN

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
	for i in range(max_hand_size):
		draw_card()


func draw_card(ignore_hand_limit: bool = false) -> bool:
	if not ignore_hand_limit and hand.size() >= max_hand_size:
		return false
	
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		reshuffle_discard_into_draw()
	
	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	SignalManager.log_message.emit("Добрана карта: %s" % card_data.get_localized_name())
	
	SignalManager.card_drawn.emit(card_data)
	
	# Отрисовываем одну карту
	if hand_ui:
		hand_ui.add_card(card_data, card_ui_scene)
	
	SignalManager.deck_size_changed.emit(draw_pile.size())
	return true


func reshuffle_discard_into_draw():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_draw_pile()
	SignalManager.deck_size_changed.emit(draw_pile.size())
	SignalManager.discard_size_changed.emit(discard_pile.size())


func start_turn():
	for i in range(cards_to_draw_per_turn):
		draw_card()


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
	for card_data in hand:
		discard_pile.append(card_data)
		SignalManager.card_discarded.emit(card_data)
	hand.clear()
	
	if hand_ui:
		hand_ui.clear_hand()
	
	SignalManager.discard_size_changed.emit(discard_pile.size())
	print("Hand discarded, discard pile size: ", discard_pile.size())


func draw_new_hand():
	# Очищаем UI
	if hand_ui:
		hand_ui.clear_hand()
	
	# Очищаем массив
	hand.clear()
	
	# Добираем карты
	for i in range(max_hand_size):
		draw_card()
	
	print("New hand drawn, hand size: ", hand.size())


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
			card_ui.state = DataManager.CardState.BURNED  # помечаем как сожжённую
			await card_ui.play_burn_animation()
		else:
			queue_free()
		
		SignalManager.card_discarded.emit(card_data)
	


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

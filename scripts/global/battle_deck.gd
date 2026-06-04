# scripts/deck/battle_deck.gd
extends Node

## ============================================================
## СИГНАЛЫ
## ============================================================

signal hand_updated(hand: Array[CardData])
signal deck_size_changed(size: int)
signal discard_size_changed(size: int)
signal card_drawn(card: CardData)
signal card_discarded(card: CardData)


## ============================================================
## ТРИ ОСНОВНЫЕ ЗОНЫ
## ============================================================

var draw_pile: Array[CardData] = []   # колода добора
var hand: Array[CardData] = []        # рука
var discard_pile: Array[CardData] = [] # сброс


## ============================================================
## ПАРАМЕТРЫ
## ============================================================

var max_hand_size: int = DataManager.MAX_HAND_SIZE
var cards_to_draw_per_turn: int = DataManager.CARDS_TO_DRAW_PER_TURN


## ============================================================
## ССЫЛКИ НА UI
## ============================================================

var hand_ui: HandUI = null
var card_ui_scene: PackedScene = preload("res://scenes/card.tscn")


## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

## Инициализация копией мастер-колоды
func initialize(cards: Array[CardData]):
	draw_pile = cards.duplicate()
	hand.clear()
	discard_pile.clear()
	shuffle_draw_pile()
	draw_initial_hand()


## Перемешать колоду добора
func shuffle_draw_pile():
	draw_pile.shuffle()


## Начальная рука
func draw_initial_hand():
	for i in range(max_hand_size):
		draw_card()


## ============================================================
## ДОБОР КАРТ
## ============================================================

## Добор одной карты
func draw_card() -> bool:
	if hand.size() >= max_hand_size:
		return false
	
	# Если колода добора пуста, перемешиваем сброс
	if draw_pile.is_empty():
		if discard_pile.is_empty():
			return false
		reshuffle_discard_into_draw()
	
	var card_data = draw_pile.pop_front()
	hand.append(card_data)
	card_drawn.emit(card_data)
	
	# Обновляем UI руки
	if hand_ui:
		hand_ui.update_hand(hand, card_ui_scene)
	
	deck_size_changed.emit(draw_pile.size())
	return true


## Перемешать сброс в колоду добора
func reshuffle_discard_into_draw():
	draw_pile = discard_pile.duplicate()
	discard_pile.clear()
	shuffle_draw_pile()
	deck_size_changed.emit(draw_pile.size())
	discard_size_changed.emit(discard_pile.size())


## Начать новый ход (добор карт)
func start_turn():
	for i in range(cards_to_draw_per_turn):
		draw_card()


## ============================================================
## СБРОС КАРТ
## ============================================================

## Сбросить карту из руки в сброс
func discard_card(card_ui: CardUI, card_data: CardData):
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
		discard_pile.append(card_data)
		card_discarded.emit(card_data)
		
		if hand_ui:
			hand_ui.remove_card(card_ui)
		
		discard_size_changed.emit(discard_pile.size())


## Сбросить все карты из руки в конце хода
func discard_hand():
	for card_data in hand:
		discard_pile.append(card_data)
		card_discarded.emit(card_data)
	hand.clear()
	
	if hand_ui:
		hand_ui.clear_hand()
	
	discard_size_changed.emit(discard_pile.size())


## ============================================================
## РОЗЫГРЫШ КАРТЫ
## ============================================================

## Разыграть карту (карта уходит в сброс после использования)
func play_card(card_ui: CardUI, card_data: CardData, target = null):
	# Удаляем из руки
	var index = hand.find(card_data)
	if index != -1:
		hand.remove_at(index)
	
	# Сгорающие карты не попадают в сброс
	if card_data.has_tag(DataManager.CardTag.BURNS):
		card_ui.queue_free()
		return
	
	# Обычные карты идут в сброс
	discard_pile.append(card_data)
	card_discarded.emit(card_data)
	discard_size_changed.emit(discard_pile.size())
	
	if hand_ui:
		hand_ui.remove_card(card_ui)


## ============================================================
## МАНИПУЛЯЦИИ С КОЛОДАМИ
## ============================================================

## Получить карты из сброса (для манипуляций)
func get_discard_pile() -> Array[CardData]:
	return discard_pile.duplicate()


## Получить карты из колоды добора (для манипуляций)
func get_draw_pile() -> Array[CardData]:
	return draw_pile.duplicate()


## Положить карту поверх колоды добора
func put_on_top_of_draw_pile(card_data: CardData):
	draw_pile.insert(0, card_data)
	deck_size_changed.emit(draw_pile.size())


## Положить карту в низ колоды добора
func put_on_bottom_of_draw_pile(card_data: CardData):
	draw_pile.append(card_data)
	deck_size_changed.emit(draw_pile.size())


## Добавить карту в сброс (например, извне)
func add_to_discard(card_data: CardData):
	discard_pile.append(card_data)
	discard_size_changed.emit(discard_pile.size())


## Добавить карту в колоду добора (замешивается)
func add_to_draw_pile(card_data: CardData, shuffle: bool = false):
	draw_pile.append(card_data)
	if shuffle:
		shuffle_draw_pile()
	deck_size_changed.emit(draw_pile.size())


## ============================================================
## ПРОВЕРКИ
## ============================================================

func is_empty() -> bool:
	return draw_pile.is_empty() and discard_pile.is_empty()


func get_total_card_count() -> int:
	return draw_pile.size() + hand.size() + discard_pile.size()

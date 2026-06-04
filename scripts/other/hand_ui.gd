# scripts/ui/hand_ui.gd
extends Control
class_name HandUI

## ============================================================
## КОНСТАНТЫ
## ============================================================

const CARD_SPACING: int = DataManager.CARD_SPACING
const CARD_BASE_WIDTH: int = DataManager.CARD_BASE_WIDTH
const CARD_BASE_HEIGHT: int = DataManager.CARD_BASE_HEIGHT
const CARD_SCALE_IN_HAND: float = DataManager.CARD_SCALE_IN_HAND

## Реальная ширина карты в руке (с учётом скейла)
var card_hand_width: int = int(CARD_BASE_WIDTH * CARD_SCALE_IN_HAND)


## ============================================================
## ССЫЛКИ НА НОДЫ
## ============================================================

## Контейнер для карт (HBoxContainer для простоты)
@onready var cards_container: HBoxContainer = %CardsContainer

## ============================================================
## ПЕРЕМЕННЫЕ СОСТОЯНИЯ
## ============================================================

var is_manual_layout: bool = true  # true = ручная раскладка веером, false = HBox


## ============================================================
## ОБНОВЛЕНИЕ РУКИ
## ============================================================

## Обновить руку
func update_hand(hand_cards: Array[CardData], card_scene: PackedScene):
	clear_hand()
	
	for card_data in hand_cards:
		var card_instance = card_scene.instantiate() as CardUI
		card_instance.card_data = card_data
		card_instance.display()
		card_instance.set_hand_scale()
		cards_container.add_child(card_instance)
	
	if is_manual_layout:
		layout_cards()


## ============================================================
## РАСКЛАДКА КАРТ
## ============================================================

## Ручная раскладка веером
func layout_cards():
	var card_count = cards_container.get_child_count()
	if card_count == 0:
		return
	
	var total_width = card_hand_width + CARD_SPACING * (card_count - 1)
	var start_x = (size.x - total_width) / 2
	
	for i in range(card_count):
		var card = cards_container.get_child(i)
		card.position = Vector2(start_x + i * CARD_SPACING, 0)
		
		# Веер (поворот)
		var angle = (i - (card_count - 1) / 2.0) * 0.1
		card.rotation = angle
		card.z_index = i


## HBox раскладка (простая)
func layout_hbox():
	# HBox автоматически раскладывает дочерние элементы
	pass


## ============================================================
## ОЧИСТКА И УДАЛЕНИЕ КАРТ
## ============================================================

## Очистить всю руку
func clear_hand():
	for child in cards_container.get_children():
		child.queue_free()


## Удалить конкретную карту из руки
func remove_card(card_ui: CardUI):
	card_ui.queue_free()
	if is_manual_layout:
		layout_cards()


## ============================================================
## ПОЛУЧЕНИЕ КАРТ
## ============================================================

## Получить все карты в руке
func get_cards_in_hand() -> Array[CardUI]:
	var result: Array[CardUI] = []
	for child in cards_container.get_children():
		if child is CardUI:
			result.append(child)
	return result


## Получить карту по индексу
func get_card_at_index(index: int) -> CardUI:
	if index >= 0 and index < cards_container.get_child_count():
		return cards_container.get_child(index) as CardUI
	return null


## ============================================================
## ВЗАИМОДЕЙСТВИЕ С КАРТАМИ
## ============================================================

## Блокировать все карты (во время анимаций)
func set_cards_interactive(interactive: bool):
	for child in cards_container.get_children():
		if child is CardUI:
			child.set_process_input(interactive)
			child.set_process_unhandled_input(interactive)


## Подсветить карту (например, при наведении эффекта)
func highlight_card(card: CardUI, highlight: bool):
	if highlight:
		card.modulate = Color(1.2, 1.2, 1.2)
	else:
		card.modulate = Color(1, 1, 1)


## ============================================================
## СБРОС ПОЗИЦИЙ
## ============================================================

## Сбросить позиции всех карт (после изменения размера окна)
func reset_positions():
	if is_manual_layout:
		layout_cards()

# scripts/ui/hand_ui.gd
extends Control
class_name HandUI

var cards_container: Node2D = null
var is_manual_layout: bool = true


func _ready():
	cards_container = $CardsContainer
	if not cards_container:
		print("ERROR: CardsContainer not found!")
	is_manual_layout = true


func clear_hand():
	if cards_container:
		for child in cards_container.get_children():
			child.queue_free()


func update_hand(hand_cards: Array[CardData], card_scene: PackedScene):
	clear_hand()
	
	for card_data in hand_cards:
		var card_instance = card_scene.instantiate() as CardUI
		cards_container.add_child(card_instance)
		card_instance.card_data = card_data
		card_instance.display()
		card_instance.set_hand_scale()
	
	if is_manual_layout:
		layout_cards()


func add_card(card_data: CardData, card_scene: PackedScene):
	var card_instance = card_scene.instantiate() as CardUI
	cards_container.add_child(card_instance)
	card_instance.card_data = card_data
	card_instance.display()
	card_instance.set_hand_scale()
	
	if is_manual_layout:
		layout_cards()


func remove_card(card_ui: CardUI):
	card_ui.queue_free()
	if is_manual_layout:
		layout_cards()


func layout_cards():
	var card_count = cards_container.get_child_count()
	if card_count == 0:
		return
	
	var card_width = DataManager.CARD_BASE_WIDTH * DataManager.CARD_SCALE_IN_HAND
	var card_height = DataManager.CARD_BASE_HEIGHT * DataManager.CARD_SCALE_IN_HAND
	var screen_size = get_viewport().get_visible_rect().size
	
	var total_width = card_width * card_count + DataManager.CARD_SPACING * (card_count - 1)
	var start_x = (screen_size.x - total_width) / 2
	var y_pos = screen_size.y - card_height - 50
	
	for i in range(card_count):
		var card = cards_container.get_child(i)
		var x_pos = start_x + i * (card_width + DataManager.CARD_SPACING)
		card.position = Vector2(x_pos, y_pos)
		
		var angle = (i - (card_count - 1) / 2.0) * 0.08
		card.rotation = angle
		card.z_index = i

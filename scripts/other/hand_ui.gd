# scripts/ui/hand_ui.gd
extends Control
class_name HandUI

var cards_container: Node2D = null
var is_manual_layout: bool = true

var is_selecting_target: bool = false
var current_card: CardUI = null
var target_arrow: Line2D = null
var current_hovered_card: CardUI = null

func _ready():
	cards_container = $CardsContainer
	if not cards_container:
		print("ERROR: CardsContainer not found!")
	is_manual_layout = true
	
	SignalManager.target_selection_requested.connect(_on_target_selection_requested)
	SignalManager.target_selected.connect(_on_target_selected)
	SignalManager.target_selection_cancelled.connect(_on_target_selection_cancelled)


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
		card_instance.set_hand_ui(self)
		card_instance.display()
		card_instance.set_hand_scale()
	
	if is_manual_layout:
		layout_cards()


func add_card(card_data: CardData, card_scene: PackedScene):
	var card_instance = card_scene.instantiate() as CardUI
	card_instance.set_hand_ui(self)
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
	
	var total_width = card_width * card_count + DataManager.CARD_SPACING_IN_HAND * (card_count - 1)
	var start_x = (screen_size.x - total_width) / 2
	var base_y = screen_size.y - card_height - DataManager.CARD_HAND_Y_OFFSET
	var arc_height = 40.0
	
	for i in range(card_count):
		var card = cards_container.get_child(i) as CardUI
		if not card:
			continue
		
		var x_pos = start_x + i * (card_width + DataManager.CARD_SPACING_IN_HAND)
		var t = float(i) / float(card_count - 1)
		var y_offset = -arc_height * (1.0 - abs(t * 2.0 - 1.0))
		var y_pos = base_y + y_offset
		
		card.position = Vector2(x_pos, y_pos)
		card.original_position = card.position
		card.original_z_index = i
		card.z_index = i
		card.rotation = 0


func _unhandled_input(event):
	if not is_selecting_target:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target = _get_target_at_position(get_viewport().get_mouse_position())
		if target:
			SignalManager.target_selected.emit(target)
		else:
			SignalManager.target_selection_cancelled.emit()
		accept_event()
	
	elif event is InputEventKey and event.key == KEY_ESCAPE and event.pressed:
		SignalManager.target_selection_cancelled.emit()
		accept_event()


func _on_target_selection_requested(card_ui: CardUI):
	current_card = card_ui
	is_selecting_target = true
	
	target_arrow = Line2D.new()
	target_arrow.width = 4
	target_arrow.default_color = Color(0.9, 0.3, 0.2, 0.8)
	target_arrow.antialiased = true
	add_child(target_arrow)


func _process(delta):
	if not is_selecting_target or not target_arrow or not current_card:
		return
	
	var card_pos = current_card.get_global_position()
	var mouse_pos = get_viewport().get_mouse_position()
	
	target_arrow.clear_points()
	target_arrow.add_point(card_pos)
	
	var mid_point = (card_pos + mouse_pos) / 2
	mid_point.y -= 50
	target_arrow.add_point(mid_point)
	target_arrow.add_point(mouse_pos)


func _get_target_at_position(pos: Vector2) -> Node:
	for enemy in BattleManager.get_enemies():
		if not enemy.is_alive():
			continue
		var enemy_ui = enemy.get_node("EnemyUI")
		if enemy_ui and enemy_ui.get_rect().has_point(enemy_ui.to_local(pos)):
			return enemy
	return null


func _on_target_selected(target: Node):
	is_selecting_target = false
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null
	
	if current_card:
		current_card.confirm_target(target)
		current_card = null


func _on_target_selection_cancelled():
	is_selecting_target = false
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null
	
	if current_card:
		current_card.cancel_selection()
		current_card = null


func set_all_cards_input_enabled(enabled: bool):
	for child in cards_container.get_children():
		var card = child as CardUI
		if card and card.card_control:
			card.card_control.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func try_set_hovered_card(card: CardUI) -> bool:
	print("try_set_hovered_card called for: ", card)
	print("current_hovered_card: ", current_hovered_card)
	
	if current_hovered_card == null or current_hovered_card == card:
		if current_hovered_card != card:
			print("Setting new hovered card")
			_set_all_cards_mouse_filter(Control.MOUSE_FILTER_IGNORE)
			if card.card_control:
				card.card_control.mouse_filter = Control.MOUSE_FILTER_PASS
		current_hovered_card = card
		return true
	
	print("Hover blocked by: ", current_hovered_card)
	return false


func clear_hovered_card(card: CardUI):
	if current_hovered_card == card:
		current_hovered_card = null
		_set_all_cards_mouse_filter(Control.MOUSE_FILTER_PASS)


func _set_all_cards_mouse_filter(filter: int):
	for child in cards_container.get_children():
		var card = child as CardUI
		if card and card.card_control:
			card.card_control.mouse_filter = filter

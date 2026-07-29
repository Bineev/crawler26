# scripts/ui/hand_ui.gd
extends Control
class_name HandUI

var cards_container: Node2D = null
var burn_container: Node2D = null
var is_manual_layout: bool = true
var is_aiming_mode: bool = false

var is_selecting_target: bool = false
var current_card: CardUI = null
var target_arrow: Line2D = null
var current_hovered_card: CardUI = null

var arrow_head: Sprite2D


func _ready():
	cards_container = $CardsContainer
	burn_container = $BurnContainer
	if not cards_container:
		print("ERROR: CardsContainer not found!")
	is_manual_layout = true
	
	SignalManager.target_selection_requested.connect(_on_target_selection_requested)
	SignalManager.target_selected.connect(_on_target_selected)
	SignalManager.target_selection_cancelled.connect(_on_target_selection_cancelled)
	SignalManager.enemy_clicked.connect(_on_enemy_clicked)


func clear_hand():
	if cards_container:
		# Используем remove_child вместо queue_free
		for child in cards_container.get_children():
			cards_container.remove_child(child)
			child.queue_free()
	
	# Сбрасываем состояние выбора цели
	is_selecting_target = false
	current_card = null
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null


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
	
	# Прячем карту за пределами экрана
	card_instance.position = Vector2(2200, 1200)
	card_instance._needs_appear_animation = true
	
	# Перестраиваем с анимацией
	apply_layout(true)


func remove_card(card_ui: CardUI):
	# Удаляем карту из контейнера
	if cards_container and card_ui.get_parent() == cards_container:
		cards_container.remove_child(card_ui)
		
		if is_manual_layout:
			layout_cards()

func layout_cards():
	var card_count = cards_container.get_child_count()
	print("layout_cards: card_count=", card_count)
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
		
		# 🆕 Защита от деления на ноль
		var t: float
		if card_count == 1:
			t = 0.5
		else:
			t = float(i) / float(card_count - 1)
		
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
	
	# Только ESCAPE для отмены
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		SignalManager.target_selection_cancelled.emit()
		accept_event()


func _on_target_selection_requested(card_ui: CardUI):
	is_aiming_mode = true
	current_card = card_ui
	is_selecting_target = true
	
	target_arrow = Line2D.new()
	target_arrow.width = 24 # Увеличили базовую ширину, так как сужение будет уменьшать её
	target_arrow.default_color = DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	target_arrow.antialiased = true
	SignalManager.selecting_target_changed.emit(true)
	# Настройка плавного сужения линии (от толстого начала к тонкому концу)
	var curve = Curve.new()
	curve.add_point(Vector2(0.0, 1.0)) # Начало у карты: 100% ширины
	curve.add_point(Vector2(1.0, 0.2)) # Конец у мыши: 20% ширины
	target_arrow.width_curve = curve
	
	add_child(target_arrow)


func _process(_delta):
	if not is_selecting_target or not target_arrow or not current_card:
		return
	
	# Центр карты
	var card_size = current_card.get_card_size()
	var card_center = current_card.global_position + card_size / 2
	
	var mouse_pos = get_global_mouse_position()
	
	target_arrow.clear_points()
	
	# Расчет контрольной точки для плавного изгиба (дуги)
	var mid_point = (card_center + mouse_pos) / 2
	mid_point.y -= 200  # Смещение вверх создает красивый прогиб дуги
	
	# Строим идеально ровную и сглаженную кривую из 30 сегментов
	var steps = 30
	for i in range(steps + 1):
		var t = float(i) / steps
		# Математическое сглаживание Безье между точками старта, изгиба и мыши
		var point = card_center.bezier_interpolate(mid_point, mid_point, mouse_pos, t)
		target_arrow.add_point(point)
	
	# Управляем наконечником стрелки
	_update_arrow_head(mouse_pos, target_arrow.get_point_position(steps - 1))



func _update_arrow_head(head_pos: Vector2, last_point_pos: Vector2):
	if not arrow_head:
		return
	arrow_head.global_position = head_pos
	# Разворачиваем наконечник по направлению движения
	arrow_head.rotation = (head_pos - last_point_pos).angle() + PI/2



func _on_target_selected(target: Node):
	is_aiming_mode = false
	is_selecting_target = false
	SignalManager.selecting_target_changed.emit(false)
	if target_arrow:
		target_arrow.queue_free()
		target_arrow = null
	
	if current_card:
		current_card.confirm_target(target)
		current_card = null


func _on_target_selection_cancelled():
	is_aiming_mode = false
	SignalManager.selecting_target_changed.emit(false)
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


func _on_enemy_clicked(enemy: EnemyInstance):
	if is_selecting_target:
		SignalManager.target_selected.emit(enemy)


func _on_selecting_target_changed(is_selecting: bool):
	is_aiming_mode = is_selecting
	if not is_selecting:
		SignalManager.enemy_highlight_requested.emit(self, false)


func get_card_uis() -> Array[CardUI]:
	var result: Array[CardUI] = []
	if cards_container:
		for child in cards_container.get_children():
			if child is CardUI:
				result.append(child)
	return result


func move_card_to_burn(card_ui: CardUI) -> void:
	if not burn_container or not card_ui:
		return
	
	# Сохраняем глобальную позицию карты
	var global_pos = card_ui.global_position
	
	# Перемещаем карту в burn_container
	cards_container.remove_child(card_ui)
	burn_container.add_child(card_ui)
	
	# Восстанавливаем позицию (сохраняем визуальное положение)
	card_ui.global_position = global_pos
	card_ui.z_index = 100


func apply_layout(animate: bool = true):
	var target_positions = _calculate_card_positions()
	var card_count = cards_container.get_child_count()
	
	if animate:
		for i in range(card_count):
			var card = cards_container.get_child(i) as CardUI
			if not card:
				continue
			
			var target_pos = target_positions[i] if i < target_positions.size() else Vector2.ZERO
			
			if card._needs_appear_animation:
				# Новая карта — прилетает с эффектом
				card._needs_appear_animation = false
				card.play_appear_animation(target_pos, i * 0.05)
			else:
				# Старая карта — плавно переезжает
				card.move_to_position(target_pos, i * 0.03)
	else:
		for i in range(card_count):
			var card = cards_container.get_child(i) as CardUI
			if not card:
				continue
			
			var target_pos = target_positions[i] if i < target_positions.size() else Vector2.ZERO
			card.position = target_pos
			card.original_position = target_pos


func _calculate_card_positions() -> Array[Vector2]:
	var card_count = cards_container.get_child_count()
	if card_count == 0:
		return []
	
	var positions: Array[Vector2] = []
	
	var card_width = DataManager.CARD_BASE_WIDTH * DataManager.CARD_SCALE_IN_HAND
	var card_height = DataManager.CARD_BASE_HEIGHT * DataManager.CARD_SCALE_IN_HAND
	var screen_size = get_viewport().get_visible_rect().size
	
	var total_width = card_width * card_count + DataManager.CARD_SPACING_IN_HAND * (card_count - 1)
	var start_x = (screen_size.x - total_width) / 2
	var base_y = screen_size.y - card_height - DataManager.CARD_HAND_Y_OFFSET
	var arc_height = 40.0
	
	for i in range(card_count):
		var x_pos = start_x + i * (card_width + DataManager.CARD_SPACING_IN_HAND)
		
		# 🆕 Если только одна карта — центрируем без дуги
		var t: float
		if card_count == 1:
			t = 0.5
		else:
			t = float(i) / float(card_count - 1)
		
		var y_offset = -arc_height * (1.0 - abs(t * 2.0 - 1.0))
		var y_pos = base_y + y_offset
		
		var target_position = Vector2(x_pos, y_pos)
		positions.append(target_position)
		
		# Обновляем оригинальные позиции карт
		var card = cards_container.get_child(i) as CardUI
		if card:
			card.original_position = target_position
			card.original_z_index = i
			card.z_index = i
	
	
	print("card_count: ", card_count)
	print("screen_size: ", screen_size)
	print("card_height: ", card_height)
	print("base_y: ", base_y)
	
	return positions


func add_card_silent(card_data: CardData, card_scene: PackedScene):
	var card_instance = card_scene.instantiate() as CardUI
	card_instance.set_hand_ui(self)
	cards_container.add_child(card_instance)
	card_instance.card_data = card_data
	card_instance.display()
	card_instance.set_hand_scale()
	
	# Прячем карту за пределами экрана
	card_instance.position = Vector2(2200, 1200)
	card_instance._needs_appear_animation = true


func rearrange_cards_with_animation():
	var card_count = cards_container.get_child_count()
	if card_count == 0:
		return
	
	# Сначала рассчитываем новые позиции
	var target_positions = _calculate_card_positions()
	
	# Обновляем original_position для всех карт
	for i in range(card_count):
		var card = cards_container.get_child(i) as CardUI
		if not card:
			continue
		
		var target_pos = target_positions[i] if i < target_positions.size() else Vector2.ZERO
		card.original_position = target_pos
		card.original_z_index = i
		card.z_index = i
	
	# Запускаем анимацию
	_animate_cards_to_positions()


func _animate_cards_to_positions():
	var children = cards_container.get_children()
	var card_count = children.size()
	if card_count == 0:
		return
	
	# Сначала прячем все карты
	for i in range(card_count):
		var card = children[i] as CardUI
		if card and not card._needs_appear_animation:
			card.modulate = Color(1, 1, 1, 0)
			card.position = card.original_position + Vector2(0, -30)
	
	await get_tree().process_frame
	
	# Обновляем список детей (на случай, если он изменился)
	children = cards_container.get_children()
	card_count = children.size()
	
	# Показываем и анимируем все карты
	for i in range(card_count):
		var card = children[i] as CardUI
		if not card:
			continue
		
		var delay = i * 0.04
		
		if card._needs_appear_animation:
			card._needs_appear_animation = false
			card.play_appear_animation(card.original_position, delay)
		else:
			card.modulate = Color(1, 1, 1, 1)
			card.move_to_position(card.original_position, delay)


func fly_hand_away() -> bool:
	if not cards_container:
		return false
	
	var children = cards_container.get_children()
	var card_count = children.size()
	
	if card_count == 0:
		return false
	
	for i in range(card_count):
		var card = children[i] as CardUI
		if card:
			var delay = i * 0.04
			card.fly_away_left(delay)
	
	# Возвращаем true, если карты были
	return true


func wait_for_fly_away():
	# Ждём, пока все карты улетят
	await get_tree().create_timer(0.5 + (cards_container.get_child_count() * 0.04)).timeout

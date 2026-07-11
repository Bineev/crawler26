extends Control
class_name ActionChoice

var actions: Array[DataManager.ActionType] = []
var action_data: Dictionary = {}  # дополнительные данные для действий
var context_object: Node = null  # 🆕 ссылка на объект, вызвавший действие

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var title_label: Label = $DarkOverlay/CenterContainer/VBoxContainer/Title
@onready var buttons_container: HBoxContainer = $DarkOverlay/CenterContainer/VBoxContainer/ButtonsContainer

func setup(title: String, actions_array: Array[DataManager.ActionType], context: Node = null, data: Dictionary = {}) -> void:
	actions = actions_array
	action_data = data
	context_object = context
	
	title_label.text = title
	_animate_in()
	_create_buttons()

func _create_buttons() -> void:
	for action in actions:
		var button = Button.new()
		button.text = _get_action_text(action)
		button.pressed.connect(_on_button_pressed.bind(action))
		
		button.add_theme_font_override("font", DataManager.FONT_HEADERS)
		button.add_theme_font_size_override("font_size", 20)
		button.custom_minimum_size = Vector2(150, 50)
		
		buttons_container.add_child(button)

func _get_action_text(action: DataManager.ActionType) -> String:
	match action:
		DataManager.ActionType.USE_KEY:
			return tr("action_use_key")
		DataManager.ActionType.BREAK:
			return tr("action_break")
		DataManager.ActionType.PRAY:
			return tr("action_pray")
		DataManager.ActionType.DRINK:
			return tr("action_drink")
		DataManager.ActionType.SEARCH:
			return tr("action_search")
		DataManager.ActionType.REST:
			return tr("action_rest")
		_:
			return ""

func _on_button_pressed(action: DataManager.ActionType) -> void:
	_handle_choice(action)

func _handle_choice(action: DataManager.ActionType) -> void:
	await _animate_transition_in()

	match action:
		DataManager.ActionType.USE_KEY:
			_handle_use_key()
		DataManager.ActionType.BREAK:
			_handle_break()
		DataManager.ActionType.PRAY:
			_handle_pray()
		DataManager.ActionType.DRINK:
			_handle_drink()
		DataManager.ActionType.SEARCH:
			_handle_search()
		DataManager.ActionType.REST:
			_handle_rest()
	#_animate_out()


func _handle_use_key() -> void:
	var success = RunManager.use_key()
	
	if success:
		await _show_result_label("СУНДУК ОТКРЫТ!", Color(0.2, 0.8, 0.2))
		SignalManager.log_message.emit("Ключ использован!")
		_create_rewards(true, DataManager.ActionType.USE_KEY)
	else:
		await _show_result_label("НЕТ КЛЮЧЕЙ!", Color(0.8, 0.2, 0.2))
		SignalManager.log_message.emit("Нет ключей!")
		_create_rewards(false, DataManager.ActionType.USE_KEY)


func _handle_break() -> void:
	var success = randf() < DataManager.CHEST_BREAK_CHANCE
	
	if success:
		await _show_result_label("УСПЕХ!", Color(0.2, 0.8, 0.2))
		SignalManager.log_message.emit("Сундук взломан!")
		_create_rewards(true, DataManager.ActionType.BREAK)
	else:
		await _show_result_label("НЕУДАЧА!", Color(0.8, 0.2, 0.2))
		SignalManager.log_message.emit("Взлом не удался!")
		_create_rewards(false, DataManager.ActionType.BREAK)


func _handle_pray() -> void:
	# TODO: молитва
	pass

func _handle_drink() -> void:
	# TODO: выпить
	pass

func _handle_search() -> void:
	# TODO: обыскать
	pass

func _handle_rest() -> void:
	# TODO: отдых
	pass

func _animate_in() -> void:
	dark_overlay.color.a = 0.0
	var tween = create_tween()
	await tween.tween_property(dark_overlay, "color:a",0.8, 1)

func _animate_out() -> void:
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.5)
	await tween.finished


func _create_rewards(success: bool, action: DataManager.ActionType) -> void:
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	
	reward_panel.reward_types = _generate_rewards(action, success)
	reward_panel.gold_mod = 1
	SignalManager.hide_object.emit()
	#await _animate_in()
	# 🆕 Отправляем сигнал через SignalManager
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _generate_rewards(action: DataManager.ActionType, success: bool) -> Array[DataManager.RewardType]:
	var rewards: Array[DataManager.RewardType] = []
	
	match action:
		DataManager.ActionType.USE_KEY:
			if success:
				# Ключ — всегда хорошие награды
				rewards.append(DataManager.RewardType.GOLD)
				rewards.append(DataManager.RewardType.CARD_BIOM)
				
				# Шанс на артефакт (20%)
				if randf() < 0.2:
					rewards.append(DataManager.RewardType.ARTIFACT)
			else:
				# Неудача с ключом — просто урон
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
		
		DataManager.ActionType.BREAK:
			if success:
				# Взлом — чуть хуже, чем ключ
				rewards.append(DataManager.RewardType.GOLD)
				
				# Шанс на карту (40%)
				if randf() < 0.4:
					rewards.append(DataManager.RewardType.CARD_BIOM)
				
				# Шанс на зелье (20%)
				if randf() < 0.2:
					rewards.append(DataManager.RewardType.POTION)
			else:
				# Неудача при взломе — урон + ловушка
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
		
		DataManager.ActionType.PRAY:
			# Молитва — лечение или благословение
			if success:
				rewards.append(DataManager.RewardType.GET_HEAL)
				if randf() < 0.3:
					rewards.append(DataManager.RewardType.ENERGY_BUFF)
			else:
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
		
		DataManager.ActionType.DRINK:
			# Питьё — зелье или яд
			if success:
				rewards.append(DataManager.RewardType.POTION)
				rewards.append(DataManager.RewardType.GET_HEAL)
			else:
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
		
		DataManager.ActionType.SEARCH:
			# Обыск — случайные находки
			if success:
				rewards.append(DataManager.RewardType.GOLD)
				if randf() < 0.5:
					rewards.append(DataManager.RewardType.CARD_BIOM)
				if randf() < 0.1:
					rewards.append(DataManager.RewardType.ARTIFACT)
			else:
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
		
		DataManager.ActionType.REST:
			# Отдых — всегда лечение
			if success:
				rewards.append(DataManager.RewardType.GET_HEAL)
				if randf() < 0.2:
					rewards.append(DataManager.RewardType.ENERGY_BUFF)
			else:
				rewards.append(DataManager.RewardType.TAKE_DAMAGE)
	
	return rewards


#func _on_rewards_finished() -> void:
	#_animate_out()
	## TODO: удалить объект сундука или отметить как открытый


func _animate_transition_in() -> void:
	# 🆕 Медленно исчезаем
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 0), 1)
	for button in buttons_container.get_children():
		tween.tween_property(button, "modulate", Color(1, 1, 1, 0), 1)
	
	tween.tween_property(dark_overlay, "color:a", 0.8, 1)
	await tween.finished


func _show_result_label(text: String, color: Color = Color.WHITE) -> void:
	var label = Label.new()
	label.text = text
	label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# 🆕 Растягиваем на весь размер родителя
	label.anchor_left = 0.0
	label.anchor_top = 0.0
	label.anchor_right = 1.0
	label.anchor_bottom = 1.0
	label.offset_left = 0
	label.offset_top = 0
	label.offset_right = 0
	label.offset_bottom = 0
	
	label.z_index = 10
	label.modulate = Color(1, 1, 1, 0)
	add_child(label)
	
	# Резко появляем
	label.modulate = Color(1, 1, 1, 1)
	
	# Медленно исчезаем в течение 2 секунд
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 0), 1.5)
	await tween.finished
	
	label.queue_free()

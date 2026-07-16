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
		DataManager.ActionType.SHARP_WEAPON:
			return tr("action_sharp_weapon")
		DataManager.ActionType.MAKE_OFFERING:
			return tr("action_make_offering")
		DataManager.ActionType.GIVE_BLOOD:
			return tr("action_give_blood")
		DataManager.ActionType.LOOT_SHRINE:
			return tr("action_loot_shrine")
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
		DataManager.ActionType.SHARP_WEAPON:
			_handle_sharp_weapon()
		DataManager.ActionType.MAKE_OFFERING:
			_handle_make_offering()
		DataManager.ActionType.GIVE_BLOOD:
			_handle_give_blood()
		DataManager.ActionType.LOOT_SHRINE:
			_handle_loot_shrine()

func _handle_use_key() -> void:
	var success = RunManager.use_key()
	
	if success:
		await _show_result_label("СУНДУК ОТКРЫТ!", DataManager.COLOR_HEAL_LOG)
		SignalManager.log_message.emit("Ключ использован!")
		_create_rewards(true, DataManager.ActionType.USE_KEY)
	else:
		await _show_result_label("НЕТ КЛЮЧЕЙ!", DataManager.COLOR_PENITENT_ART_BG_DARK)
		SignalManager.log_message.emit("Нет ключей!")
		_create_rewards(false, DataManager.ActionType.USE_KEY)


func _handle_break() -> void:
	var success = randf() < DataManager.CHEST_BREAK_CHANCE
	
	if success:
		await _show_result_label("УСПЕХ!", DataManager.COLOR_HEAL_LOG)
		SignalManager.log_message.emit("Сундук взломан!")
		_create_rewards(true, DataManager.ActionType.BREAK)
	else:
		await _show_result_label("НЕУДАЧА!", DataManager.COLOR_PENITENT_ART_BG_DARK)
		SignalManager.log_message.emit("Взлом не удался!")
		_create_rewards(false, DataManager.ActionType.BREAK)


func _handle_rest() -> void:
	await _show_result_label(tr("bonfire_rest_result"), DataManager.COLOR_HEAL_LOG)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = _generate_rewards(DataManager.ActionType.REST, true)
	reward_panel.heal_mod = 1
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()

func _handle_pray() -> void:
	await _show_result_label(tr("bonfire_pray_result"), DataManager.COLOR_HEAL_LOG)
	
	# TODO: добавить баф на 3 боевые комнаты (увеличение макс. энергии)
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = _generate_rewards(DataManager.ActionType.PRAY, true)
	reward_panel.buff_duration = DataManager.BONFIRE_ENERGY_BUFF_DURATION
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()

func _handle_sharp_weapon() -> void:
	await _show_result_label(tr("bonfire_sharp_result"), DataManager.COLOR_HEAL_LOG)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = _generate_rewards(DataManager.ActionType.SHARP_WEAPON, true)
	reward_panel.upgrade_count = 1  # 🆕 или любое другое количество
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()

func _handle_drink() -> void:
	# TODO: выпить
	pass

func _handle_search() -> void:
	# TODO: обыскать
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
				rewards.append(DataManager.RewardType.ENERGY_BUFF)
				
		DataManager.ActionType.SHARP_WEAPON:
			# Молитва — лечение или благословение
			if success:
				rewards.append(DataManager.RewardType.UPGRADE_CARD)
				
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
	label.add_theme_font_size_override("font_size", 60)
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


func _handle_make_offering() -> void:
	var bones = RunManager.get_bones()
	var rewards: Array[DataManager.RewardType] = []
	var gold_mod = 1
	
	if bones <= 10:
		# 5-10 костей: кость * 3 золота
		rewards.append(DataManager.RewardType.GOLD)
		gold_mod = 3
		await _show_result_label(tr("idol_offering_small"), DataManager.COLOR_HEAL_LOG)
	elif bones <= 20:
		# 11-20 костей: случайный артефакт + кость * 4 золота
		rewards.append(DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE)
		rewards.append(DataManager.RewardType.GOLD)
		gold_mod = 4
		await _show_result_label(tr("idol_offering_medium"), DataManager.COLOR_HEAL_LOG)
	else:
		# 20+ костей: артефакт на выбор + кость * 5 золота + бафф на +1 размер руки
		rewards.append(DataManager.RewardType.ARTIFACT)
		rewards.append(DataManager.RewardType.GOLD)
		rewards.append(DataManager.RewardType.DECK_SIZE_BUFF)
		gold_mod = 5
		await _show_result_label(tr("idol_offering_great"), DataManager.COLOR_HEAL_LOG)
	
	# Тратим все кости
	RunManager.spend_bones(bones)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	reward_panel.gold_mod = gold_mod
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_give_blood() -> void:
	await _show_result_label(tr("idol_blood_result"), DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	var player = BattleManager.get_player()
	var damage = DataManager.IDOL_DAMAGE
	
	if player:
		var current_health = player.get_health()
		if current_health - damage < 1:
			damage = current_health - 1
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.TAKE_DAMAGE, DataManager.RewardType.CARD_CHARACTER]
	reward_panel.damage_mod = damage  # передаём урон
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_loot_shrine() -> void:
	var success = randf() < DataManager.IDOL_BREAK_CHANCE
	var rewards: Array[DataManager.RewardType] = []
	var gold_mod : int = 1
	if success:
		await _show_result_label(tr("idol_loot_success"), DataManager.COLOR_HEAL_LOG)
		# Выбираем случайную награду из трёх
		var options = [
			DataManager.RewardType.CARD_WITHOUT_CHOICE,
			DataManager.RewardType.POTION,
			DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE
		]
		rewards = [options[randi() % options.size()]]
		rewards.append(DataManager.RewardType.GOLD)
		gold_mod = 3
	else:
		await _show_result_label(tr("idol_loot_fail"), DataManager.COLOR_PENITENT_ART_BG_DARK)
		rewards = [DataManager.RewardType.GOLD]
		gold_mod = 2
		# Дебафф через систему, как у Strange Mushroom
		RunManager.apply_idol_curse(FloorManager.current_biome, 3)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	reward_panel.gold_mod = gold_mod
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()

func _apply_biome_debuff() -> void:
	var player = BattleManager.get_player()
	if not player:
		return
	
	var biome = FloorManager.current_biome
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			var bleed_status = DataManager.get_status_resource(DataManager.Status.BLEED)
			if bleed_status:
				player.add_status(bleed_status, 2, 3, player)  # 2 стака на 3 хода
				SignalManager.log_message.emit("Вы получили проклятие: Кровотечение на 3 боя!")
		# TODO: другие биомы

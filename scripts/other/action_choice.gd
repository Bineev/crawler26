extends Control
class_name ActionChoice

var actions: Array[DataManager.ActionType] = []
var action_data: Dictionary = {}  # дополнительные данные для действий
var context_object: Node = null  # 🆕 ссылка на объект, вызвавший действие
var event_data: EventResource = null
var room_object: RoomObject = null

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
		var button = DataManager.create_button(_get_action_text(action), DataManager.ButtonType.PRIMARY)
		button.pressed.connect(_on_button_pressed.bind(action))
	
		
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
		DataManager.ActionType.TRANSFORM_CARD:
			return tr("action_transform_card")
		DataManager.ActionType.BREW_POTION:
			return tr("action_brew_potion")
		DataManager.ActionType.DISARM_TRAP:
			return tr("action_disarm_trap")
		DataManager.ActionType.SEARCH_TRAP:
			return tr("action_search_trap")
		DataManager.ActionType.LOSE_FLESH:
			return tr("action_lose_flesh")
		DataManager.ActionType.CRAFT:
			return tr("action_craft")
		DataManager.ActionType.TRADE:
			return tr("action_trade")
		DataManager.ActionType.ROB:
			return tr("action_rob")
		DataManager.ActionType.EVENT_MINER_SEARCH:  # 🆕
			return tr("event_miner_action_search")
		DataManager.ActionType.EVENT_MINER_HELP:    # 🆕
			return tr("event_miner_action_help")
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
		DataManager.ActionType.TRANSFORM_CARD:
			_handle_transform_card()
		DataManager.ActionType.BREW_POTION:
			_handle_brew_potion()
		DataManager.ActionType.DISARM_TRAP:
			_handle_disarm_trap()
		DataManager.ActionType.SEARCH_TRAP:
			_handle_search_trap()
		DataManager.ActionType.LOSE_FLESH:
			_handle_lose_flesh()
		DataManager.ActionType.CRAFT:
			_handle_craft()
		DataManager.ActionType.TRADE:
			_handle_trade()
		DataManager.ActionType.ROB:
			_handle_rob()
	# 🆕 Если действие не найдено в match — проверяем, является ли оно событийным
	var stri = DataManager.ActionType.keys()[action]
	if stri.begins_with("EVENT_"):
		_handle_event(action)
	else:
		printerr("Unknown action: ", action)

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
	var in_amount: float = 0.8
	if room_object:
		in_amount = 0.9
	var tween = create_tween()
	await tween.tween_property(dark_overlay, "color:a", in_amount, 1)

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
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.TAKE_DAMAGE, DataManager.RewardType.CARD_CHARACTER]
	reward_panel.damage_mod = DataManager.IDOL_DAMAGE  # передаём урон
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

func _handle_transform_card() -> void:
	await _show_result_label(tr("cauldron_transform_title"), DataManager.COLOR_HEAL_LOG)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.TRANSFORM_CARD]
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_brew_potion() -> void:
	await _show_result_label(tr("cauldron_brew_result"), DataManager.COLOR_HEAL_LOG)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.POTION]
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_disarm_trap() -> void:
	var success = randf() < DataManager.TRAP_NEUTRALIZE_CHANCE
	var rewards: Array[DataManager.RewardType] = []
	
	if success:
		await _show_result_label(tr("trap_disarm_success"), DataManager.COLOR_HEAL_LOG)
		rewards = [DataManager.RewardType.GOLD]
	else:
		await _show_result_label(tr("trap_disarm_fail"), DataManager.COLOR_PENITENT_ART_BG_DARK)
		rewards = [DataManager.RewardType.TAKE_DAMAGE]
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	reward_panel.gold_mod = 1
	reward_panel.damage_mod = DataManager.TRAP_NEUTRALIZE_DAMAGE
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_search_trap() -> void:
	var success = randf() < DataManager.TRAP_SEARCH_CHANCE
	var rewards: Array[DataManager.RewardType] = []
	
	if success:
		await _show_result_label(tr("trap_search_success"), DataManager.COLOR_HEAL_LOG)
		rewards = [DataManager.RewardType.GOLD, DataManager.RewardType.POTION]
	else:
		await _show_result_label(tr("trap_search_fail"), DataManager.COLOR_PENITENT_ART_BG_DARK)
		rewards = [DataManager.RewardType.GOLD, DataManager.RewardType.TAKE_DAMAGE]
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	reward_panel.gold_mod = 2 if success else 1
	reward_panel.damage_mod = DataManager.TRAP_SEARCH_DAMAGE
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_lose_flesh() -> void:
	await _show_result_label(tr("rack_lose_flesh_result"), DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	# Сначала урон, потом бафф
	reward_panel.reward_types = [
		DataManager.RewardType.LOST_MAX_HP,
		DataManager.RewardType.ENERGY_BUFF
	]
	reward_panel.damage_mod = DataManager.RACK_MAX_HP_LOST
	reward_panel.buff_duration = -1  # перманентный бафф (до конца забега)
	
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_craft() -> void:
	var success = randf() < 0.5  # 50% шанс
	var rewards: Array[DataManager.RewardType] = []
	
	if success:
		await _show_result_label(tr("rack_craft_success"), DataManager.COLOR_HEAL_LOG)
		rewards = [DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE]
	else:
		await _show_result_label(tr("rack_craft_fail"), DataManager.COLOR_PENITENT_ART_BG_DARK)
		rewards = [DataManager.RewardType.TAKE_DAMAGE, DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE]
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	reward_panel.damage_mod = 1  # базовый урон при неудаче
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_trade() -> void:
	await _show_result_label(tr("shop_trade_title"), DataManager.COLOR_HEAL_LOG)
	
	# Формируем товары
	var items = _generate_shop_items()
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.TRADE]
	reward_panel.shop_items = items  # нужно добавить поле в RewardPanel
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()

func _generate_shop_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	
	# 2-4 карты
	var card_count = randi() % 3 + 2  # 2-4
	var cards = DeckManager.get_cards_by_biome(FloorManager.current_biome, FloorManager.current_path_progress, FloorManager.current_floor, 10)
	cards.shuffle()
	for i in range(min(card_count, cards.size())):
		var card = cards[i]
		items.append({
			"type": "card",
			"data": card,
			"cost_grade": _random_cost_grade(),
		})
	
	# 1-2 артефакта
	var artifact_count = randi() % 2 + 1  # 1-2
	var artifacts = ArtifactManager.get_random_artifacts(DataManager.ArtifactGrade.NORMAL, 5)
	for i in range(min(artifact_count, artifacts.size())):
		var artifact = artifacts[i]
		items.append({
			"type": "artifact",
			"data": artifact,
			"cost_grade": _random_cost_grade(),
		})
	
	# 2-4 зелья
	var potion_count = randi() % 3 + 2  # 2-4
	var potions = DataManager.get_random_potions(10)
	for i in range(min(potion_count, potions.size())):
		var potion = potions[i]
		items.append({
			"type": "potion",
			"data": potion,
			"cost_grade": _random_cost_grade(),
		})
	
	return items

func _random_cost_grade() -> DataManager.CostGrade:
	var weights = [
		5,  # FREE (редко)
		10, # VERY_CHEAP
		20, # CHEAP
		30, # NORMAL
		20, # EXPENSIVE
		10, # VERY_EXPENSIVE
		5,  # ELITE
	]
	var total = 0
	for w in weights:
		total += w
	var roll = randi() % total
	var cumulative = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return i as DataManager.CostGrade
	return DataManager.CostGrade.NORMAL


func _handle_rob() -> void:
	await _show_result_label(tr("shop_rob_result"), DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	# Устанавливаем флаг грабителя
	RunManager.set_robber(true)
	SignalManager.log_message.emit("Вероломство будет наказано!")
	
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = [DataManager.RewardType.GET_BATTLE]
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()


func _handle_event(action: DataManager.ActionType) -> void:
	var is_first = (action == event_data.first_action)
	var is_second = (action == event_data.second_action)
	
	if not is_first and not is_second:
		SignalManager.log_message.emit("Ошибка: действие не найдено в событии!")
		return

	# 🆕 Успех или неудача (50% шанс)
	var success = randf() < DataManager.EVENT_SUCCESS_CHANCE
	# 🆕 Получаем ключ результата
	var result_key = ""
	if is_first:
		result_key = event_data.first_action_success_key if success else event_data.first_action_failure_key
	elif is_second:
		result_key = event_data.second_action_success_key if success else event_data.second_action_failure_key
	
	# 🆕 Оттеняемся (затемнение исчезает)
	_animate_out()
	
	# 🆕 Показываем текст результата
	if room_object and not result_key.is_empty():
		await room_object.print_narrative(tr(result_key))
	# 🆕 Ждём 1.5 секунды
	await get_tree().create_timer(3).timeout
	
	# 🆕 Парсим награды (заглушка)
	var rewards: Array[DataManager.RewardType] = []
	if is_first:
		rewards = event_data.first_action_success_rewards if success else event_data.first_action_failure_rewards
	elif is_second:
		rewards = event_data.second_action_success_rewards if success else event_data.second_action_failure_rewards

	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	reward_panel.reward_types = rewards
	
	# Проходим по наградам и устанавливаем параметры
	for reward in rewards:
		match reward:
			DataManager.RewardType.CARD_BIOM:
				if is_first:
					reward_panel.choice_count = event_data.first_success_choice_count if success else event_data.first_failure_choice_count
				elif is_second:
					reward_panel.choice_count = event_data.second_success_choice_count if success else event_data.second_failure_choice_count
			DataManager.RewardType.CARD_CHARACTER:
				if is_first:
					reward_panel.choice_count = event_data.first_success_choice_count if success else event_data.first_failure_choice_count
				elif is_second:
					reward_panel.choice_count = event_data.second_success_choice_count if success else event_data.second_failure_choice_count
			DataManager.RewardType.CARD_WITHOUT_CHOICE:
				pass
			DataManager.RewardType.ARTIFACT:
				if is_first:
					reward_panel.choice_count = event_data.first_success_choice_count if success else event_data.first_failure_choice_count
				elif is_second:
					reward_panel.choice_count = event_data.second_success_choice_count if success else event_data.second_failure_choice_count
			DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
				pass
			DataManager.RewardType.ARTIFACT_ELITE:
				if is_first:
					reward_panel.choice_count = event_data.first_success_choice_count if success else event_data.first_failure_choice_count
				elif is_second:
					reward_panel.choice_count = event_data.second_success_choice_count if success else event_data.second_failure_choice_count
			DataManager.RewardType.POTION:
				pass
			DataManager.RewardType.TAKE_DAMAGE:
				if is_first:
					reward_panel.damage_mod = event_data.first_success_damage_mod if success else event_data.first_failure_damage_mod
				elif is_second:
					reward_panel.damage_mod = event_data.second_success_damage_mod if success else event_data.second_failure_damage_mod
			DataManager.RewardType.GET_HEAL:
				if is_first:
					reward_panel.heal_mod = event_data.first_success_heal_mod if success else event_data.first_failure_heal_mod
				elif is_second:
					reward_panel.heal_mod = event_data.second_success_heal_mod if success else event_data.second_failure_heal_mod
			DataManager.RewardType.ENERGY_BUFF:
				if is_first:
					reward_panel.buff_amount = event_data.first_success_buff_amount if success else event_data.first_failure_buff_amount
					reward_panel.buff_duration = event_data.first_success_buff_duration if success else event_data.first_failure_buff_duration
				elif is_second:
					reward_panel.buff_amount = event_data.second_success_buff_amount if success else event_data.second_failure_buff_amount
					reward_panel.buff_duration = event_data.second_success_buff_duration if success else event_data.second_failure_buff_duration
			DataManager.RewardType.DECK_SIZE_BUFF:
				if is_first:
					reward_panel.buff_amount = event_data.first_success_buff_amount if success else event_data.first_failure_buff_amount
					reward_panel.buff_duration = event_data.first_success_buff_duration if success else event_data.first_failure_buff_duration
				elif is_second:
					reward_panel.buff_amount = event_data.second_success_buff_amount if success else event_data.second_failure_buff_amount
					reward_panel.buff_duration = event_data.second_success_buff_duration if success else event_data.second_failure_buff_duration
			DataManager.RewardType.GOLD:
				if is_first:
					reward_panel.gold_mod = event_data.first_success_gold_mod if success else event_data.first_failure_gold_mod
				elif is_second:
					reward_panel.gold_mod = event_data.second_success_gold_mod if success else event_data.second_failure_gold_mod
			DataManager.RewardType.REMOVE_CARD:
				if is_first:
					reward_panel.choice_count = event_data.first_success_choice_count if success else event_data.first_failure_choice_count
				elif is_second:
					reward_panel.choice_count = event_data.second_success_choice_count if success else event_data.second_failure_choice_count
			DataManager.RewardType.UPGRADE_CARD:
				if is_first:
					reward_panel.upgrade_count = event_data.first_success_upgrade_count if success else event_data.first_failure_upgrade_count
				elif is_second:
					reward_panel.upgrade_count = event_data.second_success_upgrade_count if success else event_data.second_failure_upgrade_count
			DataManager.RewardType.ADD_PROPERTY_TO_CARD:
				pass
			DataManager.RewardType.TRANSFORM_CARD:
				if is_first:
					reward_panel.upgrade_count = event_data.first_success_upgrade_count if success else event_data.first_failure_upgrade_count
				elif is_second:
					reward_panel.upgrade_count = event_data.second_success_upgrade_count if success else event_data.second_failure_upgrade_count
			DataManager.RewardType.LOST_MAX_HP:
				if is_first:
					reward_panel.damage_mod = event_data.first_success_damage_mod if success else event_data.first_failure_damage_mod
				elif is_second:
					reward_panel.damage_mod = event_data.second_success_damage_mod if success else event_data.second_failure_damage_mod
			DataManager.RewardType.TRADE:
				pass
			DataManager.RewardType.GET_BATTLE:
				pass
			DataManager.RewardType.CONCRETE_ARTIFACT:
				if is_first:
					reward_panel.concrete_artifact_id = event_data.first_success_concrete_artifact_id if success else event_data.first_failure_concrete_artifact_id
				elif is_second:
					reward_panel.concrete_artifact_id = event_data.second_success_concrete_artifact_id if success else event_data.second_failure_concrete_artifact_id
			DataManager.RewardType.CONCRETE_CARD:
				if is_first:
					reward_panel.concrete_card_id = event_data.first_success_concrete_card_id if success else event_data.first_failure_concrete_card_id
				elif is_second:
					reward_panel.concrete_card_id = event_data.second_success_concrete_card_id if success else event_data.second_failure_concrete_card_id
			DataManager.RewardType.GET_CONCRETE_BATTLE:
				if is_first:
					reward_panel.concrete_enemy = event_data.first_success_enemy if success else event_data.first_failure_enemy
				elif is_second:
					reward_panel.concrete_enemy = event_data.second_success_enemy if success else event_data.second_failure_enemy
	SignalManager.hide_object.emit()
	SignalManager.show_reward.emit(reward_panel)
	queue_free()
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	

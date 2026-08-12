extends VBoxContainer
class_name RewardContent

var reward_type: DataManager.RewardType
var rewards: Array = []  # массив карт, артефактов и т.д.
var selected_index: int = -1
var gold_mod: int = 1  # множитель золота
var damage_mod: int = 1
var heal_mod: int = 1
var buff_duration: int = 0
var upgrade_count: int = 1
var choice_count: int = 3
var buff_amount: int = 1
var concrete_artifact_id: DataManager.ArtifactId
var concrete_card_id: DataManager.CardId
var concrete_enemy: DataManager.EnemyId
var selected_card: CardData = null
var preview_container : CenterContainer = null
var transform_attempts: int = 0
var max_transform_attempts: int = 3
var confirm_button : Button
var shop_items: Array[Dictionary] = []
var hover_tween: Tween = null
var _last_hovered_vbox: Control = null
var transformed_card: CardData

enum ItemState {
	IDLE,
	HOVERED,
	UNHOVERED,
}

var item_tweens: Dictionary = {}  # key: Control (vbox), value: { "tween": Tween, "state": ItemState }

@onready var title_label: Label = $Title
@onready var rewards_container: HBoxContainer = $HBoxContainer

func setup(type: DataManager.RewardType, items: Array) -> void:
	reward_type = type
	rewards = items
	selected_index = -1
	_setup_title()
	
	title_label.text = _get_title()
	
	match reward_type:
		DataManager.RewardType.CARD_BIOM, DataManager.RewardType.CARD_CHARACTER:
			_setup_card_rewards()
		DataManager.RewardType.CARD_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_CARD:
			_setup_card_without_choice_reward()
		DataManager.RewardType.ARTIFACT, DataManager.RewardType.ARTIFACT_ELITE, DataManager.RewardType.ARTIFACT_COMBO:
			_setup_artifact_rewards()
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_ARTIFACT:
			_setup_artifact_without_choice_reward()
		DataManager.RewardType.POTION:
			_setup_potion_rewards()
		DataManager.RewardType.TAKE_DAMAGE:
			_setup_take_damage_reward()
		DataManager.RewardType.GET_HEAL:
			_setup_heal_reward()
		DataManager.RewardType.ENERGY_BUFF:
			_setup_energy_buff_reward()
		DataManager.RewardType.DECK_SIZE_BUFF:
			_setup_deck_size_buff_reward()
		DataManager.RewardType.GOLD:
			_setup_gold_reward()
		DataManager.RewardType.REMOVE_CARD:
			_setup_remove_card_reward()
		DataManager.RewardType.UPGRADE_CARD:
			_setup_upgrade_card_reward()
		DataManager.RewardType.ADD_PROPERTY_TO_CARD:
			_setup_add_property_reward()
		DataManager.RewardType.TRANSFORM_CARD:
			_setup_transform_card_reward()
		DataManager.RewardType.LOST_MAX_HP:
			_setup_lost_max_hp_reward()
		DataManager.RewardType.TRADE:
			_setup_trade_reward()

	# 🆕 Добавляем анимацию наведения для поддерживаемых типов
	_setup_hover_animation()


func _setup_hover_animation():
	var hover_types = [
		DataManager.RewardType.CARD_BIOM,
		DataManager.RewardType.CARD_CHARACTER,
		DataManager.RewardType.CARD_WITHOUT_CHOICE,
		DataManager.RewardType.CONCRETE_CARD,
		DataManager.RewardType.ARTIFACT,
		DataManager.RewardType.ARTIFACT_ELITE,
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE,
		DataManager.RewardType.CONCRETE_ARTIFACT,
		DataManager.RewardType.POTION,
	]
	
	if reward_type not in hover_types:
		return
	
	for child in rewards_container.get_children():
		var button = _find_button(child)
		if button:
			# Инициализируем структуру данных для этого vbox
			_get_item_data(child)
			
			button.mouse_entered.connect(_on_item_hovered.bind(child))
			button.mouse_exited.connect(_on_item_unhovered.bind(child))

func _find_button(node: Node) -> Button:
	# Ищем кнопку внутри VBoxContainer
	for child in node.get_children():
		if child is Button:
			return child
	return null

func _get_item_data(vbox: Control) -> Dictionary:
	if not item_tweens.has(vbox):
		item_tweens[vbox] = {
			"tween": null,
			"state": ItemState.IDLE,
		}
	return item_tweens[vbox]

func _on_item_hovered(vbox: Control):
	var first_child = vbox.get_child(0)
	if not first_child:
		return
	
	var data = _get_item_data(vbox)
	
	# Если уже в состоянии HOVERED — ничего не делаем
	if data.state == ItemState.HOVERED:
		return
	
	# Убиваем старый твин (если есть)
	if data.tween:
		data.tween.kill()
		data.tween = null
	
	# Мгновенно устанавливаем начальное состояние
	first_child.scale = Vector2.ONE
	
	var new_tween = create_tween()
	new_tween.tween_property(first_child, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)
	data.tween = new_tween
	data.tween.finished.connect(func(): 
		data.tween = null
	)
	
	data.state = ItemState.HOVERED

func _on_item_unhovered(vbox: Control):
	var first_child = vbox.get_child(0)
	if not first_child:
		return
	
	var data = _get_item_data(vbox)
	
	# Если уже в состоянии IDLE — ничего не делаем
	if data.state == ItemState.IDLE:
		return
	
	# Убиваем старый твин (если есть)
	if data.tween:
		data.tween.kill()
		data.tween = null
	
	# Мгновенно устанавливаем начальное состояние
	first_child.scale = Vector2(1.05, 1.05)
	
	# Создаём новый твин
	var new_tween = create_tween()
	new_tween.tween_property(first_child, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_IN)
	data.tween = new_tween
	data.tween.finished.connect(func(): 
		data.tween = null
	)
	
	data.state = ItemState.IDLE


func _setup_title() -> void:
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _get_title() -> String:
	match reward_type:
		DataManager.RewardType.CARD_BIOM:
			return tr("reward_card_biom_title")
		DataManager.RewardType.CARD_CHARACTER:
			return tr("reward_card_character_title")
		DataManager.RewardType.CARD_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_CARD:
			return tr("reward_card_without_choice_title")
		DataManager.RewardType.ARTIFACT:
			return tr("reward_artifact_title")
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_ARTIFACT:
			return tr("reward_artifact_without_choice_title")
		DataManager.RewardType.ARTIFACT_ELITE:
			return tr("reward_artifact_elite_title")
		DataManager.RewardType.POTION:
			return tr("reward_potion_title")
		DataManager.RewardType.TAKE_DAMAGE:
			return tr("reward_take_damage_title")
		DataManager.RewardType.GET_HEAL:
			return tr("reward_get_heal_title")
		DataManager.RewardType.ENERGY_BUFF:
			return tr("reward_energy_buff_title")
		DataManager.RewardType.DECK_SIZE_BUFF:
			return tr("reward_deck_size_buff_title")
		DataManager.RewardType.GOLD:
			return tr("reward_gold_title")
		DataManager.RewardType.REMOVE_CARD:
			return tr("reward_remove_card_title")
		DataManager.RewardType.UPGRADE_CARD:
			return tr("reward_upgrade_card_title")
		DataManager.RewardType.ADD_PROPERTY_TO_CARD:
			return tr("reward_add_property_title")
		DataManager.RewardType.TRANSFORM_CARD:
			return tr("reward_transform_card_title")
		DataManager.RewardType.TRADE:  # 🆕
			return tr("reward_trade_title")
		DataManager.RewardType.LOST_MAX_HP:  # 🆕
			return tr("reward_lost_max_hp_title")
		DataManager.RewardType.GET_BATTLE:  # 🆕
			return tr("reward_get_battle_title")
		_:
			return tr("reward_default_title")


func _on_item_selected(index: int) -> void:
	if selected_index != -1:
		return
	
	selected_index = index
	
	# Находим выбранный vbox
	var selected_vbox = rewards_container.get_child(index)
	
	# 1. Заголовок исчезает
	var tween_title = create_tween()
	tween_title.tween_property(title_label, "modulate", Color(1, 1, 1, 0), 0.2)
	
	# 2. Блокируем все кнопки и затемняем их
	for child in rewards_container.get_children():
		var button = child.get_child(-1) if child.get_child_count() > 0 else null
		if button is Button:
			button.disabled = true
			var tween = create_tween()
			tween.tween_property(button, "modulate", Color(0.5, 0.5, 0.5, 1), 0.15)
	
	# 3. Все невыбранные карты разлетаются в стороны
	var unselected_count = 0
	for child in rewards_container.get_children():
		if child != selected_vbox:
			var direction = 1 if unselected_count % 2 == 0 else -1
			var fly_x = direction * (randf_range(150, 250))
			var fly_y = randf_range(-100, 100)
			
			var tween = create_tween()
			tween.set_parallel(true)
			tween.tween_property(child, "position", child.position + Vector2(fly_x, fly_y), 0.3).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(child, "modulate", Color(1, 1, 1, 0), 0.3)
			tween.tween_property(child, "scale", Vector2(0.5, 0.5), 0.3)
			
			unselected_count += 1
			
			# Удаляем после анимации
			tween.tween_callback(child.queue_free).set_delay(0.35)
	
	# 4. Выбранный VBox поднимается и увеличивается
	var start_pos = selected_vbox.position
	var hover_pos = Vector2(
		rewards_container.size.x / 2 - selected_vbox.size.x / 2,
		selected_vbox.position.y - 60
	)
	
	var tween_hover = create_tween()
	tween_hover.set_parallel(true)
	tween_hover.tween_property(selected_vbox, "position", hover_pos, 0.3).set_ease(Tween.EASE_OUT)
	tween_hover.tween_property(selected_vbox, "scale", Vector2(1.1, 1.1), 0.3).set_ease(Tween.EASE_OUT)
	
	# 5. Убираем кнопку у выбранного
	var button = selected_vbox.get_child(-1) if selected_vbox.get_child_count() > 0 else null
	if button is Button:
		button.queue_free()
	
	# 6. Задержка перед финальной анимацией
	await get_tree().create_timer(0.4).timeout
	
	# 7. Карта улетает вверх и исчезает
	var final_target = Vector2(
		rewards_container.size.x / 2 - selected_vbox.size.x / 2,
		-200
	)
	
	var tween_fly = create_tween()
	tween_fly.set_parallel(true)
	tween_fly.tween_property(selected_vbox, "position", final_target, 0.5).set_ease(Tween.EASE_IN)
	tween_fly.tween_property(selected_vbox, "scale", Vector2(0.8, 0.8), 0.5).set_ease(Tween.EASE_IN)
	tween_fly.tween_property(selected_vbox, "modulate", Color(1, 1, 1, 0), 0.1)
	
	await tween_fly.finished
	selected_vbox.queue_free()
	
	_apply_reward(index)


func _apply_reward(index: int) -> void:
	var selected_item = rewards[index]
	
	match reward_type:
		DataManager.RewardType.CARD_BIOM, DataManager.RewardType.CARD_CHARACTER:
			SignalManager.add_card_to_deck.emit(selected_item)
		DataManager.RewardType.CARD_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_CARD:
			SignalManager.add_card_to_deck.emit(selected_item)
		DataManager.RewardType.ARTIFACT, DataManager.RewardType.ARTIFACT_COMBO, DataManager.RewardType.ARTIFACT_ELITE:
			SignalManager.add_artifact.emit(selected_item)
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_ARTIFACT:
			SignalManager.add_artifact.emit(selected_item)
		DataManager.RewardType.POTION:
			SignalManager.add_potion.emit(selected_item)
		DataManager.RewardType.TAKE_DAMAGE:
			var player = BattleManager.get_player()
			if player:
				player.take_damage(selected_item)
		DataManager.RewardType.GET_HEAL:
			var player = BattleManager.get_player()
			if player:
				player.heal(selected_item)
		DataManager.RewardType.ENERGY_BUFF:
			var player = BattleManager.get_player()
			if player:
				var bonus = rewards[0]
				var duration = rewards[1]
				if duration == -1:
					# Перманентный бафф — сразу применяем
					var current_max = player.get_max_energy()
					player.set_flat(DataManager.FlatStat.MAX_ENERGY, current_max + bonus)
					player.restore_energy()
					SignalManager.log_message.emit("Максимальная энергия увеличена на %d навсегда!" % bonus)
				else:
					# Временный бафф — через RunManager
					RunManager.apply_energy_buff(bonus, duration)
		DataManager.RewardType.DECK_SIZE_BUFF:
			var player = BattleManager.get_player()
			if player:
				var buff_amount = rewards[0]
				var duration = rewards[1]
				
				if duration == -1:
					# Перманентный бафф — сразу применяем
					var current_hand_size = player.get_flat(DataManager.FlatStat.HAND_SIZE)
					player.set_flat(DataManager.FlatStat.HAND_SIZE, current_hand_size + buff_amount)
					SignalManager.log_message.emit("Размер руки увеличен на %d навсегда!" % buff_amount)
				else:
					# Временный бафф — через RunManager
					RunManager.apply_deck_size_buff(buff_amount, duration)
		DataManager.RewardType.GOLD:
			SignalManager.add_coins.emit(selected_item)
		DataManager.RewardType.REMOVE_CARD:
			SignalManager.remove_card.emit(selected_item)
		DataManager.RewardType.UPGRADE_CARD:
			SignalManager.upgrade_card.emit(selected_item)
		DataManager.RewardType.ADD_PROPERTY_TO_CARD:
			SignalManager.add_property_to_card.emit(selected_item)
		DataManager.RewardType.LOST_MAX_HP:
			var player = BattleManager.get_player()
			if player:
				var current_max = player.get_max_health()
				var new_max = max(1, current_max - selected_item)
				player.set_flat(DataManager.FlatStat.MAX_HEALTH, new_max)
				if player.get_health() > new_max:
					player.set_flat(DataManager.FlatStat.HEALTH, new_max)
				SignalManager.log_message.emit("Максимальное здоровье уменьшено на %d!" % selected_item)
				
	SignalManager.reward_selected.emit()


func _setup_card_rewards() -> void:
	for card_data in rewards:
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		# 🆕 Добавляем отступы
		vbox.add_theme_constant_override("separation", 50)
		# Обёртка для карты
		var card_wrapper = Control.new()
		card_wrapper.custom_minimum_size = Vector2(
			DataManager.CARD_BASE_WIDTH * 1,
			DataManager.CARD_BASE_HEIGHT * 1
		)
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = card_data
		card_wrapper.add_child(card_ui)
		vbox.add_child(card_wrapper)
		rewards_container.add_child(vbox)
		
		card_ui.display()
		#card_ui.set_hand_scale()
		card_ui.template.scale = Vector2(0.8, 0.8)
		card_ui.set_reward_state()  # 🆕 устанавливаем состояние награды
		
		# Кнопка выбора
		var button = _create_reward_button("reward_choose_card", rewards.find(card_data))
		vbox.add_child(button)


func _setup_card_without_choice_reward() -> void:
	var card_data = rewards[0]  # одна карта
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 50)
	
	# Обёртка для карты
	var card_wrapper = Control.new()
	card_wrapper.custom_minimum_size = Vector2(
		DataManager.CARD_BASE_WIDTH * 1,
		DataManager.CARD_BASE_HEIGHT * 1
	)
	
	var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
	card_ui.card_data = card_data
	card_wrapper.add_child(card_ui)
	vbox.add_child(card_wrapper)
	rewards_container.add_child(vbox)
	
	card_ui.display()
	card_ui.template.scale = Vector2(0.8, 0.8)
	card_ui.set_reward_state()
	
	# Кнопка "Взять"
	var button = _create_reward_button("reward_take_card", 0)
	vbox.add_child(button)

func _setup_artifact_rewards() -> void:
	for artifact_data in rewards:
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 40)
		
		# Создаём ArtifactIcon
		var artifact_icon = preload("res://scenes/artifact_icon.tscn").instantiate() as ArtifactIcon
		artifact_icon.artifact_id = artifact_data.id
		artifact_icon.artifact_resource = artifact_data
		
		# Добавляем всё в дерево
		vbox.add_child(artifact_icon)
		rewards_container.add_child(vbox)
		
		# 🆕 Теперь можно настраивать
		artifact_icon.setup(artifact_data, true)
		
		## Название
		#var name_label = Label.new()
		#name_label.text = artifact_data.get_localized_name()
		#name_label.add_theme_font_override("font", DataManager.FONT_MAIN)
		#name_label.add_theme_font_size_override("font_size", 18)
		#name_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
		#name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		#vbox.add_child(name_label)
		
		# Кнопка выбора
		var button = _create_reward_button("reward_choose_artifact", rewards.find(artifact_data))
		vbox.add_child(button)


func _setup_artifact_without_choice_reward() -> void:
	var artifact_data = rewards[0]  # один артефакт
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	# Создаём ArtifactIcon
	var artifact_icon = preload("res://scenes/artifact_icon.tscn").instantiate() as ArtifactIcon
	artifact_icon.artifact_id = artifact_data.id
	artifact_icon.artifact_resource = artifact_data
	vbox.add_child(artifact_icon)
	rewards_container.add_child(vbox)
	
	# Настраиваем иконку после добавления в дерево
	artifact_icon.setup(artifact_data, true)
	
	## Название
	#var name_label = Label.new()
	#name_label.text = artifact_data.get_localized_name()
	#name_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	#name_label.add_theme_font_size_override("font_size", 14)
	#name_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	#name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(name_label)
	
	# Кнопка "Взять"
	var button = _create_reward_button("reward_take_artifact", 0)
	vbox.add_child(button)

func _setup_artifact_elite_rewards() -> void:
	# TODO: создать UI для выбора элитного артефакта
	pass

func _setup_potion_rewards() -> void:
	var potion_data = rewards[0]  # одно зелье
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	
	# Создаём PotionIcon в некликабельном состоянии
	var potion_icon = preload("res://scenes/potion_icon.tscn").instantiate() as PotionIcon
	vbox.add_child(potion_icon)
	rewards_container.add_child(vbox)
	potion_icon.setup(potion_data)
	potion_icon.set_interactable(false)
	
	## Название
	#var name_label = Label.new()
	#name_label.text = potion_data.get_localized_name()
	#name_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	#name_label.add_theme_font_size_override("font_size", 14)
	#name_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	#name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	#vbox.add_child(name_label)
	
	# Кнопка "Взять"
	var button = _create_reward_button("reward_take_potion", 0)
	vbox.add_child(button)

func _setup_take_damage_reward() -> void:
	var damage_amount = rewards[0]
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://img/icons/intents/attack.png")  # TODO: добавить иконку урона
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var damage_label = Label.new()
	damage_label.text = tr("damage_label") % damage_amount
	damage_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	damage_label.add_theme_font_size_override("font_size", 32)
	damage_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	damage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(damage_label)
	
	vbox.add_child(hbox)
	
	var button = _create_reward_button("reward_take_damage", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)

func _setup_heal_reward() -> void:
	var heal_amount = rewards[0]
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://img/icons/intents/heal.png")
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var heal_label = Label.new()
	heal_label.text = tr("heal_label") % heal_amount
	heal_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	heal_label.add_theme_font_size_override("font_size", 48)
	heal_label.add_theme_color_override("font_color", DataManager.COLOR_ROGUE_ART_BG_LIGHT)
	heal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heal_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(heal_label)
	
	vbox.add_child(hbox)
	
	var button = _create_reward_button("reward_take_heal", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)

func _setup_energy_buff_reward() -> void:
	var buff_amount = rewards[0]
	var buff_duration = rewards[1]
	var duration_text = ""
	
	if buff_duration == -1:
		duration_text = tr("buff_permanent")
	else:
		duration_text = tr("buff_duration") % buff_duration
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://img/icons/card_types/buff.png")  # TODO: добавить иконку
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var buff_label = Label.new()
	buff_label.text = tr("energy_buff_label") % buff_amount
	buff_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	buff_label.add_theme_font_size_override("font_size", 36)
	buff_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(buff_label)
	
	vbox.add_child(hbox)
	
	var duration_label = Label.new()
	duration_label.text = duration_text 
	duration_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	duration_label.add_theme_font_size_override("font_size", 16)
	duration_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(duration_label)
	
	var button = _create_reward_button("reward_take_buff", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)

func _setup_deck_size_buff_reward() -> void:
	var buff_amount = rewards[0]
	var buff_duration = rewards[1]
	var duration_text = ""
	if buff_duration == -1:
		duration_text = tr("buff_permanent")
	else:
		#BUG
		duration_text = tr("buff_duration") % buff_duration
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://img/icons/intents/buff.png")  # TODO: добавить иконку
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var buff_label = Label.new()
	buff_label.text = tr("deck_size_buff_label") % buff_amount
	buff_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	buff_label.add_theme_font_size_override("font_size", 36)
	buff_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	buff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buff_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(buff_label)
	
	vbox.add_child(hbox)
	
	var duration_label = Label.new()
	duration_label.text = duration_text
	duration_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	duration_label.add_theme_font_size_override("font_size", 16)
	duration_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(duration_label)
	
	var button = _create_reward_button("reward_take_buff", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)

func _setup_gold_reward() -> void:
	var gold_amount = rewards[0]
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var gold_label = Label.new()
	gold_label.text = tr("gold_label") % gold_amount
	gold_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	gold_label.add_theme_font_size_override("font_size", 48)
	gold_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gold_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(gold_label)
	
	vbox.add_child(hbox)
	
	var button = _create_reward_button("reward_take_gold", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)

func _setup_remove_card_reward() -> void:
	# TODO: создать UI для удаления карты из колоды
	pass


func _setup_add_property_reward() -> void:
	# TODO: создать UI для добавления свойства к карте
	pass

func _create_reward_button(text: String, index: int) -> Button:
	var button = DataManager.create_button(tr(text), DataManager.ButtonType.PRIMARY)
	# BUG
	button.pressed.connect(_on_item_selected.bind(index))
	
	return button


func _setup_upgrade_card_reward() -> void:
	var master_cards_temp = RunManager.get_player_deck().master_cards
	if master_cards_temp.is_empty():
		SignalManager.log_message.emit("Колода пуста! Нечего улучшать.")
		SignalManager.reward_selected.emit()
		return
	
	# 🆕 Фильтруем карты, которые можно улучшить
	var master_cards: Array[CardData] = []
	for card in master_cards_temp:
		if card.is_can_upgrade:
			master_cards.append(card)
	
	if master_cards.is_empty():
		SignalManager.log_message.emit("Нет карт, доступных для улучшения!")
		SignalManager.reward_selected.emit()
		return
	
	for child in rewards_container.get_children():
		child.queue_free()
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	main_vbox.add_theme_constant_override("separation", 15)
	rewards_container.add_child(main_vbox)
	
	# 🆕 Preview контейнер — размер с нормальную карту (масштаб 1.0)
	var preview_container = CenterContainer.new()
	preview_container.custom_minimum_size = Vector2(
		DataManager.CARD_BASE_WIDTH,
		DataManager.CARD_BASE_HEIGHT
	)
	preview_container.size = Vector2(
		DataManager.CARD_BASE_WIDTH,
		DataManager.CARD_BASE_HEIGHT
	)
	main_vbox.add_child(preview_container)
	
	# Grid контейнер с уменьшенными картами
	var scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	
	selected_card = null
	
	var card_scale = 0.65
	var card_size = Vector2(DataManager.CARD_BASE_WIDTH, DataManager.CARD_BASE_HEIGHT) * card_scale

	for card_data in master_cards:
		var display_card = card_data.duplicate_for_instance()
		display_card.upgrade_type = _get_upgrade_type_for_card(card_data)
		
		var card_wrapper = Control.new()
		card_wrapper.custom_minimum_size = card_size * 1.2
		card_wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = display_card
		card_wrapper.add_child(card_ui)
		
		grid.add_child(card_wrapper)
		card_ui.display()
		card_ui.card_control.scale = Vector2(card_scale, card_scale)
		card_ui.set_reward_state()
		
		card_wrapper.gui_input.connect(_on_card_wrapper_clicked.bind(card_data, display_card, card_wrapper, preview_container))
	scroll.custom_minimum_size = Vector2(4 * card_size.x * 1.2 + 3 * 20 + 20 , 2 * card_size.y * 1.2 + 20)
	
	
	var confirm_button = DataManager.create_button(tr("upgrade_card_confirm"), DataManager.ButtonType.PRIMARY)
	confirm_button.modulate = Color(1, 1, 1, 0)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_upgrade_confirm)
	main_vbox.add_child(confirm_button)


func _on_upgrade_card_selected(card_data: CardData, preview_container: Control) -> void:
	for child in preview_container.get_children():
		child.queue_free()
	
	var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
	card_ui.card_data = card_data
	preview_container.add_child(card_ui)
	
	card_ui.display()
	card_ui.scale = Vector2(1.0, 1.0)  # 🆕 нормальный размер
	card_ui.set_reward_state()
	
	selected_card = card_data
	
	var confirm_button = preview_container.get_parent().get_child(preview_container.get_parent().get_child_count() - 1)
	if confirm_button is Button:
		confirm_button.modulate = Color(1, 1, 1, 1)
		confirm_button.disabled = false


func _on_upgrade_confirm() -> void:
	if not selected_card:
		return
	
	# 🆕 Создаём копию карты с улучшением
	var upgraded_card = selected_card.duplicate_for_instance()
	_apply_upgrade_to_card(upgraded_card)
	
	# 🆕 Заменяем оригинальную карту в мастер-колоде
	var master_cards = RunManager.get_player_deck().master_cards
	var index = master_cards.find(selected_card)
	if index != -1:
		master_cards[index] = upgraded_card
	else:
		# Если не нашли — просто добавляем
		master_cards.append(upgraded_card)
	
	SignalManager.log_message.emit("Карта улучшена: %s" % selected_card.get_localized_name())
	SignalManager.reward_selected.emit()


func _on_card_wrapper_clicked(event: InputEvent, original_card: CardData, card_data: CardData, wrapper: Control, preview_container: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Снимаем выделение со всех обёрток
		for child in wrapper.get_parent().get_children():
			if child is Control:
				child.modulate = Color(1, 1, 1, 1)
		
		# Выделяем выбранную
		wrapper.modulate = DataManager.COLOR_ATONEMENT_GLOW
		
		# Показываем в preview
		for child in preview_container.get_children():
			child.queue_free()

		# 🆕 Показываем улучшенную версию карты
		var upgraded_card = _get_upgraded_card_copy(card_data)
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = upgraded_card
		var card_wrapper = Control.new()
		card_wrapper.add_child(card_ui)
		preview_container.add_child(card_wrapper)
		card_ui.display()
		card_ui.set_reward_state()
		card_ui.card_control.scale = Vector2(0.8, 0.8)
		card_wrapper.custom_minimum_size = card_ui.get_actual_size() * 1.3
		
		# 🆕 Сохраняем оригинальную карту для применения улучшения
		selected_card = original_card
		
		# Показываем кнопку подтверждения
		var confirm_button = preview_container.get_parent().get_child(preview_container.get_parent().get_child_count() - 1)
		if confirm_button is Button:
			confirm_button.modulate = Color(1, 1, 1, 1)
			confirm_button.disabled = false


func _apply_upgrade_to_card(card: CardData) -> void:
	match card.upgrade_type:
		DataManager.UpgradeType.COST_MINUS:
			if card.cost > 0:
				card.cost -= 1
		
		DataManager.UpgradeType.BLOCK_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.BLOCK:
					effect.base_value = floor(effect.base_value * 1.5)
					break
		
		DataManager.UpgradeType.DAMAGE_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.DAMAGE:
					effect.base_value = floor(effect.base_value * 1.5)
					break
		
		DataManager.UpgradeType.HEAL_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.HEAL:
					effect.base_value = floor(effect.base_value * 1.5)
					break
		
		DataManager.UpgradeType.DRAW_PLUS_1:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.DRAW_CARD
			new_effect.target = DataManager.EffectTarget.SELF
			new_effect.amount = 1
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.ENERGY_PLUS_1:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.GAIN_ENERGY
			new_effect.target = DataManager.EffectTarget.SELF
			new_effect.amount = 1
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.CONDITIONAL_DAMAGE_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.CONDITIONAL and effect.true_effect:
					if effect.true_effect.category == DataManager.EffectCategory.DAMAGE:
						effect.true_effect.base_value = floor(effect.true_effect.base_value * 1.5)
						break
		
		DataManager.UpgradeType.CONDITIONAL_BLOCK_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.CONDITIONAL and effect.true_effect:
					if effect.true_effect.category == DataManager.EffectCategory.BLOCK:
						effect.true_effect.base_value = floor(effect.true_effect.base_value * 1.5)
						break
		
		DataManager.UpgradeType.CONDITIONAL_HEAL_PLUS_PROC_50:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.CONDITIONAL and effect.true_effect:
					if effect.true_effect.category == DataManager.EffectCategory.HEAL:
						effect.true_effect.base_value = floor(effect.true_effect.base_value * 1.5)
						break
		
		DataManager.UpgradeType.DELETE_NEGATIVE_STATUS:
			var effects_to_remove: Array[int] = []
			for i in range(card.effects.size()):
				var effect = card.effects[i]
				if effect.category == DataManager.EffectCategory.APPLY_STATUS:
					if effect.target == DataManager.EffectTarget.SELF and effect.status:
						if DataManager.is_negative_status(effect.status.id):
							effects_to_remove.append(i)
			for i in range(effects_to_remove.size() - 1, -1, -1):
				card.effects.remove_at(effects_to_remove[i])
		
		DataManager.UpgradeType.ADD_DAMAGE_5:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.DAMAGE
			new_effect.target = DataManager.EffectTarget.ENEMY
			new_effect.base_value = 5
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.ADD_BLOCK_5:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.BLOCK
			new_effect.target = DataManager.EffectTarget.SELF
			new_effect.base_value = 5
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.ADD_HEAL_5:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.HEAL
			new_effect.target = DataManager.EffectTarget.SELF
			new_effect.base_value = 5
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.ADD_STRENGTH_3:
			var new_effect = EffectEntry.new()
			new_effect.category = DataManager.EffectCategory.APPLY_STATUS
			new_effect.target = DataManager.EffectTarget.SELF
			new_effect.status = DataManager.get_status_resource(DataManager.Status.STRENGTH)
			new_effect.value = 3
			new_effect.duration = 1
			card.effects.append(new_effect)
		
		DataManager.UpgradeType.X_2_NEGATIVE_STATUS:
			for effect in card.effects:
				if effect.category == DataManager.EffectCategory.APPLY_STATUS:
					if effect.target != DataManager.EffectTarget.SELF and effect.status:
						if DataManager.is_negative_status(effect.status.id):
							var status_resource = effect.status
							if status_resource.is_stacking:
								# Удваиваем стаки
								effect.value *= 2
							else:
								# Удваиваем длительность
								effect.duration *= 2
	
	card.is_can_upgrade = false


func _get_upgraded_card_copy(card: CardData) -> CardData:
	var copy = card.duplicate_for_instance()
	_apply_upgrade_to_card(copy)
	return copy


func _get_upgrade_type_for_card(card: CardData) -> DataManager.UpgradeType:
	if not card.is_can_upgrade:
		return card.upgrade_type
	
	var has_damage = false
	var has_block = false
	var has_heal = false
	var has_conditional_damage = false
	var has_conditional_block = false
	var has_conditional_heal = false
	var has_negative_self_status = false
	var has_negative_enemy_status = false
	var has_draw = false
	var has_energy = false
	
	for effect in card.effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				has_damage = true
			DataManager.EffectCategory.BLOCK:
				has_block = true
			DataManager.EffectCategory.HEAL:
				has_heal = true
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.target == DataManager.EffectTarget.SELF and effect.status and DataManager.is_negative_status(effect.status.id):
					has_negative_self_status = true
				if effect.target != DataManager.EffectTarget.SELF and effect.status and DataManager.is_negative_status(effect.status.id):
					has_negative_enemy_status = true
			DataManager.EffectCategory.DRAW_CARD:
				has_draw = true
			DataManager.EffectCategory.GAIN_ENERGY:
				has_energy = true
			DataManager.EffectCategory.CONDITIONAL:
				# 🆕 Проверяем эффекты внутри CONDITIONAL
				if effect.true_effect:
					match effect.true_effect.category:
						DataManager.EffectCategory.DAMAGE:
							has_conditional_damage = true
						DataManager.EffectCategory.BLOCK:
							has_conditional_block = true
						DataManager.EffectCategory.HEAL:
							has_conditional_heal = true
				if effect.false_effect:
					match effect.false_effect.category:
						DataManager.EffectCategory.DAMAGE:
							has_conditional_damage = true
						DataManager.EffectCategory.BLOCK:
							has_conditional_block = true
						DataManager.EffectCategory.HEAL:
							has_conditional_heal = true
	
	# Приоритеты выбора (сначала прямые эффекты, потом conditional)
	if has_damage:
		return DataManager.UpgradeType.DAMAGE_PLUS_PROC_50
	elif has_block:
		return DataManager.UpgradeType.BLOCK_PLUS_PROC_50
	elif has_heal:
		return DataManager.UpgradeType.HEAL_PLUS_PROC_50
	elif has_conditional_damage:
		return DataManager.UpgradeType.CONDITIONAL_DAMAGE_PLUS_PROC_50
	elif has_conditional_block:
		return DataManager.UpgradeType.CONDITIONAL_BLOCK_PLUS_PROC_50
	elif has_conditional_heal:
		return DataManager.UpgradeType.CONDITIONAL_HEAL_PLUS_PROC_50
	elif has_negative_enemy_status:
		return DataManager.UpgradeType.X_2_NEGATIVE_STATUS
	elif has_negative_self_status:
		return DataManager.UpgradeType.DELETE_NEGATIVE_STATUS
	elif has_draw:
		return DataManager.UpgradeType.DRAW_PLUS_1
	elif has_energy:
		return DataManager.UpgradeType.ENERGY_PLUS_1
	else:
		return DataManager.UpgradeType.COST_MINUS


func _setup_transform_card_reward() -> void:
	var master_cards = RunManager.get_player_deck().master_cards
	if master_cards.is_empty():
		SignalManager.log_message.emit("Колода пуста! Нечего преобразовывать.")
		SignalManager.reward_selected.emit()
		return
	
	var transformable_cards: Array[CardData] = []
	for card in master_cards:
		if card.is_can_upgrade:
			transformable_cards.append(card)
	
	if transformable_cards.is_empty():
		SignalManager.log_message.emit("Нет карт, доступных для преобразования!")
		SignalManager.reward_selected.emit()
		return
	
	for child in rewards_container.get_children():
		child.queue_free()
	
	transform_attempts = 0
	max_transform_attempts = 3
	
	# 🆕 Обновляем существующий title_label
	_update_transform_title()
	
	var main_vbox = VBoxContainer.new()
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	main_vbox.add_theme_constant_override("separation", 15)
	rewards_container.add_child(main_vbox)
	
	# Preview контейнер
	preview_container = CenterContainer.new()
	preview_container.custom_minimum_size = Vector2(
		DataManager.CARD_BASE_WIDTH,
		DataManager.CARD_BASE_HEIGHT
	)
	preview_container.size = Vector2(
		DataManager.CARD_BASE_WIDTH,
		DataManager.CARD_BASE_HEIGHT
	)
	main_vbox.add_child(preview_container)
	
	# Grid контейнер
	var scroll = ScrollContainer.new()
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	main_vbox.add_child(scroll)
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)
	
	selected_card = null
	
	var card_scale = 0.65
	var card_size = Vector2(DataManager.CARD_BASE_WIDTH, DataManager.CARD_BASE_HEIGHT) * card_scale
	for card_data in transformable_cards:
		var display_card = card_data.duplicate_for_instance()
		display_card.upgrade_type = _get_upgrade_type_for_card(card_data)
		
		var card_wrapper = Control.new()
		card_wrapper.mouse_filter = Control.MOUSE_FILTER_STOP
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = display_card
		card_wrapper.add_child(card_ui)
		card_wrapper.custom_minimum_size = card_size * 1.2
		
		await get_tree().create_timer(0.03).timeout
		
		grid.add_child(card_wrapper)
		card_ui.display()
		card_ui.card_control.scale = Vector2(card_scale, card_scale)
		card_ui.set_reward_state()
		
		card_wrapper.gui_input.connect(_on_transform_card_selected.bind(card_data, card_wrapper))
	scroll.custom_minimum_size = Vector2(4 * card_size.x * 1.2 + 3 * 20 + 20 , 2 * card_size.y * 1.2 + 20)
	
	# Кнопка подтверждения (всегда видима)
	confirm_button = DataManager.create_button(tr("transform_card_confirm"), DataManager.ButtonType.PRIMARY)
	confirm_button.modulate = Color(1, 1, 1, 1)
	confirm_button.disabled = true
	confirm_button.pressed.connect(_on_transform_confirm_pressed)
	main_vbox.add_child(confirm_button)

func _get_transform_title() -> String:
	var remaining = max_transform_attempts - transform_attempts
	return tr("reward_transform_card_title") % remaining

func _update_transform_title() -> void:
	var remaining = max_transform_attempts - transform_attempts
	if remaining == 0:
		title_label.text = tr("reward_transform_attempts_zero")
	else:
		title_label.text = tr("reward_transform_card_title") % remaining


func _on_transform_card_selected(event: InputEvent, card_data: CardData, wrapper: Control) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Проверяем, не достигнут ли лимит попыток
		if transform_attempts >= max_transform_attempts:
			SignalManager.log_message.emit("Вы уже использовали все попытки преобразования!")
			return
		
		# Проверяем, не кликнули ли по уже выбранной карте
		if wrapper.modulate == DataManager.COLOR_ATONEMENT_GLOW:
			return
		
		# Снимаем выделение со всех обёрток
		for child in wrapper.get_parent().get_children():
			if child is Control:
				child.modulate = Color(1, 1, 1, 1)
		
		# Выделяем выбранную
		wrapper.modulate = DataManager.COLOR_ATONEMENT_GLOW
		
		# Показываем в preview
		for child in preview_container.get_children():
			child.queue_free()
		
		transformed_card = _get_transformed_card_copy(card_data)
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = transformed_card
		var card_wrapper = Control.new()
		card_wrapper.add_child(card_ui)
		preview_container.add_child(card_wrapper)
		card_ui.display()
		card_ui.set_reward_state()
		card_ui.card_control.scale = Vector2(0.8, 0.8)
		card_wrapper.custom_minimum_size = card_ui.get_actual_size() * 1.3
		
		selected_card = card_data
		
		# Увеличиваем счётчик попыток
		transform_attempts += 1
		
		# 🆕 Обновляем заголовок
		_update_transform_title()
		
		# 🆕 Кнопка всегда видима, активируем её
		var confirm_button = preview_container.get_parent().get_child(preview_container.get_parent().get_child_count() - 1)
		if confirm_button is Button:
			confirm_button.disabled = false
		
		await get_tree().create_timer(0.1).timeout
		# Если достигнут лимит — автоматически подтверждаем
		if transform_attempts >= max_transform_attempts:
			SignalManager.log_message.emit("Достигнут лимит попыток! Преобразование выполняется автоматически.")
			await _on_transform_confirm()

func _get_transformed_card_copy(card: CardData) -> CardData:
	var copy = card.duplicate_for_instance()
	
	if copy.effects.is_empty():
		return copy
	
	# Определяем, какие эффекты есть у карты
	var has_damage = false
	var has_block = false
	var has_heal = false
	var has_other = false
	
	for effect in copy.effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				has_damage = true
			DataManager.EffectCategory.BLOCK:
				has_block = true
			DataManager.EffectCategory.HEAL:
				has_heal = true
			DataManager.EffectCategory.CONDITIONAL:
				if effect.true_effect:
					match effect.true_effect.category:
						DataManager.EffectCategory.DAMAGE:
							has_damage = true
						DataManager.EffectCategory.BLOCK:
							has_block = true
						DataManager.EffectCategory.HEAL:
							has_heal = true
			_:
				has_other = true
	
	var effect_count = copy.effects.size()
	
	if effect_count == 1:
		# Один эффект — добавляем новый случайный эффект
		var new_effect: EffectEntry = null
		
		if has_damage:
			var pool = [
				DataManager.EffectCategory.APPLY_STATUS,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		elif has_block:
			var pool = [
				DataManager.EffectCategory.GAIN_ENERGY,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.HEAL,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		elif has_heal:
			var pool = [
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.GAIN_ENERGY,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		else:
			var pool = [
				DataManager.EffectCategory.DAMAGE,
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.HEAL,
				DataManager.EffectCategory.APPLY_STATUS,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.GAIN_ENERGY,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		
		if new_effect:
			copy.effects.append(new_effect)
	
	elif effect_count >= 2:
		# Несколько эффектов — заменяем один из них
		var effect_to_replace = -1
		var new_effect: EffectEntry = null
		
		if has_damage:
			# Ищем не-урон эффект
			for i in range(copy.effects.size()):
				var e = copy.effects[i]
				if e.category != DataManager.EffectCategory.DAMAGE:
					if not (e.category == DataManager.EffectCategory.CONDITIONAL and e.true_effect and e.true_effect.category == DataManager.EffectCategory.DAMAGE):
						effect_to_replace = i
						break
			
			var pool = [
				DataManager.EffectCategory.APPLY_STATUS,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		
		elif has_block:
			for i in range(copy.effects.size()):
				var e = copy.effects[i]
				if e.category != DataManager.EffectCategory.BLOCK:
					if not (e.category == DataManager.EffectCategory.CONDITIONAL and e.true_effect and e.true_effect.category == DataManager.EffectCategory.BLOCK):
						effect_to_replace = i
						break
			
			var pool = [
				DataManager.EffectCategory.GAIN_ENERGY,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.HEAL,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		
		elif has_heal:
			for i in range(copy.effects.size()):
				var e = copy.effects[i]
				if e.category != DataManager.EffectCategory.HEAL:
					if not (e.category == DataManager.EffectCategory.CONDITIONAL and e.true_effect and e.true_effect.category == DataManager.EffectCategory.HEAL):
						effect_to_replace = i
						break
			
			var pool = [
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.GAIN_ENERGY,
				DataManager.EffectCategory.APPLY_STATUS,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		
		else:
			# Если нет явного типа — заменяем случайный эффект
			effect_to_replace = randi() % copy.effects.size()
			var pool = [
				DataManager.EffectCategory.DAMAGE,
				DataManager.EffectCategory.BLOCK,
				DataManager.EffectCategory.HEAL,
				DataManager.EffectCategory.APPLY_STATUS,
				DataManager.EffectCategory.DRAW_CARD,
				DataManager.EffectCategory.GAIN_ENERGY,
			]
			new_effect = DataManager.get_random_effect_from_pool(pool)
		
		if effect_to_replace != -1 and new_effect:
			copy.effects[effect_to_replace] = new_effect
	
	return copy

#func _on_transform_confirm() -> void:
	#if not selected_card:
		#return
	#if confirm_button:
		#confirm_button.disabled
		#confirm_button.hide()
	#await get_tree().create_timer(1).timeout
	## Применяем преобразование к оригинальной карте
	#var transformed = _get_transformed_card_copy(selected_card)
	#
	## Заменяем оригинальную карту в мастер-колоде
	#var master_cards = RunManager.get_player_deck().master_cards
	#var index = master_cards.find(selected_card)
	#if index != -1:
		#master_cards[index] = transformed
	#
	#SignalManager.log_message.emit("Карта преобразована: %s" % selected_card.get_localized_name())
	#
	## 🆕 Сбрасываем счётчик
	#transform_attempts = 0
	#
	#SignalManager.reward_selected.emit()

func _on_transform_confirm() -> void:
	if not selected_card or not transformed_card:
		return
	
	var preview_card = preview_container.get_child(0) if preview_container.get_child_count() > 0 else null
	if is_instance_valid(preview_card):
		var tween = create_tween()
		tween.set_parallel(true)
		
		# 1. Карта поднимается вверх (0.3 сек)
		tween.tween_property(preview_card, "position", Vector2(0, -100), 0.3).as_relative().set_ease(Tween.EASE_OUT)
		
		# 2. Остальные элементы (заголовок, грид, кнопка) растворяются
		var main_vbox = preview_card.get_parent().get_parent()  # VBoxContainer
		if main_vbox:
			for child in main_vbox.get_children():
				if child != preview_card.get_parent():  # не трогаем preview_container
					tween.tween_property(child, "modulate", Color(1, 1, 1, 0), 0.3)
		
		# Ждём подъёма
		await get_tree().create_timer(0.4).timeout
		
		# 3. Карта резко улетает вниз и исчезает (0.5 сек)
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(preview_card, "position", Vector2(0, 600), 0.5).as_relative().set_ease(Tween.EASE_IN)
		tween.tween_property(preview_card, "modulate", Color(1, 1, 1, 0), 0.5)
		
		await tween.finished
		
		if is_instance_valid(preview_card):
			preview_card.queue_free()
	
	var master_cards = RunManager.get_player_deck().master_cards
	var index = master_cards.find(selected_card)
	if index != -1:
		master_cards[index] = transformed_card
	
	SignalManager.log_message.emit("Карта преобразована: %s" % selected_card.get_localized_name())
	transform_attempts = 0
	
	SignalManager.reward_selected.emit()


func _on_transform_confirm_pressed() -> void:
	# Обёртка для вызова корутины из сигнала
	await _on_transform_confirm()


func _setup_lost_max_hp_reward() -> void:
	var lost_amount = rewards[0]
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 15)
	
	var icon = TextureRect.new()
	icon.texture = preload("res://img/icons/card_types/debuff.png")  # или другая иконка
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon)
	
	var label = Label.new()
	label.text = tr("lost_max_hp_label") % lost_amount
	label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(label)
	
	vbox.add_child(hbox)
	
	var button = _create_reward_button("reward_accept", 0)
	vbox.add_child(button)
	
	rewards_container.add_child(vbox)


func _setup_trade_reward() -> void:
	var trade_content = preload("res://scenes/trade_content.tscn").instantiate() as TradeContent
	rewards_container.add_child(trade_content)
	trade_content.setup(shop_items)
	
	# Создаём кнопку "Покинуть"
	var leave_button = DataManager.create_button(tr("shop_leave"), DataManager.ButtonType.PRIMARY)
	leave_button.pressed.connect(_on_trade_leave_pressed)
	
	# Добавляем под TradeContent
	trade_content.add_child(leave_button)

func _on_trade_leave_pressed() -> void:
	SignalManager.reward_selected.emit()

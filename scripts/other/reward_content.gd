extends VBoxContainer
class_name RewardContent

var reward_type: DataManager.RewardType
var rewards: Array = []  # массив карт, артефактов и т.д.
var selected_index: int = -1

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
		DataManager.RewardType.CARD_WITHOUT_CHOICE:
			_setup_card_without_choice_reward()
		DataManager.RewardType.ARTIFACT:
			_setup_artifact_rewards()
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			_setup_artifact_without_choice_reward()
		DataManager.RewardType.ARTIFACT_ELITE:
			_setup_artifact_elite_rewards()
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
			


func _setup_title() -> void:
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_FLESH_CAVES_ART_BG_DARK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _setup_card_rewards() -> void:
	for card_data in rewards:
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		# 🆕 Добавляем отступы
		vbox.add_theme_constant_override("separation", 40)
		# Обёртка для карты
		var card_wrapper = Control.new()
		card_wrapper.custom_minimum_size = Vector2(
			DataManager.CARD_BASE_WIDTH * 1.2,
			DataManager.CARD_BASE_HEIGHT * 1.2
		)
		
		var card_ui = preload("res://scenes/card.tscn").instantiate() as CardUI
		card_ui.card_data = card_data
		card_wrapper.add_child(card_ui)
		vbox.add_child(card_wrapper)
		rewards_container.add_child(vbox)
		
		card_ui.display()
		card_ui.set_hand_scale()
		card_ui.set_reward_state()  # 🆕 устанавливаем состояние награды
		
		# Кнопка выбора
		var button = _create_reward_button("reward_choose_card", rewards.find(card_data))
		vbox.add_child(button)


func _get_title() -> String:
	match reward_type:
		DataManager.RewardType.CARD_BIOM:
			return tr("reward_card_biom_title")
		DataManager.RewardType.CARD_CHARACTER:
			return tr("reward_card_character_title")
		DataManager.RewardType.CARD_WITHOUT_CHOICE:
			return tr("reward_card_without_choice_title")
		DataManager.RewardType.ARTIFACT:
			return tr("reward_artifact_title")
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
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
		_:
			return tr("reward_default_title")


func _on_item_selected(index: int) -> void:
	if selected_index != -1:
		return
	
	selected_index = index
	
	# Блокируем все кнопки
	for child in rewards_container.get_children():
		var button = child.get_child(-1)
		if button is Button:
			button.disabled = true
	
	# Находим выбранный vbox
	var selected_vbox = rewards_container.get_child(index)
	
	# 🆕 Исчезновение заголовка
	var tween_title = create_tween()
	tween_title.tween_property(title_label, "modulate", Color(1, 1, 1, 0), 0.2)
	
	# Анимируем выбранный элемент
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(selected_vbox, "scale", Vector2(1.2, 1.2), 0.2).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(0.3).timeout
	
	# Убираем все остальные элементы
	for child in rewards_container.get_children():
		if child != selected_vbox:
			child.queue_free()
	
	# Убираем кнопку у выбранного
	var button = selected_vbox.get_child(-1)
	if button is Button:
		button.queue_free()
	
	# Улетает вниз
	var target_pos = selected_vbox.position + Vector2(0, 600)
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(selected_vbox, "position", target_pos, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(selected_vbox, "modulate", Color(1, 1, 1, 0), 0.4)
	
	await tween.finished
	selected_vbox.queue_free()
	
	_apply_reward(index)


func _apply_reward(index: int) -> void:
	var selected_item = rewards[index]
	
	match reward_type:
		DataManager.RewardType.CARD_BIOM, DataManager.RewardType.CARD_CHARACTER:
			SignalManager.add_card_to_deck.emit(selected_item)
		DataManager.RewardType.CARD_WITHOUT_CHOICE:
			SignalManager.add_card_to_deck.emit(selected_item)
		DataManager.RewardType.ARTIFACT:
			SignalManager.add_artifact.emit(selected_item)
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			SignalManager.add_artifact.emit(selected_item)
		DataManager.RewardType.ARTIFACT_ELITE:
			SignalManager.add_artifact.emit(selected_item)
		DataManager.RewardType.POTION:
			SignalManager.add_potion.emit(selected_item)
		DataManager.RewardType.TAKE_DAMAGE:
			SignalManager.damage_player.emit(selected_item)
		DataManager.RewardType.GET_HEAL:
			SignalManager.heal_player.emit(selected_item)
		DataManager.RewardType.ENERGY_BUFF:
			SignalManager.energy_buff.emit(selected_item)
		DataManager.RewardType.DECK_SIZE_BUFF:
			SignalManager.deck_size_buff.emit(selected_item)
		DataManager.RewardType.GOLD:
			SignalManager.add_gold.emit(selected_item)
		DataManager.RewardType.REMOVE_CARD:
			SignalManager.remove_card.emit(selected_item)
		DataManager.RewardType.UPGRADE_CARD:
			SignalManager.upgrade_card.emit(selected_item)
		DataManager.RewardType.ADD_PROPERTY_TO_CARD:
			SignalManager.add_property_to_card.emit(selected_item)
	
	SignalManager.reward_selected.emit()


func _setup_card_without_choice_reward() -> void:
	# TODO: создать UI для получения конкретной карты (без выбора)
	pass

func _setup_artifact_rewards() -> void:
	# TODO: создать UI для выбора артефакта
	pass

func _setup_artifact_without_choice_reward() -> void:
	# TODO: создать UI для получения конкретного артефакта (без выбора)
	pass

func _setup_artifact_elite_rewards() -> void:
	# TODO: создать UI для выбора элитного артефакта
	pass

func _setup_potion_rewards() -> void:
	# TODO: создать UI для получения зелья
	pass

func _setup_take_damage_reward() -> void:
	# TODO: создать UI для получения урона
	pass

func _setup_heal_reward() -> void:
	# TODO: создать UI для лечения
	pass

func _setup_energy_buff_reward() -> void:
	# TODO: создать UI для увеличения энергии
	pass

func _setup_deck_size_buff_reward() -> void:
	# TODO: создать UI для увеличения размера колоды
	pass

func _setup_gold_reward() -> void:
	# TODO: создать UI для получения золота
	pass

func _setup_remove_card_reward() -> void:
	# TODO: создать UI для удаления карты из колоды
	pass

func _setup_upgrade_card_reward() -> void:
	# TODO: создать UI для улучшения карты
	pass

func _setup_add_property_reward() -> void:
	# TODO: создать UI для добавления свойства к карте
	pass


func _create_reward_button(text: String, index: int) -> Button:
	var button = Button.new()
	button.text = tr(text)
	button.pressed.connect(_on_item_selected.bind(index))
	
	# Настройка стиля как у кнопки "Конец хода"
	button.add_theme_font_override("font", DataManager.FONT_HEADERS)
	button.add_theme_font_size_override("font_size", 20)
	button.custom_minimum_size = Vector2(150, 50)
	
	return button

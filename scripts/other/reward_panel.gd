extends Control
class_name RewardPanel

var reward_types: Array = []
var current_index: int = 0
var is_animating: bool = false
var gold_mod: int = 1  # множитель золота
var damage_mod: int = 1 # множитель урона
var heal_mod: int = 1
var buff_duration: int = 0
var upgrade_count: int = 1  # количество карт для улучшения
var shop_items: Array[Dictionary] = []

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var center_container: CenterContainer = $CenterContainer
@onready var after_dark_overlay: ColorRect = $AfterDarkOverlay

func _ready():
	# Начальное состояние: AfterDarkOverlay полностью прозрачный
	after_dark_overlay.color.a = 0.0
	await _animate_in()
	show_rewards()


func show_rewards():
	current_index = 0
	_show_current_reward()

func _show_current_reward():
	if current_index >= reward_types.size():
		# Все награды показаны — затемняем и закрываем
		_animate_final_out()
		return
	
	# Затемняем между наградами
	_animate_transition_in()

func _animate_transition_in():
	is_animating = true
	# Затемняем AfterDarkOverlay
	var tween = create_tween()
	tween.tween_property(after_dark_overlay, "color:a", 0.8, 0.3)
	await tween.finished
	
	# Показываем контент текущей награды
	_create_current_reward()
	
	# Оттемняем
	tween = create_tween()
	tween.tween_property(after_dark_overlay, "color:a", 0.0, 0.3)
	await tween.finished
	is_animating = false

func _create_current_reward():
	var reward_type = reward_types[current_index]
	
	# Очищаем контейнер
	for child in center_container.get_children():
		child.queue_free()
	
	match reward_type:
		DataManager.RewardType.CARD_BIOM:
			_create_card_reward(DataManager.RewardType.CARD_BIOM)
		DataManager.RewardType.CARD_CHARACTER:
			_create_card_reward(DataManager.RewardType.CARD_CHARACTER)
		DataManager.RewardType.CARD_WITHOUT_CHOICE:
			_create_card_without_choice_reward()
		DataManager.RewardType.ARTIFACT:
			_create_artifact_reward()
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			_create_artifact_without_choice_reward()
		DataManager.RewardType.ARTIFACT_ELITE:
			_create_artifact_elite_reward()
		DataManager.RewardType.POTION:
			_create_potion_reward()
		DataManager.RewardType.TAKE_DAMAGE:
			_create_take_damage_reward()
		DataManager.RewardType.GET_HEAL:
			_create_heal_reward()
		DataManager.RewardType.ENERGY_BUFF:
			_create_energy_buff_reward()
		DataManager.RewardType.DECK_SIZE_BUFF:
			_create_deck_size_buff_reward()
		DataManager.RewardType.GOLD:
			_create_gold_reward()
		DataManager.RewardType.REMOVE_CARD:
			_create_remove_card_reward()
		DataManager.RewardType.UPGRADE_CARD:
			_create_upgrade_card_reward()
		DataManager.RewardType.ADD_PROPERTY_TO_CARD:
			_create_add_property_reward()
		DataManager.RewardType.TRANSFORM_CARD:
			_create_transform_card_reward()
		DataManager.RewardType.LOST_MAX_HP:
			_create_lost_max_hp_reward()
		DataManager.RewardType.TRADE:
			_create_trade_reward()
		DataManager.RewardType.GET_BATTLE:
			_create_battle_reward()
		_:
			pass


func _create_card_reward(type: DataManager.RewardType) -> void:
	var cards: Array[CardData] = []
	var amount: int = DataManager.REWARD_CHOICE_AMOUNT
	
	match type:
		DataManager.RewardType.CARD_BIOM:
			var biome = FloorManager.current_biome
			var floor = FloorManager.current_floor
			var progress = FloorManager.current_path_progress
			cards = DeckManager.get_cards_by_biome(biome, progress, floor, amount)
		
		DataManager.RewardType.CARD_CHARACTER:
			var character = RunManager.current_character
			var floor = FloorManager.current_floor
			var progress = FloorManager.current_path_progress
			cards = DeckManager.get_cards_by_character(character, progress, floor, amount)
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(type, cards)
	
	# Подписываемся на сигнал через SignalManager
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_card_without_choice_reward() -> void:
	# Получаем случайную карту
	var cards = DeckManager.get_cards_by_biome(FloorManager.current_biome, FloorManager.current_path_progress, FloorManager.current_floor, 1)
	if cards.is_empty():
		SignalManager.log_message.emit("Нет доступных карт!")
		SignalManager.reward_selected.emit()
		return
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	# Используем CARD_WITHOUT_CHOICE тип, передаём массив с одной картой
	content.setup(DataManager.RewardType.CARD_WITHOUT_CHOICE, cards)
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_reward() -> void:
	var amount: int = 3
	var grade: DataManager.ArtifactGrade = DataManager.ArtifactGrade.NORMAL
	
	match reward_types[current_index]:
		DataManager.RewardType.ARTIFACT:
			grade = DataManager.ArtifactGrade.NORMAL
		DataManager.RewardType.ARTIFACT_ELITE:
			grade = DataManager.ArtifactGrade.ELITE
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			grade = DataManager.ArtifactGrade.NORMAL
			amount = 1
	
	# 🆕 Получаем ID артефактов, которые уже есть у игрока
	var existing_ids: Array[DataManager.ArtifactId] = []
	for artifact in RunManager.artifacts:
		existing_ids.append(artifact.id)
	
	# Получаем все доступные артефакты по грейду
	var all_available = ArtifactManager._get_available_artifacts_by_grade(grade)
	
	# 🆕 Фильтруем — убираем те, что уже есть
	var filtered: Array[DataManager.ArtifactId] = []
	for artifact_id in all_available:
		if artifact_id not in existing_ids:
			filtered.append(artifact_id)
	
	var selected_artifacts: Array[ArtifactResource] = []
	
	if filtered.is_empty():
		# Если все артефакты уже получены — даём золото вместо артефакта
		SignalManager.log_message.emit("Все артефакты этого грейда уже получены! Вы получаете золото.")
		# TODO: выдать золото
		return
	
	filtered.shuffle()
	
	if amount == 1:
		var resource = DataManager.get_artifact_resource(filtered[0])
		if resource:
			selected_artifacts.append(resource)
	else:
		for i in range(min(amount, filtered.size())):
			var resource = DataManager.get_artifact_resource(filtered[i])
			if resource:
				selected_artifacts.append(resource)
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.ARTIFACT, selected_artifacts)
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_without_choice_reward() -> void:
	# Определяем грейд в зависимости от контекста
	var grade = DataManager.ArtifactGrade.NORMAL
	match reward_types[current_index]:
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			grade = DataManager.ArtifactGrade.NORMAL
		DataManager.RewardType.ARTIFACT_ELITE:
			grade = DataManager.ArtifactGrade.ELITE
	
	# Получаем случайный артефакт
	var artifact = ArtifactManager.get_random_artifact(grade)
	if not artifact:
		SignalManager.log_message.emit("Нет доступных артефактов!")
		SignalManager.reward_selected.emit()
		return
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE, [artifact])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_elite_reward() -> void:
	# TODO: создать UI для выбора элитного артефакта
	pass

func _create_potion_reward() -> void:
	# Получаем случайное зелье
	var potion = DataManager.get_random_potions(1)[0]  # одно случайное зелье
	
	if not potion:
		SignalManager.log_message.emit("Нет доступных зелий!")
		SignalManager.reward_selected.emit()
		return
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.POTION, [potion])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_take_damage_reward() -> void:
	var damage_amount = DataManager.REWARD_DAMAGE_DEFAULT
	if damage_mod > 1:
		damage_amount = damage_mod
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.damage_mod = damage_mod
	center_container.add_child(content)
	content.setup(DataManager.RewardType.TAKE_DAMAGE, [damage_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_heal_reward() -> void:
	var heal_amount = DataManager.REST_DEFAULT_HEAL * heal_mod
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.heal_mod = heal_mod
	center_container.add_child(content)
	content.setup(DataManager.RewardType.GET_HEAL, [heal_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_energy_buff_reward() -> void:
	var buff_amount = DataManager.ENERGY_BUFF_REWARD_AMOUNT
	var duration = buff_duration  # уже передан извне
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.buff_duration = duration
	content.energy_buff_amount = buff_amount
	center_container.add_child(content)
	content.setup(DataManager.RewardType.ENERGY_BUFF, [buff_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_deck_size_buff_reward() -> void:
	var buff_amount = 1  # +1 к размеру руки
	var duration = buff_duration if buff_duration > 0 else -1  # -1 = до конца забега
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.buff_duration = duration
	center_container.add_child(content)
	content.setup(DataManager.RewardType.DECK_SIZE_BUFF, [buff_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_gold_reward() -> void:
	var gold_amount = DataManager.REWARD_GOLD_DEFAULT * gold_mod
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.gold_mod = gold_mod
	center_container.add_child(content)
	content.setup(DataManager.RewardType.GOLD, [gold_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_remove_card_reward() -> void:
	# TODO: создать UI для удаления карты из колоды
	pass

func _create_upgrade_card_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.upgrade_count = upgrade_count
	center_container.add_child(content)
	content.setup(DataManager.RewardType.UPGRADE_CARD, [])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_add_property_reward() -> void:
	# TODO: создать UI для добавления свойства к карте
	pass

func _on_reward_selected() -> void:
	# Отписываемся, чтобы не было дублирования
	SignalManager.reward_selected.disconnect(_on_reward_selected)
	current_index += 1
	_show_current_reward()

func _animate_final_out():
	# Оттемняем и закрываем панель
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.5)
	await tween.finished
	
	SignalManager.getting_all_rewards.emit()
	queue_free()

func _animate_in():
	# Начальная анимация появления
	dark_overlay.color.a = 0.0
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", 0.8, 0.5)
	await tween.finished


func _create_transform_card_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.TRANSFORM_CARD, [])
	SignalManager.reward_selected.connect(_on_reward_selected)


func _create_lost_max_hp_reward() -> void:
	var lost_amount = DataManager.RACK_MAX_HP_LOST * damage_mod
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.damage_mod = damage_mod
	center_container.add_child(content)
	content.setup(DataManager.RewardType.LOST_MAX_HP, [lost_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)


func _create_trade_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	content.shop_items = shop_items
	center_container.add_child(content)
	content.setup(DataManager.RewardType.TRADE, [])
	SignalManager.reward_selected.connect(_on_reward_selected)


func _create_battle_reward() -> void:
	# Создаём RoomNode для элитного боя
	var room_node = RoomNode.new()
	room_node.setup({
		"type": DataManager.RoomType.COMBAT,
		"combat_type": DataManager.CombatType.ELITE,
		"is_revealed": true
	})
	var current_room = GameTestManager.get_current_room()
	# Вызываем загрузку комнаты через GameTestManager
	GameTestManager._on_room_selected(room_node, false)

	if current_room:
		current_room.queue_free()
	# Закрываем панель наград
	queue_free()

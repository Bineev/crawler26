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
var choice_count: int = 3
var buff_amount: int = 1
var concrete_artifact_id: DataManager.ArtifactId
var concrete_card_id: DataManager.CardId
var concrete_enemy: DataManager.EnemyId
var shop_items: Array[Dictionary] = []
## Для GET_CONCRETE_STATUS — статус и его параметры
var concrete_status: DataManager.Status = DataManager.Status.POISON
var concrete_status_stacks: int = 1
var concrete_status_duration: int = 1
var max_health_mod: int = 1  # множитель увеличения макс. здоровья

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var center_container: CenterContainer = $CenterContainer
@onready var after_dark_overlay: ColorRect = $AfterDarkOverlay

func _ready():
	# Начальное состояние: AfterDarkOverlay полностью прозрачный
	scale *= DataManager.SCALE_FACTOR
	#dark_overlay.custom_minimum_size *= DataManager.SCALE_FACTOR
	#after_dark_overlay.custom_minimum_size *= DataManager.SCALE_FACTOR
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
	
	if reward_type == DataManager.RewardType.UPGRADE_CARD or reward_type == DataManager.RewardType.TRANSFORM_CARD or reward_type == DataManager.RewardType.TRADE:
		center_container.position.y = 0
	elif reward_type == DataManager.RewardType.CARD_BIOM or reward_type == DataManager.RewardType.CARD_CHARACTER or reward_type == DataManager.RewardType.CARD_WITHOUT_CHOICE or reward_type == DataManager.RewardType.CONCRETE_CARD:
		center_container.position.y = 200
	else:
		center_container.position.y = 300
	
	for child in center_container.get_children():
		child.queue_free()
	
	match reward_type:
		DataManager.RewardType.CARD_BIOM:
			_create_card_reward(DataManager.RewardType.CARD_BIOM)
		DataManager.RewardType.CARD_CHARACTER:
			_create_card_reward(DataManager.RewardType.CARD_CHARACTER)
		DataManager.RewardType.CARD_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_CARD:
			_create_card_without_choice_reward(reward_type)
		DataManager.RewardType.ARTIFACT, DataManager.RewardType.ARTIFACT_ELITE, DataManager.RewardType.ARTIFACT_COMBO:
			_create_artifact_reward()
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE, DataManager.RewardType.CONCRETE_ARTIFACT:
			_create_artifact_without_choice_reward(reward_type)
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
		DataManager.RewardType.GET_BATTLE, DataManager.RewardType.GET_CONCRETE_BATTLE:
			_create_battle_reward(reward_type)
		DataManager.RewardType.GET_CONCRETE_STATUS:
			_create_concrete_status_reward()
		DataManager.RewardType.GET_MAX_HEALTH:
			_create_max_health_reward()
		_:
			pass


func _create_card_reward(type: DataManager.RewardType) -> void:
	var cards: Array[CardData] = []
	var amount: int = choice_count  # 🆕 используем choice_count вместо константы
	
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

func _create_card_without_choice_reward(type: DataManager.RewardType = DataManager.RewardType.CARD_WITHOUT_CHOICE) -> void:
	var cards: Array[CardData] = []
	
	if type == DataManager.RewardType.CONCRETE_CARD:
		var card = DataManager.get_card(concrete_card_id)
		if card:
			cards.append(card)
	else:
		cards = DeckManager.get_cards_by_biome(FloorManager.current_biome, FloorManager.current_path_progress, FloorManager.current_floor, 1)
	
	if cards.is_empty():
		SignalManager.log_message.emit("Нет доступных карт!")
		SignalManager.reward_selected.emit()
		return
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	# Используем CARD_WITHOUT_CHOICE тип, передаём массив с одной картой
	content.setup(type, cards)
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_reward() -> void:
	var amount: int = choice_count
	var grade: DataManager.ArtifactGrade = DataManager.ArtifactGrade.NORMAL
	
	match reward_types[current_index]:
		DataManager.RewardType.ARTIFACT:
			grade = DataManager.ArtifactGrade.NORMAL
		DataManager.RewardType.ARTIFACT_ELITE:
			grade = DataManager.ArtifactGrade.ELITE
		DataManager.RewardType.ARTIFACT_COMBO:
			grade = DataManager.ArtifactGrade.COMBO
	
	# Получаем ID артефактов, которые уже есть у игрока
	var existing_ids: Array[DataManager.ArtifactId] = []
	for artifact in RunManager.artifacts:
		existing_ids.append(artifact.id)
	
	# Получаем все доступные артефакты по грейду
	var all_available = ArtifactManager.get_available_artifacts_by_grade(grade)
	
	# Фильтруем — убираем те, что уже есть
	var filtered: Array[DataManager.ArtifactId] = []
	for artifact_id in all_available:
		if artifact_id not in existing_ids:
			filtered.append(artifact_id)
	
	var selected_artifacts: Array[ArtifactResource] = []
	
	if filtered.is_empty():
		SignalManager.log_message.emit("Все артефакты этого грейда уже получены! Вы получаете золото.")
		# TODO: выдать золото
		return
	
	filtered.shuffle()
	
	for i in range(min(amount, filtered.size())):
		var resource = DataManager.get_artifact_resource(filtered[i])
		if resource:
			selected_artifacts.append(resource)
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(reward_types[current_index], selected_artifacts)
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_without_choice_reward(type: DataManager.RewardType = DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE) -> void:
	var artifacts: Array[ArtifactResource] = []
	
	if type == DataManager.RewardType.CONCRETE_ARTIFACT:
		var artifact = DataManager.get_artifact_resource(concrete_artifact_id)
		if artifact:
			artifacts.append(artifact)
	else:
		var random_artifact = ArtifactManager.get_random_artifact(DataManager.ArtifactGrade.NORMAL)
		if random_artifact:
			artifacts.append(random_artifact)
	
	if artifacts.is_empty():
		SignalManager.log_message.emit("Нет доступных артефактов!")
		SignalManager.reward_selected.emit()
		return
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(type, artifacts)
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
	content.setup(reward_types[current_index], [potion])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_take_damage_reward() -> void:
	var damage_amount = RunManager.reward_damage_default * damage_mod
	# 🆕 Проверяем, чтобы урон не убивал игрока
	var player = BattleManager.get_player()
	if player:
		var current_health = player.get_health()
		if current_health - damage_amount < 1:
			damage_amount = current_health - 1
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	# content.damage_mod = damage_mod  # 🆕 убираем
	center_container.add_child(content)
	content.setup(DataManager.RewardType.TAKE_DAMAGE, [damage_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_heal_reward() -> void:
	var heal_amount = RunManager.rest_default_heal * heal_mod
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.GET_HEAL, [heal_amount])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_energy_buff_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent

	center_container.add_child(content)
	content.setup(DataManager.RewardType.ENERGY_BUFF, [buff_amount, buff_duration])  # 🆕 передаём оба параметра
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_deck_size_buff_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.DECK_SIZE_BUFF, [buff_amount, buff_duration])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_gold_reward() -> void:
	var gold_amount = RunManager.reward_gold_default * gold_mod
	
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
	center_container.add_child(content)
	content.setup(DataManager.RewardType.UPGRADE_CARD, [upgrade_count])
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_add_property_reward() -> void:
	# TODO: создать UI для добавления свойства к карте
	pass

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


func _create_battle_reward(type: DataManager.RewardType = DataManager.RewardType.GET_BATTLE) -> void:
	var room_node = RoomNode.new()
	var current_room = GameTestManager.get_current_room()
	if type == DataManager.RewardType.GET_CONCRETE_BATTLE:
		room_node.setup({
			"type": DataManager.RoomType.COMBAT,
			"combat_type": DataManager.CombatType.CONCRETE_COMBAT,
			"is_revealed": true
		})
		# Передаём массив с конкретным врагом
		GameTestManager._on_room_selected(room_node, false, [concrete_enemy])
	else:
		room_node.setup({
			"type": DataManager.RoomType.COMBAT,
			"combat_type": DataManager.CombatType.ELITE_AFTER_ROB,
			"is_revealed": true
		})
		GameTestManager._on_room_selected(room_node, false)
	
	if current_room:
		current_room.queue_free()
	
	queue_free()


func _create_concrete_status_reward() -> void:
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	
	# Передаём данные о статусе
	content.concrete_status = concrete_status
	content.concrete_status_stacks = concrete_status_stacks
	content.concrete_status_duration = concrete_status_duration
	
	# Настройка контента для отображения
	content.setup(DataManager.RewardType.GET_CONCRETE_STATUS, [])
	SignalManager.reward_selected.connect(_on_reward_selected)


func _create_max_health_reward() -> void:
	var amount = DataManager.BASE_MAX_HEALTH_AMOUNT * max_health_mod  # базовое значение 10, умножаем на модификатор
	
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.max_health_amount = amount
	content.setup(DataManager.RewardType.GET_MAX_HEALTH, [amount])
	SignalManager.reward_selected.connect(_on_reward_selected)


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

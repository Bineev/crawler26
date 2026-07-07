extends Control
class_name RewardPanel

var reward_types: Array[DataManager.RewardType] = []
var current_index: int = 0
var is_animating: bool = false
var gold_mod: int = 1  # множитель золота

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
	# TODO: создать UI для получения конкретной карты (без выбора)
	pass

func _create_artifact_reward() -> void:
	var artifacts: Array[ArtifactResource] = []
	var amount: int = 3  # количество артефактов на выбор
	var grade: DataManager.ArtifactGrade = DataManager.ArtifactGrade.NORMAL
	
	# Определяем грейд в зависимости от типа награды
	match reward_types[current_index]:
		DataManager.RewardType.ARTIFACT:
			grade = DataManager.ArtifactGrade.NORMAL
		DataManager.RewardType.ARTIFACT_ELITE:
			grade = DataManager.ArtifactGrade.ELITE
		DataManager.RewardType.ARTIFACT_WITHOUT_CHOICE:
			grade = DataManager.ArtifactGrade.NORMAL
			amount = 1  # без выбора — даём один
	
	# Получаем артефакты
	if amount == 1:
		# Без выбора — просто один артефакт
		var artifact = ArtifactManager.get_random_artifact(grade)
		if artifact:
			artifacts.append(artifact)
	else:
		# С выбором — несколько артефактов
		artifacts = ArtifactManager.get_random_artifacts(grade, amount)
	
	# Создаём контент для артефактов
	var content = preload("res://scenes/reward_content.tscn").instantiate() as RewardContent
	center_container.add_child(content)
	content.setup(DataManager.RewardType.ARTIFACT, artifacts)
	SignalManager.reward_selected.connect(_on_reward_selected)

func _create_artifact_without_choice_reward() -> void:
	# TODO: создать UI для получения конкретного артефакта (без выбора)
	pass

func _create_artifact_elite_reward() -> void:
	# TODO: создать UI для выбора элитного артефакта
	pass

func _create_potion_reward() -> void:
	# TODO: создать UI для получения зелья
	pass

func _create_take_damage_reward() -> void:
	# TODO: создать UI для получения урона (обычно за выбор)
	pass

func _create_heal_reward() -> void:
	# TODO: создать UI для лечения
	pass

func _create_energy_buff_reward() -> void:
	# TODO: создать UI для увеличения энергии
	pass

func _create_deck_size_buff_reward() -> void:
	# TODO: создать UI для увеличения размера колоды
	pass

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
	# TODO: создать UI для улучшения карты
	pass

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

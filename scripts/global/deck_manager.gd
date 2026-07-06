# autoload/deck_manager.gd
extends Node

## Массив ID карт, которые открыты в мете
var unlocked_card_ids: Array[DataManager.CardId] = []

## Словарь карт по биомам
var cards_by_biome: Dictionary = {}
## Словарь карт по персонажам
var cards_by_character: Dictionary = {}

## Прогресс открытия карт (0.0 - 1.0)
var meta_progress: float = 0.0

func _ready():
	pass

func _load_cards_data() -> void:
	# Загружаем все карты из DataManager
	var all_cards = DataManager.get_all_cards()  # нужно добавить геттер в DataManager
	
	# Группируем по биомам
	for card_id in all_cards.keys():
		var card = all_cards[card_id]
		if card.origin == DataManager.CardOrigin.BIOME:
			if not cards_by_biome.has(card.biome):
				cards_by_biome[card.biome] = []
			cards_by_biome[card.biome].append(card_id)
		elif card.origin == DataManager.CardOrigin.CHARACTER:
			if not cards_by_character.has(card.character_class):
				cards_by_character[card.character_class] = []
			cards_by_character[card.character_class].append(card_id)

func _init_unlocked_cards() -> void:
	# TODO: загружать прогресс из сохранения
	# Пока все карты открыты
	var all_cards = DataManager._cards
	for card_id in all_cards.keys():
		unlocked_card_ids.append(card_id)

## Получить одну карту по биому
func get_card_by_biome(biome: DataManager.Biome, room_progress: int, floor_progress: int) -> CardData:
	var pool = _get_available_cards_by_biome(biome, room_progress, floor_progress)
	if pool.is_empty():
		return null
	return DataManager.get_card(pool[randi() % pool.size()])

## Получить одну карту по персонажу
func get_card_by_character(character: DataManager.CharacterClass, room_progress: int, floor_progress: int) -> CardData:
	var pool = _get_available_cards_by_character(character, room_progress, floor_progress)
	if pool.is_empty():
		return null
	return DataManager.get_card(pool[randi() % pool.size()])

## Получить несколько карт по биому
func get_cards_by_biome(biome: DataManager.Biome, room_progress: int, floor_progress: int, amount: int) -> Array[CardData]:
	var pool = _get_available_cards_by_biome(biome, room_progress, floor_progress)
	var result: Array[CardData] = []
	
	if pool.is_empty():
		return result
	
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	
	for i in range(min(amount, shuffled.size())):
		result.append(DataManager.get_card(shuffled[i]))
	
	return result

## Получить несколько карт по персонажу
func get_cards_by_character(character: DataManager.CharacterClass, room_progress: int, floor_progress: int, amount: int) -> Array[CardData]:
	var pool = _get_available_cards_by_character(character, room_progress, floor_progress)
	var result: Array[CardData] = []
	
	if pool.is_empty():
		return result
	
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	
	for i in range(min(amount, shuffled.size())):
		result.append(DataManager.get_card(shuffled[i]))
	
	return result

## Возвращает доступные карты по биому с учётом прогресса
func _get_available_cards_by_biome(biome: DataManager.Biome, room_progress: int, floor_progress: int) -> Array[DataManager.CardId]:
	var all_cards = cards_by_biome.get(biome, [])
	var available: Array[DataManager.CardId] = []
	
	for card_id in all_cards:
		if card_id in unlocked_card_ids:
			# TODO: добавить фильтрацию по прогрессу (room_progress, floor_progress)
			available.append(card_id)
	
	return available

## Возвращает доступные карты по персонажу с учётом прогресса
func _get_available_cards_by_character(character: DataManager.CharacterClass, room_progress: int, floor_progress: int) -> Array[DataManager.CardId]:
	var all_cards = cards_by_character.get(character, [])
	var available: Array[DataManager.CardId] = []
	
	for card_id in all_cards:
		if card_id in unlocked_card_ids:
			# TODO: добавить фильтрацию по прогрессу (room_progress, floor_progress)
			available.append(card_id)
	
	return available

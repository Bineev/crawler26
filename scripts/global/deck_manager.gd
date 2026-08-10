# autoload/deck_manager.gd
extends Node

## Словарь карт по биомам
var cards_by_biome: Dictionary = {}  # Biome -> Array[CardId]
## Словарь карт по персонажам
var cards_by_character: Dictionary = {}  # CharacterClass -> Array[CardId]

func _ready():
	_load_cards_data()

func _load_cards_data() -> void:
	var all_cards = DataManager.get_all_cards()
	
	# Группируем по биомам
	for card_id in all_cards.keys():
		var card = all_cards[card_id]
		
		match card.origin:
			DataManager.CardOrigin.BIOME:
				if not cards_by_biome.has(card.biome):
					cards_by_biome[card.biome] = []
				cards_by_biome[card.biome].append(card_id)
			
			DataManager.CardOrigin.CHARACTER:
				if not cards_by_character.has(card.character_class):
					cards_by_character[card.character_class] = []
				cards_by_character[card.character_class].append(card_id)

## ============================================================
## СТАРТОВАЯ КОЛОДА
## ============================================================

func get_starting_deck(character_class: DataManager.CharacterClass) -> Array[CardData]:
	var deck: Array[CardData] = []
	
	match character_class:
		DataManager.CharacterClass.PENITENT:
			deck = _get_penitent_starting_deck()
		
		DataManager.CharacterClass.WARRIOR:
			deck = _get_warrior_starting_deck()
		
		DataManager.CharacterClass.MYSTIC:
			deck = _get_mystic_starting_deck()
		
		DataManager.CharacterClass.ROGUE:
			deck = _get_rogue_starting_deck()
		
		_:
			deck = _get_fallback_deck()
	
	return deck

## ============================================================
## ПОЛУЧЕНИЕ КАРТ ДЛЯ НАГРАД
## ============================================================

func get_card_by_biome(biome: DataManager.Biome, room_progress: int = 0, floor_progress: int = 0) -> CardData:
	var pool = _get_available_cards_by_biome(biome, room_progress, floor_progress)
	if pool.is_empty():
		return null
	return DataManager.get_card(pool[randi() % pool.size()])

func get_card_by_character(character: DataManager.CharacterClass, room_progress: int = 0, floor_progress: int = 0) -> CardData:
	var pool = _get_available_cards_by_character(character, room_progress, floor_progress)
	if pool.is_empty():
		return null
	return DataManager.get_card(pool[randi() % pool.size()])

func get_cards_by_biome(biome: DataManager.Biome, room_progress: int = 0, floor_progress: int = 0, amount: int = 3) -> Array[CardData]:
	var pool = _get_available_cards_by_biome(biome, room_progress, floor_progress)
	var result: Array[CardData] = []
	
	if pool.is_empty():
		return result
	
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	
	for i in range(min(amount, shuffled.size())):
		result.append(DataManager.get_card(shuffled[i]))
	
	return result

func get_cards_by_character(character: DataManager.CharacterClass, room_progress: int = 0, floor_progress: int = 0, amount: int = 3) -> Array[CardData]:
	var pool = _get_available_cards_by_character(character, room_progress, floor_progress)
	var result: Array[CardData] = []
	
	if pool.is_empty():
		return result
	
	var shuffled = pool.duplicate()
	shuffled.shuffle()
	
	for i in range(min(amount, shuffled.size())):
		result.append(DataManager.get_card(shuffled[i]))
	
	return result

## ============================================================
## ВНУТРЕННИЕ МЕТОДЫ
## ============================================================

## Возвращает все открытые карты для персонажа
func _get_unlocked_cards_for_character(character: DataManager.CharacterClass) -> Array[DataManager.CardId]:
	var all_cards = cards_by_character.get(character, [])
	var available: Array[DataManager.CardId] = []
	
	for card_id in all_cards:
		if ProgressManager.is_card_unlocked(card_id):
			available.append(card_id)
	
	return available

## Возвращает доступные карты по биому с учётом прогресса
func _get_available_cards_by_biome(biome: DataManager.Biome, room_progress: int, floor_progress: int) -> Array[DataManager.CardId]:
	var all_cards = cards_by_biome.get(biome, [])
	var available: Array[DataManager.CardId] = []
	
	for card_id in all_cards:
		# Проверяем, открыта ли карта в мете
		if not ProgressManager.is_card_unlocked(card_id):
			continue
		
		var card = DataManager.get_card(card_id)
		if not card:
			continue
		
		# TODO: добавить фильтрацию по прогрессу (редкость, стоимость и т.д.)
		# Например, используем card.grade и card.cost
		
		available.append(card_id)
	
	return available

## Возвращает доступные карты по персонажу с учётом прогресса
func _get_available_cards_by_character(character: DataManager.CharacterClass, room_progress: int, floor_progress: int) -> Array[DataManager.CardId]:
	var all_cards = cards_by_character.get(character, [])
	var available: Array[DataManager.CardId] = []
	
	for card_id in all_cards:
		# Проверяем, открыта ли карта в мете
		if not ProgressManager.is_card_unlocked(card_id):
			continue
		
		var card = DataManager.get_card(card_id)
		if not card:
			continue
		
		# TODO: добавить фильтрацию по прогрессу
		
		available.append(card_id)
	
	return available

## ============================================================
## УТИЛИТЫ
## ============================================================

func get_all_cards_for_character(character: DataManager.CharacterClass) -> Array[DataManager.CardId]:
	return cards_by_character.get(character, [])

func get_all_cards_for_biome(biome: DataManager.Biome) -> Array[DataManager.CardId]:
	return cards_by_biome.get(biome, [])


func _get_penitent_starting_deck() -> Array[CardData]:
	var deck: Array[CardData] = []

	# Базовые атаки
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	
	# Базовые атаки (сильные)
	deck.append(DataManager.get_card(DataManager.CardId.SINFUL_STRIKE))
	
	# Утилити
	deck.append(DataManager.get_card(DataManager.CardId.PENITENT_REVELATION))
	deck.append(DataManager.get_card(DataManager.CardId.PENITENT_REVELATION))
	
	# Защита
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	
	return deck

func _get_warrior_starting_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# TODO: реализовать стартовую колоду для WARRIOR
	# Пока используем временную
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.SINFUL_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	
	return deck

func _get_mystic_starting_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# TODO: реализовать стартовую колоду для MYSTIC
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.SINFUL_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	
	return deck

func _get_rogue_starting_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	# TODO: реализовать стартовую колоду для ROGUE
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.SINFUL_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	
	return deck

func _get_fallback_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.SINFUL_STRIKE))
	deck.append(DataManager.get_card(DataManager.CardId.ATONEMENT_BARRIER))
	
	return deck

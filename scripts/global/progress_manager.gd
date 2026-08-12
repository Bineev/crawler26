# autoload/progress_manager.gd
extends Node

## Открытые классы персонажей
var unlocked_classes: Array[DataManager.CharacterClass] = []

## Открытые ID карт
var unlocked_card_ids: Array[DataManager.CardId] = []

## Открытые ID артефактов
var unlocked_artifact_ids: Array[DataManager.ArtifactId] = []

## Мета-валюта (кости)
var meta_currency: int = 0

## Флаги достижений
var achievements: Dictionary = {}

## Статистика забегов
var total_runs: int = 0
var total_victories: int = 0
var total_defeats: int = 0

func _ready():
	_init_default_progress()

func _init_default_progress():
	# ============================================================
	# 1. ОТКРЫТЫЕ КЛАССЫ ПЕРСОНАЖЕЙ
	# ============================================================
	unlocked_classes = [
		DataManager.CharacterClass.PENITENT,
	]
	
	# ============================================================
	# 2. ОТКРЫТЫЕ КАРТЫ
	# ============================================================
	
	# 2.1 Карты Покаянника
	var penitent_cards = [
		DataManager.CardId.ATONEMENT_STRIKE,
		DataManager.CardId.SINFUL_STRIKE,
		DataManager.CardId.PENITENT_REVELATION,
		DataManager.CardId.ATONEMENT_BARRIER,
	]
	for card_id in penitent_cards:
		unlock_card(card_id)
	
	# 2.2 Карты биома Кротовые норы
	var mole_cards = [
		DataManager.CardId.BLOOD_TRAIL,
		DataManager.CardId.FROZEN_EARTH,
		DataManager.CardId.RODENT_AGILITY,
		DataManager.CardId.FROZEN_BITE,
		DataManager.CardId.ROTTEN_CUT,
		DataManager.CardId.BEAST_PULSE,
		DataManager.CardId.BLOOD_THREAD,
		DataManager.CardId.MOLE_TOSS,
		DataManager.CardId.WORM_SPIRIT,
		DataManager.CardId.FLESH_RAGE,
		DataManager.CardId.TORN_WOUND,
	]
	for card_id in mole_cards:
		unlock_card(card_id)
	
	# 2.3 🆕 Карты биома Гнилостные Топи
	var rotten_cards = [
		DataManager.CardId.SNAKE_BITE,
		DataManager.CardId.SWAMP_BLAST,
		DataManager.CardId.BLESSING_OF_ROT,
		DataManager.CardId.WEAK_SPOT,
		DataManager.CardId.BLOOM_OF_CORRUPTION,
		DataManager.CardId.MUD_SPLASH,
		DataManager.CardId.BLOOD_INFECTION,
		DataManager.CardId.EPIDEMIC,
		DataManager.CardId.FOUL_WELL,
		DataManager.CardId.STING_OF_CORRUPTION,
	]
	for card_id in rotten_cards:
		unlock_card(card_id)
	
	# ============================================================
	# 3. ОТКРЫТЫЕ АРТЕФАКТЫ (все существующие)
	# ============================================================
	unlocked_artifact_ids = [
		DataManager.ArtifactId.STRANGE_MUSHROOM,
		DataManager.ArtifactId.HEROS_BROOCH,
		DataManager.ArtifactId.KINGS_ORDER,
		DataManager.ArtifactId.HEALERS_AMULET,
		DataManager.ArtifactId.ABYSS_DUST,
		DataManager.ArtifactId.TROLL_BLADE,
		DataManager.ArtifactId.IMP_BLADE,
		DataManager.ArtifactId.PLAGUE_AMULET,
	]
	
	meta_currency = 0

## ============================================================
## МЕТОДЫ ДЛЯ РАЗБЛОКИРОВКИ
## ============================================================

func unlock_card(card_id: DataManager.CardId) -> bool:
	if card_id in unlocked_card_ids:
		return false
	unlocked_card_ids.append(card_id)
	return true

func unlock_class(character_class: DataManager.CharacterClass) -> bool:
	if character_class in unlocked_classes:
		return false
	unlocked_classes.append(character_class)
	return true

func unlock_artifact(artifact_id: DataManager.ArtifactId) -> bool:
	if artifact_id in unlocked_artifact_ids:
		return false
	unlocked_artifact_ids.append(artifact_id)
	return true

## ============================================================
## ПРОВЕРКИ
## ============================================================

func is_class_unlocked(character_class: DataManager.CharacterClass) -> bool:
	return character_class in unlocked_classes

func is_card_unlocked(card_id: DataManager.CardId) -> bool:
	return card_id in unlocked_card_ids

func is_artifact_unlocked(artifact_id: DataManager.ArtifactId) -> bool:
	return artifact_id in unlocked_artifact_ids

## ============================================================
## МЕТОДЫ ДЛЯ СОХРАНЕНИЯ/ЗАГРУЗКИ
## ============================================================

func save_progress():
	# TODO: сохранять в файл
	pass

func load_progress():
	# TODO: загружать из файла
	pass

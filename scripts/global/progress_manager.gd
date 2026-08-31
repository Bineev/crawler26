# autoload/progress_manager.gd
extends Node


## ============================================================
## ПРОГРЕСС ПЕРСОНАЖА (общий, накапливается)
## ============================================================

var character_experience: Dictionary = {}  # CharacterClass -> int (общий опыт)
var character_level: Dictionary = {}      # CharacterClass -> int (текущий уровень)

## ============================================================
## ПРОГРЕСС БИОМА (общий, накапливается)
## ============================================================

var biome_experience: Dictionary = {}  # Biome -> int (общий опыт)
var biome_level: Dictionary = {}       # Biome -> int (текущий уровень)

## ============================================================
## КОПИИ НА СТАРТЕ ЗАБЕГА (для отслеживания прогресса за забег)
## ============================================================

var run_start_character_experience: Dictionary = {}  # CharacterClass -> int
var run_start_character_level: Dictionary = {}      # CharacterClass -> int
var run_start_biome_experience: Dictionary = {}     # Biome -> int
var run_start_biome_level: Dictionary = {}          # Biome -> int

## ============================================================
## БИОМЫ (доступные для выбора)
## ============================================================

## Все доступные биомы в игре
var all_biomes: Array[DataManager.Biome] = [
	DataManager.Biome.MOLE_TUNNELS,
	DataManager.Biome.ROTTEN_MARSHES,
	# DataManager.Biome.FLESH_CAVES,  # позже
	# DataManager.Biome.BONE_LABYRINTH,  # позже
]

## Текущие доступные биомы для выбора (копия, будет изменяться)
var available_biomes: Array[DataManager.Biome] = []

## Выбранный биом (для текущего забега)
var selected_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

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

## ============================================================
## КАРТЫ ДЛЯ РАЗБЛОКИРОВКИ ПО УРОВНЯМ
## ============================================================

## Карты персонажа (по классам и уровням)
var character_unlock_cards: Dictionary = {
	# Penitent
	DataManager.CharacterClass.PENITENT: {
		1: [  # уровень 0→1
			DataManager.CardId.BLOOD_SACRIFICE,
			DataManager.CardId.PRICE_OF_DESPAIR,
		],
		2: [  # уровень 1→2
			DataManager.CardId.SCOURING_FLAME,
			DataManager.CardId.SIN_OF_VANITY,
			DataManager.CardId.THIRST_FOR_PUNISHMENT,
		],
		3: [  # уровень 2→3
			DataManager.CardId.SHIELD_OF_PENANCE,
			DataManager.CardId.VOID_STRIKE,
			DataManager.CardId.CRY_OF_DESPAIR,
			DataManager.CardId.PURE_THOUGHTS,
		],
	},
	# TODO: WARRIOR, MYSTIC, ROGUE
}

## Карты биомов (по биомам и уровням)
var biome_unlock_cards: Dictionary = {
	DataManager.Biome.MOLE_TUNNELS: {
		1: [  # уровень 0→1
			DataManager.CardId.BLOOD_TRAIL,
			DataManager.CardId.FROZEN_EARTH,
		],
		2: [  # уровень 1→2
			DataManager.CardId.RODENT_AGILITY,
			DataManager.CardId.FROZEN_BITE,
			DataManager.CardId.ROTTEN_CUT,
		],
		3: [  # уровень 2→3
			DataManager.CardId.BEAST_PULSE,
			DataManager.CardId.BLOOD_THREAD,
			DataManager.CardId.MOLE_TOSS,
			DataManager.CardId.WORM_SPIRIT,
			DataManager.CardId.FLESH_RAGE,
			DataManager.CardId.TORN_WOUND,
		],
	},
	DataManager.Biome.ROTTEN_MARSHES: {
		1: [  # уровень 0→1
			DataManager.CardId.SNAKE_BITE,
			DataManager.CardId.MUD_SPLASH,
		],
		2: [  # уровень 1→2
			DataManager.CardId.WEAK_SPOT,
			DataManager.CardId.BLOOD_INFECTION,
			DataManager.CardId.STING_OF_CORRUPTION,
		],
		3: [  # уровень 2→3
			DataManager.CardId.SWAMP_BLAST,
			DataManager.CardId.BLESSING_OF_ROT,
			DataManager.CardId.BLOOM_OF_CORRUPTION,
			DataManager.CardId.FOUL_WELL,
			DataManager.CardId.EPIDEMIC,
		],
	},
}


func _ready():
	_init_default_progress()
	reset_available_biomes()


func reset_available_biomes():
	available_biomes = all_biomes.duplicate()


func get_random_biomes(count: int = 2) -> Array[DataManager.Biome]:
	var pool = available_biomes.duplicate()
	pool.shuffle()
	
	var result: Array[DataManager.Biome] = []
	for i in range(min(count, pool.size())):
		result.append(pool[i])
	
	return result


func select_biome(biome: DataManager.Biome) -> bool:
	if biome not in available_biomes:
		return false
	
	available_biomes.erase(biome)
	selected_biome = biome
	return true


func is_biome_available(biome: DataManager.Biome) -> bool:
	return biome in available_biomes


func get_biome_count() -> int:
	return available_biomes.size()


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
		DataManager.CardId.BLACK_ENVY,  # 🆕
		DataManager.CardId.TIME_TO_DIE,  # 🆕
		DataManager.CardId.BITTER_VENGEANCE,  # 🆕
		DataManager.CardId.PURE_THOUGHTS,  # 🆕
		DataManager.CardId.BLIND_VENGEANCE,  # 🆕
		DataManager.CardId.GRIP_OF_DESPAIR,  # 🆕
		DataManager.CardId.FORGIVENESS,  # 🆕
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

	# Инициализация прогресса
	character_experience.clear()
	character_level.clear()
	biome_experience.clear()
	biome_level.clear()
	
	for class_type in DataManager.CharacterClass.values():
		character_experience[class_type] = 0
		character_level[class_type] = 0
	
	for biome in DataManager.Biome.values():
		biome_experience[biome] = 0
		biome_level[biome] = 0

	run_start_character_experience.clear()
	run_start_character_level.clear()
	run_start_biome_experience.clear()
	run_start_biome_level.clear()

## ============================================================
## СОХРАНЕНИЕ КОПИЙ НА СТАРТЕ ЗАБЕГА
## ============================================================

func save_run_start_snapshot() -> void:
	run_start_character_experience = character_experience.duplicate()
	run_start_character_level = character_level.duplicate()
	run_start_biome_experience = biome_experience.duplicate()
	run_start_biome_level = biome_level.duplicate()
	print("=== RUN START SNAPSHOT SAVED ===")


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


## ============================================================
## ДОБАВЛЕНИЕ ОПЫТА
## ============================================================

func add_character_experience(character_class: DataManager.CharacterClass, amount: int) -> void:
	if not character_experience.has(character_class):
		character_experience[character_class] = 0
	if not character_level.has(character_class):
		character_level[character_class] = 0
	
	character_experience[character_class] += amount


func add_biome_experience(biome: DataManager.Biome, amount: int) -> void:
	if not biome_experience.has(biome):
		biome_experience[biome] = 0
	if not biome_level.has(biome):
		biome_level[biome] = 0
	
	biome_experience[biome] += amount

## ============================================================
## РАСЧЁТ УРОВНЯ ПО ТЕКУЩЕМУ ОПЫТУ
## ============================================================

func calculate_character_level(character_class: DataManager.CharacterClass) -> int:
	var total_xp = character_experience.get(character_class, 0)
	var level = 0
	var required_xp = get_required_xp_for_character_level(level)
	
	while total_xp >= required_xp:
		total_xp -= required_xp
		level += 1
		required_xp = get_required_xp_for_character_level(level)
	
	return level


func calculate_biome_level(biome: DataManager.Biome) -> int:
	var total_xp = biome_experience.get(biome, 0)
	var level = 0
	var required_xp = get_required_xp_for_biome_level(level)
	
	while total_xp >= required_xp:
		total_xp -= required_xp
		level += 1
		required_xp = get_required_xp_for_biome_level(level)
	
	return level


## ============================================================
## ПОЛУЧЕНИЕ ПРОГРЕССА ЗА ТЕКУЩИЙ ЗАБЕГ
## ============================================================

func get_run_character_xp_gain(character_class: DataManager.CharacterClass) -> int:
	var start = run_start_character_experience.get(character_class, 0)
	var current = character_experience.get(character_class, 0)
	return max(0, current - start)


func get_run_biome_xp_gain(biome: DataManager.Biome) -> int:
	var start = run_start_biome_experience.get(biome, 0)
	var current = biome_experience.get(biome, 0)
	return max(0, current - start)


## ============================================================
## МЕТОДЫ ДЛЯ РАСЧЁТА ТРЕБУЕМОГО ОПЫТА
## ============================================================

func get_required_xp_for_character_level(level: int) -> int:
	var multiplier = DataManager.XP_CHARACTER_MULTIPLIER * pow(2, level)
	return floor(DataManager.XP_BASE * multiplier)


func get_required_xp_for_biome_level(level: int) -> int:
	var multiplier = DataManager.XP_BIOME_MULTIPLIER * pow(2, level)
	return DataManager.XP_BASE * multiplier


## ============================================================
## ОТКРЫТИЕ КАРТ (ПОКА ЗАГЛУШКИ)
## ============================================================


func _get_character_cards_for_level(character_class: DataManager.CharacterClass, level: int) -> Array[DataManager.CardId]:
	# TODO: определить, какие карты открываются на каждом уровне
	return []


func _get_biome_cards_for_level(biome: DataManager.Biome, level: int) -> Array[DataManager.CardId]:
	# TODO: определить, какие карты открываются на каждом уровне
	return []


## Добавляет опыт за пройденную комнату
func add_experience_for_room(room: Room) -> void:
	var xp_amount = 0
	var character_class = RunManager.current_character
	var biome = room.current_biome
	
	match room.room_type:
		DataManager.RoomType.COMBAT:
			match room.combat_type:
				DataManager.CombatType.NORMAL:
					xp_amount = DataManager.XP_PER_COMBAT
				DataManager.CombatType.ELITE:
					xp_amount = DataManager.XP_PER_ELITE
				DataManager.CombatType.CONCRETE_COMBAT:
					xp_amount = DataManager.XP_PER_CONCRETE
				DataManager.CombatType.BOSS:
					xp_amount = DataManager.XP_PER_BOSS
				_:
					xp_amount = DataManager.XP_PER_COMBAT
		
		DataManager.RoomType.OBJECT:
			xp_amount = DataManager.XP_PER_OBJECT
		
		DataManager.RoomType.EVENT:
			xp_amount = DataManager.XP_PER_EVENT
		
		_:
			xp_amount = 0
	
	if xp_amount > 0:
		add_character_experience(character_class, xp_amount)
		add_biome_experience(biome, xp_amount)
		SignalManager.log_message.emit("Получено %d опыта" % xp_amount)
		print("=== XP GAIN ===")
		print("Комната: ", room.room_type, " (", room.combat_type if room.room_type == DataManager.RoomType.COMBAT else "N/A", ")")
		print("Опыт: +", xp_amount)
		print("Персонаж (", DataManager.CharacterClass.keys()[character_class], "): XP=", character_experience[character_class], " LVL=", character_level[character_class])
		print("Биом (", DataManager.get_biome_name(biome), "): XP=", biome_experience[biome], " LVL=", biome_level[biome])
		print("==================")


func calculate_character_level_from_snapshot(character_class: DataManager.CharacterClass) -> int:
	var total_xp = run_start_character_experience.get(character_class, 0)
	var level = 0
	var required_xp = get_required_xp_for_character_level(level)
	
	while total_xp >= required_xp:
		total_xp -= required_xp
		level += 1
		required_xp = get_required_xp_for_character_level(level)
	
	return level


func calculate_biome_level_from_snapshot(biome: DataManager.Biome) -> int:
	var total_xp = run_start_biome_experience.get(biome, 0)
	var level = 0
	var required_xp = get_required_xp_for_biome_level(level)
	
	while total_xp >= required_xp:
		total_xp -= required_xp
		level += 1
		required_xp = get_required_xp_for_biome_level(level)
	
	return level


## ============================================================
## РАСЧЁТ ЛЕВЕЛ-АПОВ ЗА ЗАБЕГ
## ============================================================

## Проверяет левел-апы персонажа за забег и разблокирует карты
func process_character_level_ups(character_class: DataManager.CharacterClass) -> Array[DataManager.CardId]:
	var unlocked_cards: Array[DataManager.CardId] = []
	
	var start_level = calculate_character_level_from_snapshot(character_class)
	var current_level = calculate_character_level(character_class)
	
	# Проходим по всем уровням, которые были достигнуты за забег
	for level in range(start_level + 1, current_level + 1):
		var cards = _unlock_character_cards(character_class, level)
		unlocked_cards.append_array(cards)
	
	return unlocked_cards


## Проверяет левел-апы биома за забег и разблокирует карты
func process_biome_level_ups(biome: DataManager.Biome) -> Array[DataManager.CardId]:
	var unlocked_cards: Array[DataManager.CardId] = []
	
	var start_level = calculate_biome_level_from_snapshot(biome)
	var current_level = calculate_biome_level(biome)
	
	# Проходим по всем уровням, которые были достигнуты за забег
	for level in range(start_level + 1, current_level + 1):
		var cards = _unlock_biome_cards(biome, level)
		unlocked_cards.append_array(cards)
	
	return unlocked_cards


## ============================================================
## ВНУТРЕННИЕ МЕТОДЫ РАЗБЛОКИРОВКИ (возвращают массив открытых карт)
## ============================================================

func _unlock_character_cards(character_class: DataManager.CharacterClass, level: int) -> Array[DataManager.CardId]:
	var unlocked: Array[DataManager.CardId] = []
	var cards = character_unlock_cards.get(character_class, {}).get(level, [])
	
	for card_id in cards:
		if not is_card_unlocked(card_id):
			unlocked_card_ids.append(card_id)
			unlocked.append(card_id)
			print("🔓 Открыта карта персонажа: %s" % DataManager.get_card(card_id).get_localized_name())
			SignalManager.log_message.emit("Открыта карта: %s" % DataManager.get_card(card_id).get_localized_name())
	
	return unlocked


func _unlock_biome_cards(biome: DataManager.Biome, level: int) -> Array[DataManager.CardId]:
	var unlocked: Array[DataManager.CardId] = []
	var cards = biome_unlock_cards.get(biome, {}).get(level, [])
	
	for card_id in cards:
		if not is_card_unlocked(card_id):
			unlocked_card_ids.append(card_id)
			unlocked.append(card_id)
			print("🔓 Открыта карта биома: %s" % DataManager.get_card(card_id).get_localized_name())
			SignalManager.log_message.emit("Открыта карта биома: %s" % DataManager.get_card(card_id).get_localized_name())
	
	return unlocked


## ============================================================
## ОБЩАЯ ФУНКЦИЯ ДЛЯ ЭКРАНА СМЕРТИ
## ============================================================

## Проверяет все левел-апы за забег и возвращает словарь с открытыми картами
func process_all_level_ups() -> Dictionary:
	var character_class = RunManager.current_character
	var biome = RunManager.current_biome
	
	var result = {
		"character_unlocked": process_character_level_ups(character_class),
		"biome_unlocked": process_biome_level_ups(biome),
	}
	
	return result

# data_manager.gd
extends Node

## ============================================================
## 1. ОСНОВНЫЕ ПЕРЕЧИСЛЕНИЯ (ENUMS)
## ============================================================


## ============================================================
## СОСТОЯНИЯ КАРТ
## ============================================================

enum CardState {
	IDLE,
	HOVERED,
	SELECTED,
	AIMING,
	PLAYED,
	BURNED,
}


enum BattleState {
	IDLE,
	PLAYER_TURN,
	ENEMY_TURN,
	VICTORY,
	DEFEAT
}
## Базовые статы (flats) — числовые характеристики
enum FlatStat {
	HEALTH,
	MAX_HEALTH,
	ENERGY,
	MAX_ENERGY,
	#BLOCK,
	HAND_SIZE,
	DRAW_PER_TURN,
	ATONEMENT,
	MAX_ATONEMENT
}

enum ModifierChangeType {
	MULTIPLIER,   # умножение (1.25 = +25%)
	PERCENT,      # процентное изменение (0.25 = +25%)
	FLAT_BONUS,   # флэт-бонус (+5)
}

## Модификаторы статов (проценты / множители)
enum ModifierStat {
	DAMAGE_DEALT_PERCENT,      # +X% урона
	DAMAGE_TAKEN_PERCENT,      # +X% входящего урона
	BLOCK_GAINED_PERCENT,      # +X% получаемого блока
	HEALING_RECEIVED_PERCENT,  # +X% получаемого лечения
	ATONEMENT_GAIN_MULTIPLIER, # множитель получения Искупления
	DAMAGE_FLAT_BONUS,         # СИЛА (+X к урону)
}

enum CardOrigin {
	CHARACTER,  # карта персонажа
	BIOME,      # карта биома
}

enum GrowType {
	NONE,       # не растёт
	ADD,        # +value_grow_value каждый раз
	SUBTRACT,   # -value_grow_value каждый раз
	MULTIPLY,   # × value_grow_value каждый раз
	DIVIDE,     # / value_grow_value каждый раз
}

enum GrowTarget {
	VALUE,      # растёт value (стаки или величина эффекта)
	DURATION,   # растёт длительность
	BASE_VALUE, # растёт base_value (для DAMAGE/BLOCK/HEAL)
	BOTH,       # растёт и value, и duration
}

enum PassiveTrigger {
	ON_TAKE_DAMAGE,
	ON_DEAL_DAMAGE,
	ON_PLAY_CARD,
	ON_APPLY_STATUS,
	ON_GAIN_BLOCK,
	ON_TURN_START,
	ON_TURN_END,
	ON_KILL_ENEMY,
	ON_STATUS_TICK,
}

## Типы эффектов карт
enum EffectCategory {
	DAMAGE,
	BLOCK,
	HEAL,
	SCALED_VALUE,
	APPLY_STATUS,
	APPLY_PASSIVE,
	MODIFY_STAT,
	MODIFY_MODIFIER,
	DRAW_CARD,
	GAIN_ENERGY,
	SACRIFICE_CARD,
	CONVERT,
	CONVERT_STATUS,  # ← новый тип
	CONVERT_EXCESS_TO_BLOCK,
	CONDITIONAL,
	CUSTOM,
}

## Тип значения для SCALED_VALUE эффекта
enum ScaledType {
	DAMAGE,
	BLOCK,
	HEAL,
	GAIN_ENERGY,
	DRAW_CARD,
	APPLY_STATUS,  # ← добавить
}

enum ScaledResource {
	ATONEMENT,
	HEALTH,
	MAX_HEALTH,
	ENERGY,
	BLOCK,
	ENEMY_STATUSES,
	PLAYER_STATUSES,
	BURN_STACKS,
	POISON_STACKS,
	BLEED_STACKS,
}

enum ScaledCompare {
	GREATER_EQUAL,   # значение >= порога
	LESSER_EQUAL,    # значение <= порога
	GREATER,         # значение > порога
	LESSER,          # значение < порога
	EQUAL,           # значение == порога
}

## Тип цикла намерений
enum IntentCycleType {
	SEQUENTIAL,
	RANDOM,
	RANDOM_WITHOUT_REPEAT,
}

## Цель эффекта
enum EffectTarget {
	SELF,
	ENEMY,
	ALL_ENEMIES,
	ALL_ALLIES,
	ANY,
}

## Типы зарядов пассивок
enum PassiveChargeType {
	PERMANENT,
	TURN_BASED,
	USAGE_BASED,
	CONDITIONAL,
}

## Все возможные пассивки
enum Passive {
	# Кротовые норы
	REGROWTH,
	VENOMOUS_SHIELD,
	WRATH,
	FREEZING_GROUND,
	DENIAL,
	SHAME,
	# Пещеры плоти
	FLESH_WARD,
	CRIMSON_FRENZY,
}

## Все возможные статусы
enum Status {
	POISON,
	BLEED,
	BURN,
	COLD,
	WEAKNESS,
	VULNERABILITY,
	STRENGTH,
	REGEN,
	SHIELD,
}

## Классы персонажей
enum CharacterClass {
	PENITENT,
	WARRIOR,
	MYSTIC,
	ROGUE,
}

## Грейды карт
enum CardGrade {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY,
	MYTHIC,
}

## Типы карт
enum CardType {
	ATTACK,
	DEFEND,
	BUFF_SELF,
	DEBUFF,
	HEAL,
	RESOURCE,
	UTILITY,
}

## Теги карт
enum CardTag {
	BURNS,      # сгорающая (не попадает в сброс)
}

enum CardId {
	# Сломленный (Penitent) - 12 карт
	ATONEMENT_STRIKE,      # Удар расплаты
	SINFUL_STRIKE,         # Греховный выпад
	PENITENT_REVELATION,   # Покаянное откровение
	ATONEMENT_BARRIER,     # Искупительный барьер
	BLOOD_SACRIFICE,       # Кровавая жертва
	PRICE_OF_DESPAIR,      # Цена отчаяния
	SCOURING_FLAME,        # Очищающее пламя
	SIN_OF_VANITY,         # Грех тщеславия
	THIRST_FOR_PUNISHMENT, # Жажда кары
	SHIELD_OF_PENANCE,     # Щит покаяния
	VOID_STRIKE,           # Удар пустоты
	CRY_OF_DESPAIR,        # Крик отчаяния
	
	# Кротовые норы (Mole Tunnels) - 5 карт
	BLIND_FURY,            # Слепая ярость
	SMELL_OF_BLOOD,        # Запах крови
	MOLERAT_HIDE,          # Шкура кротокрыса
	TUNNEL_AMBUSH,         # Туннельная засада
	BLOODLETTING,          # Кровопускание
}

## Намерения врагов
enum IntentType {
	ATTACK,         # атака
	DEFEND,         # защита (блок)
	BUFF,           # усиление себя
	DEBUFF,         # ослабление игрока (включая статусы и пассивки)
	UNKNOWN,        # неизвестное намерение (знак вопроса)
	SUMMON,         # призыв союзников
	HEAL,           # лечение
}

## ============================================================
## БИОМЫ И ВРАГИ
## ============================================================

enum Biome {
	MOLE_TUNNELS,       # Кротовые норы
	FLESH_CAVES,        # Пещеры плоти
	BONE_LABYRINTH,     # Костяной лабиринт
	FROZEN_DEPTHS,      # Ледяные глубины (на будущее)
	MAGMA_CORE,         # Ядро магмы (на будущее)
}

## Враги Кротовых нор
enum MoleEnemy {
	MOLE_MUTANT,        # Слепыш-мутант
	STRONG_MOLE,        # Крот-силач
	RABID_RAT,          # Бешеная крыса
	MOLE_FUNGUS,        # Крот-гриб
	MANY_HEADED_MOLE,   # Многоголовый слепыш
	FUNGAL_MINER,       # Шахтёр-гриб
	RODENT_MOUND,       # Гора грызунов (босс)
}

## Тип комнаты
enum RoomType {
	COMBAT,      # бой
	EVENT,       # эвент (нарратив)
	OBJECT,      # объект (интерактив)
}

## Тип боя
enum CombatType {
	NORMAL,           # обычный бой
	ELITE,            # элитный бой
	LIMITED_TURNS,    # бой с ограниченным количеством ходов
	BOSS,             # босс файт
}

## Тип эвента
enum EventType {
	NARRATIVE,       # чистый нарратив (диалог, выбор)
	# при необходимости можно расширять
}

## Тип объекта
enum ObjectType {
	SHOP,            # магазин
	IDOL,            # идол (алтарь)
	TRAP,            # ловушка
	CHEST,           # сундук
	CAULDRON,        # котел
	TORTURE_RACK,    # пыточный стол
	BONFIRE,         # костер
}

enum EnemySize {
	WEAK,      # 192x192
	NORMAL,    # 256x256
	ELITE,     # 320x320
	BOSS,      # 460x460
}
## ============================================================
## КОМНАТЫ И РАЗВИЛКИ
## ============================================================

enum RoomReveal {
	KNOWN,      # тип комнаты виден игроку
	HIDDEN,     # знак вопроса
}

## ============================================================
## НАСТРОЙКИ ЭТАЖА
## ============================================================

const FLOOR_ROOMS_PER_PATH: int = 3           # комнат в одном пути
const FLOOR_VISIBLE_ROOMS: int = 1            # видимых комнат в пути
const FLOOR_PATHS_COUNT: int = 2              # количество путей на развилке
const FLOOR_SEGMENTS_BEFORE_BOSS: int = 3     # сегментов (развилок) до босса
## ============================================================
## 2. БАЛАНСНЫЕ КОНСТАНТЫ
## ============================================================

## === Основные лимиты ===
const STARTING_HAND_SIZE: int = 5
const CARDS_TO_DRAW_PER_TURN: int = 5
const STARTING_ENERGY: int = 3
const MAX_ENERGY: int = 3

## === Сломленный (Penitent) ===
const PENITENT_STARTING_HEALTH: int = 80
const PENITENT_MAX_ATONEMENT: int = 30
const PENITENT_ATONEMENT_GAIN_PER_DAMAGE: int = 0.2

## === Статусы ===

const POISON_BASE_DAMAGE_PER_STACK: int = 1
const POISON_TICK_INTERVAL: int = 1

const BLEED_BASE_DAMAGE_PER_STACK: int = 5
const BLEED_TICK_INTERVAL: int = 2

const BURN_BASE_DAMAGE_PER_STACK: int = 2
const BURN_TICK_INTERVAL: int = 1
const BURN_THRESHOLD_STACKS: int = 10
const BURN_EXPLOSION_DAMAGE_PER_STACK: int = 3
const BURN_STRENGTH_STACKS: int = 1
const BURN_STRENGTH_DURATION: int = 2

const COLD_EFFECT_PERCENT_PER_STACK: float = 0.01
const COLD_MIN_EFFECT_MULTIPLIER: float = 0.75

const WEAKNESS_DAMAGE_MULTIPLIER: float = 0.75
const VULNERABILITY_DAMAGE_MULTIPLIER: float = 1.5

const DESPAIR_DURATION: int = 2
const DESPAIR_DAMAGE_DEALT_MULTIPLIER: float = 0.75

## === Пассивки ===

const REGROWTH_STARTING_HEAL: int = 2
const REGROWTH_INCREMENT: int = 1

const VENOMOUS_SHIELD_POISON_STACKS: int = 1
const VENOMOUS_SHIELD_POISON_DURATION: int = 2

const WRATH_STRENGTH_GAIN_PER_TURN: int = 1

const FREEZING_GROUND_ICE_STACKS: int = 5
const FREEZING_GROUND_RECHARGE_TURN: int = 6

const DENIAL_STARTING_CHARGES: int = 3

const STRENGTH_FLAT_BONUS_PER_STACK: int = 1
const REGEN_HEAL_PER_STACK: int = 1

const SHAME_DURATION: int = 2
const SHAME_DAMAGE_TAKEN_MULTIPLIER: float = 1.25
const SHAME_ATONEMENT_MULTIPLIER: float = 2.0

## === Карты Сломленного ===

const ATONEMENT_STRIKE_DAMAGE: int = 8
const SINFUL_STRIKE_DAMAGE: int = 10

const PENITENT_REVELATION_THRESHOLD_1: int = 10
const PENITENT_REVELATION_THRESHOLD_2: int = 20
const PENITENT_REVELATION_THRESHOLD_3: int = 30
const PENITENT_REVELATION_DRAW_1: int = 1
const PENITENT_REVELATION_DRAW_2: int = 2
const PENITENT_REVELATION_DRAW_3: int = 3

const REDEMPTIVE_BARRIER_SELF_DAMAGE: int = 5
const REDEMPTIVE_BARRIER_BLOCK_TIER_1: int = 10
const REDEMPTIVE_BARRIER_BLOCK_TIER_2: int = 16
const REDEMPTIVE_BARRIER_BLOCK_TIER_3: int = 22

const BLOOD_SACRIFICE_SELF_DAMAGE: int = 5
const BLOOD_SACRIFICE_ATONEMENT_GAIN: int = 30

const PRICE_OF_DESPAIR_HEAL_TIER_1: int = 6
const PRICE_OF_DESPAIR_HEAL_TIER_2: int = 11
const PRICE_OF_DESPAIR_HEAL_TIER_3: int = 15

const SCOURING_FLAME_SELF_DAMAGE_PER_STATUS: int = 3
const SCOURING_FLAME_ATONEMENT_PER_STATUS: int = 5

const SIN_OF_VANITY_BASE_DAMAGE: int = 4
const SIN_OF_VANITY_BONUS_PER_STATUS: int = 2

const THIRST_FOR_PUNISHMENT_SELF_DAMAGE: int = 5
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_1: int = 1
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_2: int = 2
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_3: int = 3

const SHIELD_OF_PENANCE_BASE_BLOCK: int = 5
const SHIELD_OF_PENANCE_BONUS_BLOCK: int = 5
const SHIELD_OF_PENANCE_STATUS_THRESHOLD: int = 2

const VOID_STRIKE_BASE_DAMAGE: int = 6
const VOID_STRIKE_BONUS_DAMAGE_IF_ZERO_ATONEMENT: int = 4

const CRY_OF_DESPAIR_DAMAGE: int = 5
const CRY_OF_DESPAIR_HEAL_TIER_1: int = 5
const CRY_OF_DESPAIR_HEAL_TIER_2: int = 10
const CRY_OF_DESPAIR_HEAL_TIER_3: int = 15


## ============================================================
## 3. РАЗМЕРЫ КАРТ
## ============================================================
#const CARD_HAND_Y_OFFSET: int = -80     # отступ от нижнего края
const CARD_HAND_Y_OFFSET: int = -100     # отступ от нижнего края
const CARD_BASE_WIDTH: int = 234
const CARD_BASE_HEIGHT: int = 330
const CARD_ART_SIZE: int = 164
const CARD_ICON_SIZE: int = 32
const CARD_ICON_SOURCE_SIZE: int = 64

const CARD_SCALE_NORMAL: float = 1.0
const CARD_SCALE_IN_HAND: float = 1
const CARD_SCALE_HOVER: float = 1.2
const CARD_HOVER_RAISE: int = 180  # высота подъёма при наведении
const CARD_HOVER_CENTER_FORCE: float = 0.02 # сила притяжения к центру (0-1)
const CARD_HAND_WIDTH: int = int(CARD_BASE_WIDTH * CARD_SCALE_IN_HAND)
const CARD_HAND_HEIGHT: int = int(CARD_BASE_HEIGHT * CARD_SCALE_IN_HAND)
const CARD_SPACING_IN_HAND: int = -60


## ============================================================
## 4. РАЗМЕРЫ ЭКРАНА
## ============================================================

const SCREEN_WIDTH: int = 1920
const SCREEN_HEIGHT: int = 1080

const PORTRAIT_POS: Vector2 = Vector2(50, 80)
const PORTRAIT_SIZE: Vector2 = Vector2(200, 200)
const ARTIFACT_POS: Vector2 = Vector2(50, 300)
const ARTIFACT_ICON_SIZE: Vector2 = Vector2(48, 48)
const RESOURCE_PANEL_POS: Vector2 = Vector2(50, 860)
const RESOURCE_PANEL_SIZE: Vector2 = Vector2(200, 60)

const BATTLE_SCENE_POS: Vector2 = Vector2(448, 80)
const BATTLE_SCENE_SIZE: Vector2 = Vector2(1024, 768)

const ENEMY_INTENT_POS: Vector2 = Vector2(312, 138)
const ENEMY_SPRITE_SIZE: Vector2 = Vector2(400, 500)
const ENEMY_POS_IN_SCENE: Vector2 = Vector2(312, 188)
const ENEMY_STATUS_POS: Vector2 = Vector2(312, 688)

const HAND_POS: Vector2 = Vector2(448, 860)
const HAND_SIZE: Vector2 = Vector2(1024, 220)

const LOG_PANEL_POS: Vector2 = Vector2(1520, 80)
const LOG_PANEL_SIZE: Vector2 = Vector2(350, 500)
const HINT_PANEL_POS: Vector2 = Vector2(1520, 580)
const HINT_PANEL_SIZE: Vector2 = Vector2(350, 268)

const LOCATION_SPRITE_SIZE: Vector2 = Vector2(1024, 768)


## ============================================================
## 5. КОЛОДА
## ============================================================

const MAX_HAND_SIZE: int = 5
## ============================================================
## НАСТРОЙКИ ПОДБОРА ВРАГОВ
## ============================================================

# Сложность (прогресс на этаже)
const DIFFICULTY_MAX_PROGRESS: int = 10  # максимальный прогресс для фактора сложности

# Пороги сложности для обычных боёв
const NORMAL_DIFFICULTY_EARLY: float = 0.2   # 0-20% - начало этажа
const NORMAL_DIFFICULTY_MID: float = 0.5     # 20-50% - середина этажа
const NORMAL_DIFFICULTY_LATE: float = 0.8    # 50-80% - поздний этаж

# Пороги сложности для элитных боёв
const ELITE_DIFFICULTY_EARLY: float = 0.3    # 0-30% - начало этажа
const ELITE_DIFFICULTY_LATE: float = 0.7     # 30-70% - середина

# Количество врагов в обычных боях
const NORMAL_ENEMY_COUNT_EARLY: int = 1      # первая комната
const NORMAL_ENEMY_COUNT_MID: int = 2        # середина
const NORMAL_ENEMY_COUNT_LATE_MIN: int = 2   # минимум в поздней
const NORMAL_ENEMY_COUNT_LATE_MAX: int = 3   # максимум в поздней

# Количество врагов в элитных боях
const ELITE_ENEMY_COUNT_EARLY: int = 1       # начало
const ELITE_ENEMY_COUNT_MID: int = 2         # середина
const ELITE_ENEMY_COUNT_LATE: int = 2        # конец

# Этаж появления миньонов у босса
const BOSS_ADD_MINIONS_FROM_FLOOR: int = 3

# Этаж появления элитных врагов Fungal Miner
const ELITE_MINER_APPEARS_FROM_FLOOR: int = 3
## ============================================================
## РАЗМЕРЫ КОМНАТЫ
## ============================================================

const ROOM_WIDTH: int = 1024
const ROOM_HEIGHT: int = 800
const ROOM_CENTER_X: int = ROOM_WIDTH / 2  # 512
const ROOM_CENTER_Y: int = ROOM_HEIGHT / 2  # 400
const ROOM_POSITION: Vector2 = Vector2(448, -80)
const END_BUTTON_POSITION: Vector2 = Vector2(1600, 860)
## ============================================================
## РАЗМЕРЫ ВРАГОВ
## ============================================================

const ENEMY_SPACING: int = 40
const ENEMY_Y_OFFSET_FROM_BOTTOM: int = 150  # отступ от нижней границы


const sound_delay: int = 50  # задержка между одинаковыми звуками в мс
const max_sounds: int = 8    # максимальное количество одновременных звуков
## ============================================================
## 6. ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func is_negative_status(status: Status) -> bool:
	return status in [
		Status.POISON,
		Status.BLEED,
		Status.BURN,
		Status.COLD,
		Status.WEAKNESS,
		Status.VULNERABILITY,
	]

func get_status_name(status: Status) -> String:
	match status:
		Status.POISON: return "Poison"
		Status.BLEED: return "Bleed"
		Status.BURN: return "Burn"
		Status.COLD: return "Cold"
		Status.WEAKNESS: return "Weakness"
		Status.VULNERABILITY: return "Vulnerability"
		Status.STRENGTH: return "Strength"
		Status.REGEN: return "Regeneration"
		Status.SHIELD: return "Shield"
		_: return "Unknown"

##
## FONT
##

const FONT_HEADERS : Font = preload("res://fonts/KellySlab-Regular.ttf")
const FONT_MAIN : Font = preload("res://fonts/RobotoCondensed-VariableFont_wght.ttf")
## ============================================================
## 7. ИКОНКИ
## ============================================================

const INTENT_ICONS: Dictionary = {
	IntentType.ATTACK: preload("res://img/icons/intents/attack.png"),
	IntentType.DEFEND: preload("res://img/icons/intents/defend.png"),
	IntentType.BUFF: preload("res://img/icons/intents/buff.png"),
	IntentType.DEBUFF: preload("res://img/icons/intents/debuff.png"),
	IntentType.UNKNOWN: preload("res://img/icons/intents/unknown.png"),
	IntentType.SUMMON: preload("res://img/icons/intents/summon.png"),
	IntentType.HEAL: preload("res://img/icons/intents/heal.png"),
}

const CARD_TYPE_ICONS: Dictionary = {
	CardType.ATTACK: preload("res://img/icons/card_types/attack.png"),
	CardType.DEFEND: preload("res://img/icons/card_types/defend.png"),
	CardType.BUFF_SELF: preload("res://img/icons/card_types/buff.png"),
	CardType.DEBUFF: preload("res://img/icons/card_types/debuff.png"),
	CardType.HEAL: preload("res://img/icons/card_types/heal.png"),
	CardType.RESOURCE: preload("res://img/icons/card_types/resource.png"),
	CardType.UTILITY: preload("res://img/icons/card_types/utility.png"),
}

const STATUS_ICONS: Dictionary = {
	Status.POISON: preload("res://img/icons/statuses/poison.png"),
	Status.BLEED: preload("res://img/icons/statuses/bleed.png"),
	Status.BURN: preload("res://img/icons/statuses/burn.png"),
	Status.COLD: preload("res://img/icons/statuses/cold.png"),
	Status.WEAKNESS: preload("res://img/icons/statuses/weakness.png"),
	Status.VULNERABILITY: preload("res://img/icons/statuses/vulnerability.png"),
	Status.STRENGTH: preload("res://img/icons/statuses/strength.png"),
	Status.REGEN: preload("res://img/icons/statuses/regen.png"),
	Status.SHIELD: preload("res://img/icons/statuses/shield.png"),
}

const PASSIVE_ICONS: Dictionary = {
	Passive.REGROWTH: preload("res://img/icons/passives/regrowth.png"),
	Passive.VENOMOUS_SHIELD: preload("res://img/icons/passives/venomous_shield.png"),
	Passive.WRATH: preload("res://img/icons/passives/wrath.png"),
	Passive.FREEZING_GROUND: preload("res://img/icons/passives/freezing_ground.png"),
	Passive.DENIAL: preload("res://img/icons/passives/denial.png"),
	Passive.SHAME: preload("res://img/icons/passives/shame.png"),
}


## ============================================================
## 8. МЕТОДЫ ДЛЯ ПОЛУЧЕНИЯ ИКОНОК
## ============================================================

func get_intent_icon(intent_type: IntentType) -> Texture2D:
	return INTENT_ICONS.get(intent_type, INTENT_ICONS.get(IntentType.UNKNOWN))

func get_card_type_icon(card_type: CardType) -> Texture2D:
	return CARD_TYPE_ICONS.get(card_type, null)

func get_status_icon(status: Status) -> Texture2D:
	return STATUS_ICONS.get(status, null)

func get_passive_icon(passive: Passive) -> Texture2D:
	return PASSIVE_ICONS.get(passive, null)


## ============================================================
## 9. ЗАГРУЗКА РЕСУРСОВ СТАТУСОВ
## ============================================================

var _status_resources: Dictionary = {}
var _status_resources_loaded: bool = false

func load_status_resources():
	if _status_resources_loaded:
		return
	
	_status_resources[Status.POISON] = load("res://resources/statuses/poison.tres")
	_status_resources[Status.BLEED] = load("res://resources/statuses/bleed.tres")
	_status_resources[Status.BURN] = load("res://resources/statuses/burn.tres")
	_status_resources[Status.COLD] = load("res://resources/statuses/cold.tres")
	_status_resources[Status.WEAKNESS] = load("res://resources/statuses/weakness.tres")
	_status_resources[Status.VULNERABILITY] = load("res://resources/statuses/vulnerability.tres")
	_status_resources[Status.STRENGTH] = load("res://resources/statuses/strength.tres")
	_status_resources[Status.REGEN] = load("res://resources/statuses/regen.tres")
	_status_resources[Status.SHIELD] = load("res://resources/statuses/shield.tres")
	
	_status_resources_loaded = true

func get_status_resource(status: Status) -> StatusResource:
	if not _status_resources_loaded:
		load_status_resources()
	return _status_resources.get(status, null)

func get_status_by_enum(status: Status) -> StatusResource:
	return get_status_resource(status)


## ============================================================
## 10. ЗАГРУЗКА РЕСУРСОВ ПАССИВОК
## ============================================================

var _passive_resources: Dictionary = {}
var _passive_resources_loaded: bool = false

func load_passive_resources():
	if _passive_resources_loaded:
		return
	
	_passive_resources[Passive.REGROWTH] = load("res://resources/passives/regrowth.tres")
	_passive_resources[Passive.VENOMOUS_SHIELD] = load("res://resources/passives/venomous_shield.tres")
	_passive_resources[Passive.WRATH] = load("res://resources/passives/wrath.tres")
	_passive_resources[Passive.FREEZING_GROUND] = load("res://resources/passives/freezing_ground.tres")
	_passive_resources[Passive.DENIAL] = load("res://resources/passives/denial.tres")
	_passive_resources[Passive.SHAME] = load("res://resources/passives/shame.tres")
	
	_passive_resources_loaded = true

## ============================================================
## БЭКГРАУНДЫ КОМНАТ
## ============================================================

var _biome_backgrounds: Dictionary = {}  # Biome -> Array[Texture2D]

func load_biome_backgrounds():
	# Кротовые норы
	_biome_backgrounds[DataManager.Biome.MOLE_TUNNELS] = [
		preload("res://img/backgrounds/mole_tunnels/mole_tunnels_1.png"),
		preload("res://img/backgrounds/mole_tunnels/mole_tunnels_2.png"),
		preload("res://img/backgrounds/mole_tunnels/mole_tunnels_3.png"),
		preload("res://img/backgrounds/mole_tunnels/mole_tunnels_4.png")
	]
	
	# Пещеры плоти (позже)
	# _biome_backgrounds[DataManager.Biome.FLESH_CAVES] = [...]
	
	# Костяной лабиринт (позже)
	# _biome_backgrounds[DataManager.Biome.BONE_LABYRINTH] = [...]

func get_biome_backgrounds(biome: DataManager.Biome) -> Array[Texture2D]:
	if _biome_backgrounds.is_empty():
		load_biome_backgrounds()
	return _biome_backgrounds.get(biome, [])

	
func get_random_background(biome: Biome) -> Texture2D:
	if _biome_backgrounds.is_empty():
		load_biome_backgrounds()
	
	var backgrounds = _biome_backgrounds.get(biome, [])
	if backgrounds.is_empty():
		return null
	
	return backgrounds[randi() % backgrounds.size()]

func get_passive_resource(passive: Passive) -> PassiveResource:
	if not _passive_resources_loaded:
		load_passive_resources()
	return _passive_resources.get(passive, null)

func get_passive_by_enum(passive: Passive) -> PassiveResource:
	return get_passive_resource(passive)


## ============================================================
## 11. ДАННЫЕ ВРАГОВ ДЛЯ БИОМОВ
## ============================================================

var _current_enemies_data: Resource = null

func load_biome_enemies(biome: Biome):
	match biome:
		Biome.MOLE_TUNNELS:
			_current_enemies_data = preload("res://data/biomes/mole_tunnels_enemies.gd").new()
		# Biome.FLESH_CAVES:
		#     _current_enemies_data = preload("res://data/biomes/flesh_caves_enemies.gd").new()
		# Biome.BONE_LABYRINTH:
		#     _current_enemies_data = preload("res://data/biomes/bone_labyrinth_enemies.gd").new()

func get_enemy_intents(enemy_id: int) -> Dictionary:
	if not _current_enemies_data:
		return {}
	
	# Получаем константу INTENTS из ресурса
	var intents_dict = _current_enemies_data.get("INTENTS")
	if intents_dict == null:
		return {}
	
	return intents_dict.get(enemy_id, {})


func get_enemy_intents_list(enemy_id: int) -> Array:
	var data = get_enemy_intents(enemy_id)
	return data.get("intents", [])


func get_enemy_cycle_type(enemy_id: int) -> int:
	var data = get_enemy_intents(enemy_id)
	return data.get("cycle_type", DataManager.IntentCycleType.SEQUENTIAL)
## ============================================================
## 12. ИНИЦИАЛИЗАЦИЯ
## ============================================================

func _ready():
	load_status_resources()
	load_passive_resources()


## ============================================================
## НАЗВАНИЯ КАРТ (для fallback, если нет локализации)
## ============================================================

func get_card_default_name(card_id: CardId) -> String:
	match card_id:
		# Сломленный
		CardId.ATONEMENT_STRIKE:
			return "Atonement Strike"
		CardId.SINFUL_STRIKE:
			return "Sinful Strike"
		CardId.PENITENT_REVELATION:
			return "Penitent Revelation"
		CardId.ATONEMENT_BARRIER:
			return "Atonement Barrier"
		CardId.BLOOD_SACRIFICE:
			return "Blood Sacrifice"
		CardId.PRICE_OF_DESPAIR:
			return "Price of Despair"
		CardId.SCOURING_FLAME:
			return "Scouring Flame"
		CardId.SIN_OF_VANITY:
			return "Sin of Vanity"
		CardId.THIRST_FOR_PUNISHMENT:
			return "Thirst for Punishment"
		CardId.SHIELD_OF_PENANCE:
			return "Shield of Penance"
		CardId.VOID_STRIKE:
			return "Void Strike"
		CardId.CRY_OF_DESPAIR:
			return "Cry of Despair"
		
		# Кротовые норы
		CardId.BLIND_FURY:
			return "Blind Fury"
		CardId.SMELL_OF_BLOOD:
			return "Smell of Blood"
		CardId.MOLERAT_HIDE:
			return "Molerat Hide"
		CardId.TUNNEL_AMBUSH:
			return "Tunnel Ambush"
		CardId.BLOODLETTING:
			return "Bloodletting"
		
		_:
			return "Unknown Card"

## ============================================================
## СПРАЙТЫ ВРАГОВ
## ============================================================

var _enemy_sprites: Dictionary = {}  # "biome_enemy" -> Texture2D

func load_enemy_sprites():
	# Кротовые норы (Mole Tunnels)
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.MOLE_MUTANT, "res://img/enemies/mole_tunnels/mole_mutant.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.STRONG_MOLE, "res://img/enemies/mole_tunnels/strong_mole.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.RABID_RAT, "res://img/enemies/mole_tunnels/rabid_rat.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.MOLE_FUNGUS, "res://img/enemies/mole_tunnels/mole_fungus.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.MANY_HEADED_MOLE, "res://img/enemies/mole_tunnels/many_headed_mole.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.FUNGAL_MINER, "res://img/enemies/mole_tunnels/fungal_miner.png")
	_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.MoleEnemy.RODENT_MOUND, "res://img/enemies/mole_tunnels/rodent_mound.png")

func _register_enemy_sprite(biome: DataManager.Biome, enemy_id, path: String):
	var key = str(biome) + "_" + str(enemy_id)
	if ResourceLoader.exists(path):
		_enemy_sprites[key] = load(path)
	else:
		printerr("Enemy sprite not found: ", path)

func get_enemy_sprite(enemy_id, biome: DataManager.Biome) -> Texture2D:
	if _enemy_sprites.is_empty():
		load_enemy_sprites()
	
	var key = str(biome) + "_" + str(enemy_id)
	var sprite = _enemy_sprites.get(key)
	
	# Если спрайт не найден, возвращаем заглушку
	if not sprite:
		printerr("Missing sprite for enemy: ", enemy_id, " in biome: ", biome)
		return _get_fallback_sprite()
	
	return sprite

func _get_fallback_sprite() -> Texture2D:
	# Заглушка на случай отсутствия спрайта
	return load("res://img/enemies/fallback.png")
## ============================================================
## РЕСУРСЫ ВРАГОВ
## ============================================================

var _enemy_resources: Dictionary = {}  # MoleEnemy -> EnemyResource
var _enemy_resources_loaded: bool = false

func load_enemy_resources():
	if _enemy_resources_loaded:
		return
	
	# Кротовые норы
	_enemy_resources[MoleEnemy.MOLE_MUTANT] = load("res://resources/enemies/mole_tunnels/mole_mutant.tres")
	_enemy_resources[MoleEnemy.STRONG_MOLE] = load("res://resources/enemies/mole_tunnels/strong_mole.tres")
	_enemy_resources[MoleEnemy.RABID_RAT] = load("res://resources/enemies/mole_tunnels/rabid_rat.tres")
	_enemy_resources[MoleEnemy.MOLE_FUNGUS] = load("res://resources/enemies/mole_tunnels/mole_fungus.tres")
	_enemy_resources[MoleEnemy.MANY_HEADED_MOLE] = load("res://resources/enemies/mole_tunnels/many_headed_mole.tres")
	_enemy_resources[MoleEnemy.FUNGAL_MINER] = load("res://resources/enemies/mole_tunnels/fungal_miner.tres")
	_enemy_resources[MoleEnemy.RODENT_MOUND] = load("res://resources/enemies/mole_tunnels/rodent_mound.tres")
	
	_enemy_resources_loaded = true


# DataManager.gd

func get_enemy_resource_name(enemy: MoleEnemy) -> String:
	match enemy:
		MoleEnemy.MOLE_MUTANT:
			return "Mole Mutant"
		MoleEnemy.STRONG_MOLE:
			return "Strong Mole"
		MoleEnemy.RABID_RAT:
			return "Rabid Rat"
		MoleEnemy.MOLE_FUNGUS:
			return "Mole Fungus"
		MoleEnemy.MANY_HEADED_MOLE:
			return "Many-Headed Mole"
		MoleEnemy.FUNGAL_MINER:
			return "Fungal Miner"
		MoleEnemy.RODENT_MOUND:
			return "Rodent Mound"
		_:
			return "Unknown"

func get_enemy_resource(enemy: MoleEnemy) -> EnemyResource:
	if not _enemy_resources_loaded:
		load_enemy_resources()
	
	var resource = _enemy_resources.get(enemy)
	if not resource:
		printerr("Enemy resource not found for: ", enemy)
	return resource

func get_enemy_size_pixels(size: DataManager.EnemySize) -> Vector2:
	match size:
		DataManager.EnemySize.WEAK:
			return Vector2(192, 192)
		DataManager.EnemySize.NORMAL:
			return Vector2(256, 256)
		DataManager.EnemySize.ELITE:
			return Vector2(320, 320)
		DataManager.EnemySize.BOSS:
			return Vector2(460, 460)
	return Vector2(256, 256)


## СТАРТОВАЯ КОЛОДА
## ============================================================

# DataManager.gd

## ============================================================
## КАРТЫ
## ============================================================

var _cards: Dictionary = {}  # CardId -> CardData
var _cards_loaded: bool = false

func load_all_cards():
	if _cards_loaded:
		return
	
	# Загружаем все карты по enum
	_register_card(CardId.ATONEMENT_STRIKE, "res://resources/cards/penitent/atonement_strike.tres")
	_register_card(CardId.SINFUL_STRIKE, "res://resources/cards/penitent/sinful_strike.tres")
	_register_card(CardId.PENITENT_REVELATION, "res://resources/cards/penitent/penitent_revelation.tres")
	_register_card(CardId.ATONEMENT_BARRIER, "res://resources/cards/penitent/atonement_barrier.tres")
	_register_card(CardId.BLOOD_SACRIFICE, "res://resources/cards/penitent/blood_sacrifice.tres")
	_register_card(CardId.PRICE_OF_DESPAIR, "res://resources/cards/penitent/price_of_despair.tres")
	_register_card(CardId.SCOURING_FLAME, "res://resources/cards/penitent/scouring_flame.tres")
	_register_card(CardId.SIN_OF_VANITY, "res://resources/cards/penitent/sin_of_vanity.tres")
	_register_card(CardId.THIRST_FOR_PUNISHMENT, "res://resources/cards/penitent/thirst_for_punishment.tres")
	_register_card(CardId.SHIELD_OF_PENANCE, "res://resources/cards/penitent/shield_of_penance.tres")
	_register_card(CardId.VOID_STRIKE, "res://resources/cards/penitent/void_strike.tres")
	_register_card(CardId.CRY_OF_DESPAIR, "res://resources/cards/penitent/cry_of_despair.tres")
	
	_cards_loaded = true

func _register_card(card_id: CardId, path: String):
	if ResourceLoader.exists(path):
		_cards[card_id] = load(path)
	else:
		printerr("Card not found: ", path)

func get_card(card_id: CardId) -> CardData:
	if not _cards_loaded:
		load_all_cards()
	return _cards.get(card_id)


func get_starting_deck() -> Array[CardData]:
	var deck: Array[CardData] = []
	
	deck.append(get_card(CardId.ATONEMENT_STRIKE))
	deck.append(get_card(CardId.ATONEMENT_STRIKE))
	deck.append(get_card(CardId.ATONEMENT_STRIKE))
	deck.append(get_card(CardId.SINFUL_STRIKE))
	deck.append(get_card(CardId.SINFUL_STRIKE))
	deck.append(get_card(CardId.SINFUL_STRIKE))
	deck.append(get_card(CardId.PENITENT_REVELATION))
	deck.append(get_card(CardId.ATONEMENT_BARRIER))
	deck.append(get_card(CardId.ATONEMENT_BARRIER))
	
	return deck
	
## ============================================================
## ФОНЫ КАРТ
## ============================================================

var _card_backgrounds: Dictionary = {}

func load_card_backgrounds():
	# Фоны биомов
	#_card_backgrounds["biome_" + str(Biome.MOLE_TUNNELS)] = preload("res://img/cards/backgrounds/mole_tunnels_card_bg.png")
	
	# Фоны классов персонажей
	_card_backgrounds["class_" + str(CharacterClass.PENITENT)] = preload("res://img/cards/backgrounds/penitent_card_bg.png")


func get_card_background_for_class(class_type: CharacterClass) -> Texture2D:
	if _card_backgrounds.is_empty():
		load_card_backgrounds()
	return _card_backgrounds.get("class_" + str(class_type), null)


func get_card_background_for_biome(biome: Biome) -> Texture2D:
	if _card_backgrounds.is_empty():
		load_card_backgrounds()
	return _card_backgrounds.get("biome_" + str(biome), null)


## ============================================================
## ИЛЛЮСТРАЦИИ КАРТ
## ============================================================

var _card_illustrations: Dictionary = {}  # CardId -> Texture2D

func load_card_illustrations():
	# Карты Сломленного (Penitent)
	_card_illustrations[CardId.ATONEMENT_STRIKE] = preload("res://img/cards/penitent/atonement_strike.png")
	_card_illustrations[CardId.SINFUL_STRIKE] = preload("res://img/cards/penitent/sinful_strike.png")
	_card_illustrations[CardId.PENITENT_REVELATION] = preload("res://img/cards/penitent/penitent_revelation.png")
	_card_illustrations[CardId.ATONEMENT_BARRIER] = preload("res://img/cards/penitent/atonement_barrier.png")
	_card_illustrations[CardId.BLOOD_SACRIFICE] = preload("res://img/cards/penitent/blood_sacrifice.png")
	_card_illustrations[CardId.PRICE_OF_DESPAIR] = preload("res://img/cards/penitent/price_of_despair.png")
	_card_illustrations[CardId.SCOURING_FLAME] = preload("res://img/cards/penitent/scouring_flame.png")
	_card_illustrations[CardId.SIN_OF_VANITY] = preload("res://img/cards/penitent/sin_of_vanity.png")
	_card_illustrations[CardId.THIRST_FOR_PUNISHMENT] = preload("res://img/cards/penitent/thirst_for_punishment.png")
	_card_illustrations[CardId.SHIELD_OF_PENANCE] = preload("res://img/cards/penitent/shield_of_penance.png")
	_card_illustrations[CardId.VOID_STRIKE] = preload("res://img/cards/penitent/void_strike.png")
	_card_illustrations[CardId.CRY_OF_DESPAIR] = preload("res://img/cards/penitent/cry_of_despair.png")
	
	## Карты биома Кротовые норы
	#_card_illustrations[CardId.BLIND_FURY] = preload("res://img/cards/mole_tunnels/blind_fury.png")
	#_card_illustrations[CardId.SMELL_OF_BLOOD] = preload("res://img/cards/mole_tunnels/smell_of_blood.png")
	#_card_illustrations[CardId.MOLERAT_HIDE] = preload("res://img/cards/mole_tunnels/molerat_hide.png")
	#_card_illustrations[CardId.TUNNEL_AMBUSH] = preload("res://img/cards/mole_tunnels/tunnel_ambush.png")
	#_card_illustrations[CardId.BLOODLETTING] = preload("res://img/cards/mole_tunnels/bloodletting.png")


func get_card_illustration(card_id: CardId) -> Texture2D:
	if _card_illustrations.is_empty():
		load_card_illustrations()
	return _card_illustrations.get(card_id, null)


## ============================================================
## ЦВЕТА КАРТ (КОНСТАНТЫ в HEX)
## ============================================================

# === ТЁМНЫЕ ЦВЕТА (оригинальные) ===
# Цвета для фона иллюстрации (ArtBackground) - карты персонажа
const COLOR_PENITENT_ART_BG_DARK: Color = Color("592626")    # тёмно-бордовый
const COLOR_WARRIOR_ART_BG_DARK: Color = Color("33334D")      # тёмно-синий
const COLOR_MYSTIC_ART_BG_DARK: Color = Color("331A40")       # тёмно-фиолетовый
const COLOR_ROGUE_ART_BG_DARK: Color = Color("263326")        # тёмно-зелёный

# Цвета для фона иллюстрации (ArtBackground) - карты биома
const COLOR_MOLE_TUNNELS_ART_BG_DARK: Color = Color("261A0D")    # тёмно-коричневый
const COLOR_FLESH_CAVES_ART_BG_DARK: Color = Color("400D0D")     # тёмно-красный
const COLOR_BONE_LABYRINTH_ART_BG_DARK: Color = Color("332E26")  # тёмно-серый

# === СВЕТЛЫЕ ЦВЕТА (альтернативные) ===
const COLOR_PENITENT_ART_BG_LIGHT2: Color = Color("C47A7A")     # светло-бордовый
const COLOR_PENITENT_ART_BG_LIGHT: Color = Color("faeceb")     # светло-бордовый
const COLOR_WARRIOR_ART_BG_LIGHT: Color = Color("8A8ABF")      # светло-синий
const COLOR_MYSTIC_ART_BG_LIGHT: Color = Color("8A5ABF")       # светло-фиолетовый
const COLOR_ROGUE_ART_BG_LIGHT: Color = Color("6ABF6A")        # светло-зелёный

const COLOR_MOLE_TUNNELS_ART_BG_LIGHT: Color = Color("BFA86A")     # светло-коричневый
const COLOR_FLESH_CAVES_ART_BG_LIGHT: Color = Color("BF6A6A")      # светло-красный
const COLOR_BONE_LABYRINTH_ART_BG_LIGHT: Color = Color("BFB8A6")   # светло-серый

const COLOR_DAMAGE_LOG: Color = Color(1, 0.3, 0.2)
const COLOR_HEAL_LOG: Color = Color(0.4, 0.8, 0.3)

## ============================================================
## ЦВЕТА ПОДЛОЖКИ КАРТ (CARDBACKGROUND)
## ============================================================

# Цвета подложки карт персонажа
const COLOR_PENITENT_CARD_BG: Color = Color("f2ccb3")   # бежевый
const COLOR_WARRIOR_CARD_BG: Color = Color("c4c4e6")    # светло-синий
const COLOR_MYSTIC_CARD_BG: Color = Color("ccb3e6")     # светло-фиолетовый
const COLOR_ROGUE_CARD_BG: Color = Color("b3e6b3")      # светло-зелёный

# Цвета подложки карт биома
const COLOR_MOLE_TUNNELS_CARD_BG: Color = Color("e6d6b3")    # бежево-коричневый
const COLOR_FLESH_CAVES_CARD_BG: Color = Color("e6c4c4")     # светло-красный
const COLOR_BONE_LABYRINTH_CARD_BG: Color = Color("e6e0d6")  # светло-серый
## ============================================================
## МЕТОДЫ ПОЛУЧЕНИЯ ЦВЕТОВ
## ============================================================

# Использовать тёмные цвета (по умолчанию)
func get_card_art_background_color(origin: CardOrigin, character_class: CharacterClass, biome: Biome, use_light: bool = false) -> Color:
	if use_light:
		return _get_card_art_background_color_light(origin, character_class, biome)
	else:
		return _get_card_art_background_color_dark(origin, character_class, biome)

func _get_card_art_background_color_dark(origin: CardOrigin, character_class: CharacterClass, biome: Biome) -> Color:
	match origin:
		CardOrigin.CHARACTER:
			match character_class:
				CharacterClass.PENITENT:
					return COLOR_PENITENT_ART_BG_DARK
				CharacterClass.WARRIOR:
					return COLOR_WARRIOR_ART_BG_DARK
				CharacterClass.MYSTIC:
					return COLOR_MYSTIC_ART_BG_DARK
				CharacterClass.ROGUE:
					return COLOR_ROGUE_ART_BG_DARK
				_:
					return Color.BLACK
		
		CardOrigin.BIOME:
			match biome:
				Biome.MOLE_TUNNELS:
					return COLOR_MOLE_TUNNELS_ART_BG_DARK
				Biome.FLESH_CAVES:
					return COLOR_FLESH_CAVES_ART_BG_DARK
				Biome.BONE_LABYRINTH:
					return COLOR_BONE_LABYRINTH_ART_BG_DARK
				_:
					return Color.BLACK
		
		_:
			return Color.BLACK

func _get_card_art_background_color_light(origin: CardOrigin, character_class: CharacterClass, biome: Biome) -> Color:
	match origin:
		CardOrigin.CHARACTER:
			match character_class:
				CharacterClass.PENITENT:
					return COLOR_PENITENT_ART_BG_LIGHT
				CharacterClass.WARRIOR:
					return COLOR_WARRIOR_ART_BG_LIGHT
				CharacterClass.MYSTIC:
					return COLOR_MYSTIC_ART_BG_LIGHT
				CharacterClass.ROGUE:
					return COLOR_ROGUE_ART_BG_LIGHT
				_:
					return Color.BLACK
		
		CardOrigin.BIOME:
			match biome:
				Biome.MOLE_TUNNELS:
					return COLOR_MOLE_TUNNELS_ART_BG_LIGHT
				Biome.FLESH_CAVES:
					return COLOR_FLESH_CAVES_ART_BG_LIGHT
				Biome.BONE_LABYRINTH:
					return COLOR_BONE_LABYRINTH_ART_BG_LIGHT
				_:
					return Color.BLACK
		
		_:
			return Color.BLACK

func t(key: String) -> String:
	return tr(key)


func get_room_icon(room_type: DataManager.RoomType, combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL) -> Texture2D:
	match room_type:
		DataManager.RoomType.COMBAT:
			match combat_type:
				DataManager.CombatType.NORMAL:
					return preload("res://img/icons/card_types/attack.png")
				DataManager.CombatType.ELITE:
					return preload("res://img/icons/statuses/strength.png")
				DataManager.CombatType.BOSS:
					return preload("res://img/icons/passives/shame.png")
				_:
					return preload("res://img/icons/card_types/attack.png")
		DataManager.RoomType.EVENT:
			return preload("res://img/icons/intents/summon.png")
		DataManager.RoomType.OBJECT:
			return preload("res://img/icons/card_types/utility.png")
	return preload("res://img/icons/intents/unknown.png")

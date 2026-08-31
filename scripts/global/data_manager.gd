# data_manager.gd
extends Node

func get_scale_factor() -> float:
	var base_size = Vector2(1920, 1080)  # или из Project Settings
	var viewport_size = DisplayServer.screen_get_size()
	var scale_factor
	scale_factor = viewport_size.y / base_size.y
	if base_size.y == viewport_size.y:
		scale_factor = 1
	return scale_factor
	
var SCALE_FACTOR = get_scale_factor()
## ============================================================
## 1. ОСНОВНЫЕ ПЕРЕЧИСЛЕНИЯ (ENUMS)
## ============================================================card


## ============================================================
## СОСТОЯНИЯ КАРТ
## ============================================================

enum EnemyAnimationState {
	IDLE,
	ATTACK,
	GET_HIT,
}

enum ButtonType {
	DEFAULT,
	PRIMARY,
	SECONDARY,
	DANGER,
	SUCCESS,
}


enum CardState {
	IDLE,
	HOVERED,
	SELECTED,
	AIMING,
	PLAYED,
	BURNED,
	REWARD,  # 🆕 состояние для карт в наградах
}

enum ActionType {
	USE_KEY,
	BREAK,
	PRAY,
	DRINK,
	SEARCH,
	REST,
	MEDITATE,
	SHARP_WEAPON,
	MAKE_OFFERING,      # 🆕
	GIVE_BLOOD,         # 🆕
	LOOT_SHRINE,        # 🆕
	TRANSFORM_CARD,   # 🆕
	BREW_POTION,      # 🆕
	DISARM_TRAP,
	SEARCH_TRAP,
	LOSE_FLESH,
	CRAFT,
	TRADE,
	ROB,
	EVENT_MINER_SEARCH,   # 🆕
	EVENT_MINER_HELP,     # 🆕
	EVENT_UNDERGROUND_POOL_GRAB,   # 🆕
	EVENT_UNDERGROUND_POOL_DISTRACT, # 🆕
	EVENT_FLOWER_WATER,   # 🆕
	EVENT_FLOWER_CUT,     # 🆕
	EVENT_DIAMOND_WEDDING_WIFE,      # 🆕
	EVENT_DIAMOND_WEDDING_HUSBAND,   # 🆕
	EVENT_DANGER_DIALOGUE,   # 🆕
	EVENT_DANGER_ATTACK,     # 🆕
	EVENT_KROTINI_MOON,   # 🆕
	EVENT_KROTINI_OPAL,   # 🆕
}

enum EnemyId {
	# Кротовые норы
	MOLE_MUTANT,
	STRONG_MOLE,
	RABID_RAT,
	MOLE_FUNGUS,
	MANY_HEADED_MOLE,
	FUNGAL_MINER,
	RODENT_MOUND,
	# 🆕 Гнилостные Топи (Rotten Marshes)
	TOXIC_IMP,          # Болотный вампир (человек + летучая мышь)
	THORNY_BLOOM,       # Шипастая поросль
	CRESTED_TOAD,       # Гребнистая лягушка
	ROTTING_SNAIL,      # Улитка распада
	ROTTEN_PORTER,      # Сгнивший рабочий
	FLESH_HOUND,        # Гончая-цветок
	MASTER_OF_ROT,      # Хозяин гнили (босс)
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

## Типы валют
enum CurrencyType {
	COIN,   # внутризабеговая валюта
	BONE,   # мета-валюта вне забега
}

enum ModifierChangeType {
	MULTIPLIER,   # умножение (1.25 = +25%)
	PERCENT,      # процентное изменение (0.25 = +25%)
	FLAT_BONUS,   # флэт-бонус (+5)
}

enum UpgradeType {
	NONE,                      # 🆕 Нет улучшения (дефолтное значение)
	COST_MINUS,
	BLOCK_PLUS_PROC_50,
	DAMAGE_PLUS_PROC_50,
	HEAL_PLUS_PROC_50,
	DRAW_PLUS_1,
	ENERGY_PLUS_1,
	CONDITIONAL_DAMAGE_PLUS_PROC_50,
	CONDITIONAL_BLOCK_PLUS_PROC_50,
	CONDITIONAL_HEAL_PLUS_PROC_50,
	DELETE_NEGATIVE_STATUS,
	ADD_DAMAGE_5,
	ADD_BLOCK_5,
	ADD_HEAL_5,
	X_2_NEGATIVE_STATUS,
	ADD_STRENGTH_3,  # 🆕
}

## Модификаторы статов (проценты / множители)
enum ModifierStat {
	DAMAGE_DEALT_PERCENT,      # +X% урона
	DAMAGE_TAKEN_PERCENT,      # +X% входящего урона
	BLOCK_GAINED_PERCENT,      # +X% получаемого блока
	HEALING_RECEIVED_PERCENT,  # +X% получаемого лечения
	ATONEMENT_GAIN_MULTIPLIER, # множитель получения Искупления
	DAMAGE_FLAT_BONUS,         # СИЛА (+X к урону)
	# 🆕 Новые модификаторы
	DAMAGE_DEALT_DIRECT_PERCENT,   # +X% к прямому урону (карты, атаки)
	DAMAGE_DEALT_DOT_PERCENT,      # +X% к урону от статусов (DOT)
	DAMAGE_TAKEN_DIRECT_PERCENT,   # +X% к входящему прямому урону
	DAMAGE_TAKEN_DOT_PERCENT,      # +X% к входящему урону от статусов (DOT)
}

enum PotionType {
	HEAL,
	ENERGY,
	DRAW,         # 🆕
	EXPLOSION,    # 🆕
	STATUS_CLEANSE,
	STRENGTH,
	POISON,
	BLOCK,
}

enum CardOrigin {
	CHARACTER,  # карта персонажа
	BIOME,      # карта биома
}

## ============================================================
## ШЕЙДЕРЫ ВРАГА
## ============================================================

enum EnemyShaderPriority {
	NONE,
	DEBUFF,   # 1 — низший
	HIT,      # 2 — средний
	FREEZE,   # 3 — высокий
	DEATH,    # 4 — наивысший
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
	ON_DEAL_DIRECT_DAMAGE,  # 🆕
	ON_TAKE_DIRECT_DAMAGE,    # 🆕 новый
	ON_STATUS_APPLIED_TO_SELF,  # 🆕
	ON_STATUS_DENIED,  # 🆕 срабатывает при попытке наложения статуса, который блокируется
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

# ============================================================
# АРТЕФАКТЫ
# ============================================================

## Грейд артефакта
enum ArtifactGrade {
	NORMAL,
	ELITE,
	COMBO,
}

## Тип срабатывания артефакта
enum ArtifactTrigger {
	ONE_TIME,              # срабатывает один раз и исчезает
	TURN_COUNT_START,      # срабатывает через N ходов в начале
	TURN_COUNT_END,        # срабатывает через N ходов в конце
	ON_START_FIGHT,        # срабатывает в начале боя
	HEALTH_DROPPED_BELOW , # срабатывает при выполнении условия
	CARD_PLAYED_COUNTER,   # срабатывает при розыгрыше N-й карты
	CUSTOM,                # кастомная логика
	ADD_ACTION_WHEN_APPLY_CONCRETE_STATUS_TO_ENEMY,  # 🆕
	DAMAGE_THRESHOLD,  # 🆕
	ATTACKS_THRESHOLD,  # 🆕
}

## ID артефактов
enum ArtifactId {
	STRANGE_MUSHROOM,      # ONE_TIME + ON_START_FIGHT
	HEROS_BROOCH,          # TURN_COUNT_START
	KINGS_ORDER,           # CARD_PLAYED_COUNTER
	HEALERS_AMULET,        # CONDITIONAL
	ABYSS_DUST,            # CUSTOM
	TROLL_BLADE,  # 🆕
	IMP_BLADE,  # 🆕 Клинок Импа
	PLAGUE_AMULET,  # 🆕
	ARACHNID_BELT,  # 🆕
	RUNIC_HELM,  # 🆕
	DRAGON_BROOCH,  # 🆕
	RUSTY_NAIL,  # 🆕
	THORN_CROWN,  # 🆕
	SERRATED_KNUCKLE,  # 🆕
	RING_OF_BARRICADE,  # 🆕
	LUCKY_PICK,  # 🆕
	INSATIABLE_BLADE,  # 🆕
}

## ============================================================
## ЗВУКИ
## ============================================================

enum SoundType {
	# UI
	CARD_HOVER,
	CARD_CLICK,
	CARD_PLAY,
	CARD_DISCARD,
	CARD_BURN,
	CARD_DRAW,
	BUTTON_CLICK,
	BUTTON_HOVER,
	
	# Бой
	ENEMY_GET_DAMAGE,
	ENEMY_ATTACK,
	PLAYER_GET_DAMAGE,
	PLAYER_ATTACK,
	BLOCK,
	HEAL,
	DEATH,
	APPLY_DEBUFF,
	# Статусы
	POISON_TICK,
	BLEED_TICK,
	BURN_TICK,
	
	# Победа/поражение
	VICTORY,
	DEFEAT,
	
	# Музыка
	MUSIC_MENU,
	MUSIC_GAMEPLAY,
	MUSIC_BOSS,
	
	GET_GOLD,
	GET_POTION,
	GET_SOMETHING
}

enum ScaledCompare {
	GREATER_EQUAL,   # значение >= порога
	LESSER_EQUAL,    # значение <= порога
	GREATER,         # значение > порога
	LESSER,          # значение < порога
	EQUAL,           # значение == порога
}

## Типы наград
enum RewardType {
	CARD_BIOM,
	CARD_CHARACTER,
	CARD_WITHOUT_CHOICE,
	ARTIFACT,
	ARTIFACT_WITHOUT_CHOICE,
	ARTIFACT_ELITE,          # 🆕 элитный артефакт         
	POTION,                  # 🆕 зелье
	TAKE_DAMAGE,
	GET_HEAL,
	ENERGY_BUFF,
	DECK_SIZE_BUFF,
	GOLD,
	REMOVE_CARD,
	UPGRADE_CARD,
	ADD_PROPERTY_TO_CARD,
	TRANSFORM_CARD,
	LOST_MAX_HP,  # 🆕
	TRADE,
	GET_BATTLE,
	CONCRETE_ARTIFACT,
	CONCRETE_CARD,
	GET_CONCRETE_BATTLE,  # 🆕 бой с конкретным типом врага
	ARTIFACT_COMBO,          # 🆕 элитный артефакт 
	GET_CONCRETE_STATUS,  # 🆕
	GET_MAX_HEALTH,  # 🆕
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

enum StatusDenyType {
	NONE,        # не блокирует ничего
	ALL,         # блокирует все статусы
	NEGATIVE,    # блокирует только негативные
	POSITIVE,    # блокирует только позитивные
	POISON,
	BLEED,
	BURN,
	COLD,
	WEAKNESS,
	VULNERABILITY,
	# ... можно добавлять любые статусы
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
	SHELL,
	BLOODDRINKER,
	THORNS,  # 🆕
	ROTTING_SHIELD,  # 🆕
	STEEL_HIDE
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
	FROZEN,
	GANGRENE,  # ← добавить
	BLISTER,  # Чёрный пузырь
	INFECTION,  # 🆕 Заражение
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

enum CostGrade {
	FREE,          # 0
	VERY_CHEAP,    # 1
	CHEAP,         # 2
	NORMAL,        # 3
	EXPENSIVE,     # 4
	VERY_EXPENSIVE,# 5
	ELITE,         # 6
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
	BLOOD_TRAIL,           # Кровавый след
	FROZEN_EARTH,          # Стылая земля
	RODENT_AGILITY,        # Проворство грызуна
	FROZEN_BITE,           # Мерзлый укус
	BEAST_PULSE,           # Пульс зверя
	BLOOD_THREAD,          # Кровавая нить
	ROTTEN_CUT,            # Гнилой порез
	MOLE_TOSS,             # Бросок слепыша
	WORM_SPIRIT,           # Дух червя
	FLESH_RAGE,            # Ярость плоти
	TORN_WOUND,            # Рваная рана
	# Rotten Marshes
	SNAKE_BITE,
	SWAMP_BLAST,  # 🆕
	BLESSING_OF_ROT,
	WEAK_SPOT,  # 🆕
	BLOOM_OF_CORRUPTION,  # 🆕
	MUD_SPLASH,
	BLOOD_INFECTION,
	EPIDEMIC,  # 🆕
	FOUL_WELL,  # 🆕
	STING_OF_CORRUPTION,  # 🆕
	
	# сломленный
	BLACK_ENVY,  # 🆕
	TIME_TO_DIE,  # 🆕
	BITTER_VENGEANCE,  # 🆕
	PURE_THOUGHTS,  # 🆕 Чистые помыслы
	BLIND_VENGEANCE,  # 🆕 Слепая месть
	GRIP_OF_DESPAIR,  # 🆕 Хватка отчаяния
	FORGIVENESS,  # 🆕 Прощение
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
	ROTTEN_MARSHES,     # 🆕 Гнилостные Топи
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
	ELITE_AFTER_ROB,  # бой после ограбления
	LIMITED_TURNS,    # бой с ограниченным количеством ходов
	BOSS,             # босс файт
	CONCRETE_COMBAT
}



## Тип эвента
enum EventType {
	MINER,
	UNDERGROUND_POOL,  # 🆕
	FLOWER,  # 🆕
	DIAMOND_WEDDING,  # 🆕
	DANGER_BEHIND,  # 🆕
	LEONARDO_KROTINI,     # 5 🆕
}

## Тип объекта
enum ObjectType {
	EVENT,           # 
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
const FLOOR_VISIBLE_ROOMS: int = 3            # видимых комнат в пути
const FLOOR_PATHS_COUNT: int = 2              # количество путей на развилке
const FLOOR_SEGMENTS_BEFORE_BOSS: int = 4     # сегментов (развилок) до босса
const FLOOR_OBJECT_SHUFFLE_CHANCE: float = 0.5  # 🆕 шанс переместить объект внутри сегмента
## ============================================================
## 2. БАЛАНСНЫЕ КОНСТАНТЫ
## ============================================================

## === Основные лимиты ===
const STARTING_HAND_SIZE: int = 5
const CARDS_TO_DRAW_PER_TURN: int = 6
const STARTING_ENERGY: int = 3
const MAX_ENERGY: int = 3
const HAND_SIZE_INCREMENT_PER_BIOME: int = 1  # 🆕
## === Сломленный (Penitent) ===
const PENITENT_STARTING_HEALTH: int = 120
const PENITENT_MAX_ATONEMENT: int = 30
const PENITENT_ATONEMENT_GAIN_PER_ATTACK: int = 5

## === Статусы ===

const POISON_BASE_DAMAGE_PER_STACK: int = 5
const POISON_TICK_INTERVAL: int = 1

const BLEED_BASE_DAMAGE_PER_STACK: int = 3
const BLEED_TICK_INTERVAL: int = 1

const BURN_BASE_DAMAGE_PER_STACK: int = 1
const BURN_TICK_INTERVAL: int = 1
const BURN_THRESHOLD_STACKS: int = 25
const BURN_EXPLOSION_DAMAGE_PER_STACK: int = 2
const BURN_STRENGTH_STACKS: int = 1
const BURN_STRENGTH_DURATION: int = 2

const COLD_EFFECT_PERCENT_PER_STACK: float = 0.01
const COLD_MIN_EFFECT_MULTIPLIER: float = 0.75
#BUG
const COLD_FREEZE_THRESHOLD: int = 15
const COLD_DEFAULT_DURATION: int = 3  # ← изменено с 3 на 5
const FROZEN_DURATION: int = 1  # заморозка на 1 ход
#BUG
const WEAKNESS_DAMAGE_MULTIPLIER: float = 0.75
const VULNERABILITY_DAMAGE_MULTIPLIER: float = 1.5

const POISON_HEALING_REDUCTION: float = 0.25

const DESPAIR_DURATION: int = 2
const DESPAIR_DAMAGE_DEALT_MULTIPLIER: float = 0.75

const INFECTION_BLEED_MULTIPLIER: int = 3
const INFECTION_MULTIPLIER: float = 1.5  # 🆕 множитель для общего урона
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



const ENEMY_STEP_DELAY : float = 1
const STATUS_TRIGGER_DELAY : float = 1
const PLAYER_STATUS_TRIGGER_DELAY : float = 1.2

const CHEST_BREAK_CHANCE: float = 0.5  # 50% шанс взлома
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
const CARD_HOVER_RAISE: int = 130  # высота подъёма при наведении
const CARD_HOVER_CENTER_FORCE: float = 0 # сила притяжения к центру (0-1)
#const CARD_HOVER_CENTER_FORCE: float = 0.02 # сила притяжения к центру (0-1)
const CARD_HAND_WIDTH: int = int(CARD_BASE_WIDTH * CARD_SCALE_IN_HAND)
const CARD_HAND_HEIGHT: int = int(CARD_BASE_HEIGHT * CARD_SCALE_IN_HAND)
## Дополнительное смещение влево при наведении (в пикселях)
const CARD_HOVER_EXTRA_OFFSET: int = -20
## ============================================================
## НАСТРОЙКИ РУКИ (HAND)
## ============================================================

## Базовый отступ между картами в руке (отрицательное значение = наложение)
const CARD_SPACING_IN_HAND: int = -60

## Базовая точка отсчёта для динамического сжатия (количество карт, с которого начинается сжатие)
const CARD_SPACING_BASE_COUNT: int = 5

## Множитель динамического сжатия (чем больше, тем сильнее сжимаются карты при увеличении их количества)
const CARD_SPACING_COMPRESSION_FACTOR: float = 0.13

## Минимальный отступ между картами (в процентах от ширины карты, 0.7 = 70%)
const CARD_MIN_SPACING_RATIO: float = 0.7

## ============================================================
## КАРТА: ВРЕМЯ УМИРАТЬ
## ============================================================

const TIME_TO_DIE_DAMAGE: int = 15
const TIME_TO_DIE_HEAL_PER_KILL: int = 8
## Настройки артефактов (временные значения для тестов)
const ARTIFACT_STRANGE_MUSHROOM_HP_BONUS: int = 10
const ARTIFACT_STRANGE_MUSHROOM_POISON_DURATION: int = 2

const ARTIFACT_HEROS_BROOCH_STRENGTH_STACKS: int = 3
const ARTIFACT_HEROS_BROOCH_TURN_INTERVAL: int = 3

const ARTIFACT_KINGS_ORDER_CARD_COUNT: int = 5
const ARTIFACT_KINGS_ORDER_DAMAGE_MULTIPLIER: float = 2.0

const ARTIFACT_HEALERS_AMULET_STATUS_THRESHOLD: int = 4
const ARTIFACT_HEALERS_AMULET_HEAL_AMOUNT: int = 10

const ARTIFACT_ABYSS_DUST_CARD_COST: int = 0

const POTION_MAX_COUNT: int = 5
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
## ВЗАИМОДЕЙСТВИЯ СТАТУСОВ
## ============================================================

## Bleed + Poison → Мука (Bleed стаки += Poison длительность / 3)
const BLEED_POISON_FLOUR_DIVIDER: int = 3

## Poison + Bleed → Агония (Poison длительность += Bleed стаки × 3)
const POISON_BLEED_AGONY_MULTIPLIER: int = 3

## Poison + Burn → Химический взрыв (урон = стаки Poison × длительность Poison)
const POISON_EXPLOSION_MULTIPLIER: int = 1

## Bleed + Cold → Гангрена (стаки = Bleed × Cold × 2, длительность = (Bleed + Cold) / 3)
const GANGRENE_MULTIPLIER: int = 2
const GANGRENE_DURATION_DIVIDER: int = 3


const FROZEN_ENERGY_LOSS: int = 2
## Burn ↔ Cold (контр-статусы, 1:1 вычитание)
# Константа не нужна, так как вычитание 1:1

## ============================================================
## 5. КОЛОДА
## ============================================================

const MAX_HAND_SIZE: int = 5


const COINS_SCREEN_POSITION: Vector2 = Vector2(1520, 450)
const KEYS_SCREEN_POSITION: Vector2 = Vector2(1620, 450)
const BONES_SCREEN_POSITION: Vector2 = Vector2(1720, 450)
const POTION_CONTAINER_POSITION: Vector2 = Vector2(1520, 550)

const MIN_BONES_FOR_IDOL: int = 5
const IDOL_DAMAGE: int = 3
const IDOL_BREAK_CHANCE: float = 0.5

const RACK_MAX_HP_LOST: int = 6
const RACK_MAX_HP_LOST_PERCENT: float = 0.4  # 🆕 40% от максимального здоровья
const RACK_ENERGY_BUFF_AMOUNT: int = 1       # 🆕 сколько энергии даёт пыточный стол
const RACK_ENERGY_BUFF_DURATION: int = -1    # 🆕 -1 = перманентно

const STARTING_KEYS: int = 1

const EVENT_TEXTURE_SIZE: Vector2 = Vector2(460, 460)
const EVENT_LABEL_SIZE: Vector2 = Vector2(700, 0)
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

const CONSECUTIVE_BATTLES_COUNT: int = 2
const SHOPS_ON_FLOOR_COUNT: int = 1
const EVENTS_ON_FLOOR_COUNT: int = 2
const CHESTS_ON_FLOOR_COUNT: int = 2
const TRAPS_ON_FLOOR_COUNT: int = 2
const BONFIRES_ON_FLOOR_COUNT: int = 2
const IDOLS_ON_FLOOR_COUNT: int = 1
const TORTURE_RACK_ON_FLOOR_COUNT: int = 1
const CAULDRONS_ON_FLOOR_COUNT: int = 1

# Этаж появления миньонов у босса
const BOSS_ADD_MINIONS_FROM_FLOOR: int = 3

# Этаж появления элитных врагов Fungal Miner
const ELITE_MINER_APPEARS_FROM_FLOOR: int = 3

const REWARD_GOLD_DEFAULT : int = 10
const REWARD_BONES_DEFAULT : int = 1
const REWARD_CHOICE_AMOUNT : int = 3
const REWARD_DAMAGE_DEFAULT: int = 5
const ENERGY_BUFF_REWARD_AMOUNT: int = 1
## Стартовое количество валют
const STARTING_COINS: int = 0
const STARTING_BONES: int = 0

const TRAP_NEUTRALIZE_CHANCE: float = 0.8  # 80% шанс
const TRAP_SEARCH_CHANCE: float = 0.5      # 50% шанс
const TRAP_NEUTRALIZE_DAMAGE: int = 1
const TRAP_SEARCH_DAMAGE: int = 2

const REST_DEFAULT_HEAL: int = 30
const BONFIRE_ENERGY_BUFF_DURATION: int = 3  # количество боевых комнат

const EVENT_SUCCESS_CHANCE : float = 0.6

const DEFAULT_ITEM_COST: int = 17
## ============================================================
## РАЗМЕРЫ КОМНАТЫ
## ============================================================

const ROOM_WIDTH: int = 1024
const ROOM_HEIGHT: int = 800
const ROOM_CENTER_X: int = ROOM_WIDTH / 2  # 512
const ROOM_CENTER_Y: int = ROOM_HEIGHT / 2  # 400
const ROOM_POSITION: Vector2 = Vector2(448, 0)
const END_BUTTON_POSITION: Vector2 = Vector2(1600, 680)
## ============================================================
## РАЗМЕРЫ ВРАГОВ
## ============================================================

const ENEMY_SPACING: int = 40
const ENEMY_Y_OFFSET_FROM_BOTTOM: int = 200  # отступ от нижней границы


const sound_delay: int = 50  # задержка между одинаковыми звуками в мс
const max_sounds: int = 8    # максимальное количество одновременных звуков


const BASE_MAX_HEALTH_AMOUNT: int = 10
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
		Status.FROZEN,
		Status.GANGRENE,
		Status.BLISTER,     # 🆕
		Status.INFECTION,   # 🆕
	]

func get_status_name(status: Status) -> String:
	match status:
		Status.POISON: return tr("status_poison_name")
		Status.BLEED: return tr("status_bleed_name")
		Status.BURN: return tr("status_burn_name")
		Status.COLD: return tr("status_cold_name")
		Status.WEAKNESS: return tr("status_weakness_name")
		Status.VULNERABILITY: return tr("status_vulnerability_name")
		Status.STRENGTH: return tr("status_strength_name")
		Status.REGEN: return tr("status_regen_name")
		Status.SHIELD: return tr("status_shield_name")
		Status.FROZEN: return tr("status_frozen_name")
		Status.GANGRENE: return tr("status_gangrene_name")
		Status.BLISTER: return tr("status_blister_name")      # 🆕
		Status.INFECTION: return tr("status_infection_name")  # 🆕
		_: return tr("status_unknown")

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
	IntentType.DEFEND: preload("res://img/icons/statuses/shield.png"),
	IntentType.BUFF: preload("res://img/icons/intents/buff.png"),
	IntentType.DEBUFF: preload("res://img/icons/intents/debuff.png"),
	IntentType.UNKNOWN: preload("res://img/icons/intents/unknown.png"),
	IntentType.SUMMON: preload("res://img/icons/intents/summon.png"),
	IntentType.HEAL: preload("res://img/icons/intents/heal.png"),
}

const CARD_TYPE_ICONS: Dictionary = {
	CardType.ATTACK: preload("res://img/icons/card_types/attack.png"),
	CardType.DEFEND: preload("res://img/icons/statuses/shield.png"),
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
	Status.COLD: preload("res://img/icons/statuses/frozen.png"),
	Status.WEAKNESS: preload("res://img/icons/statuses/weakness.png"),
	Status.VULNERABILITY: preload("res://img/icons/statuses/vulnerability.png"),
	Status.STRENGTH: preload("res://img/icons/statuses/strength.png"),
	Status.REGEN: preload("res://img/icons/statuses/regen.png"),
	Status.SHIELD: preload("res://img/icons/statuses/shield.png"),
	Status.FROZEN: preload("res://img/icons/statuses/cold.png"),
	Status.GANGRENE: preload("res://img/icons/statuses/gangrene.png"),
	Status.BLISTER: preload("res://img/icons/statuses/blister.png"),
	Status.INFECTION: preload("res://img/icons/statuses/infection.png"),
}

const PASSIVE_ICONS: Dictionary = {
	Passive.REGROWTH: preload("res://img/icons/passives/regrowth.png"),
	Passive.VENOMOUS_SHIELD: preload("res://img/icons/passives/venomous_shield.png"),
	Passive.WRATH: preload("res://img/icons/passives/wrath.png"),
	Passive.FREEZING_GROUND: preload("res://img/icons/passives/freezing_ground.png"),
	Passive.DENIAL: preload("res://img/icons/passives/denial.png"),
	Passive.SHAME: preload("res://img/icons/passives/shame.png"),
	Passive.SHELL: preload("res://img/icons/passives/shell.png"),  # 🆕
	Passive.BLOODDRINKER: preload("res://img/icons/passives/blooddrinker.png"),  # 🆕
	Passive.THORNS: preload("res://img/icons/passives/thorns.png"),
	Passive.ROTTING_SHIELD: preload("res://img/icons/passives/rotting_shield.png"),
	Passive.STEEL_HIDE: preload("res://img/icons/passives/steel_hide.png"),
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
	_status_resources[Status.FROZEN] = load("res://resources/statuses/frozen.tres")
	_status_resources[Status.GANGRENE] = load("res://resources/statuses/gangrene.tres")
	_status_resources[Status.BLISTER] = load("res://resources/statuses/blister.tres")
	_status_resources[Status.INFECTION] = load("res://resources/statuses/infection.tres")  # 🆕
	
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
	_passive_resources[Passive.SHELL] = load("res://resources/passives/shell.tres")
	_passive_resources[Passive.BLOODDRINKER] = load("res://resources/passives/blooddrinker.tres")
	_passive_resources[Passive.THORNS] = load("res://resources/passives/thorns.tres")
	_passive_resources[Passive.ROTTING_SHIELD] = load("res://resources/passives/rotting_shield.tres")
	_passive_resources[Passive.STEEL_HIDE] = load("res://resources/passives/steel_hide.tres")
	
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
	# 🆕 Гнилостные Топи
	_biome_backgrounds[DataManager.Biome.ROTTEN_MARSHES] = [
		preload("res://img/backgrounds/rotten_marshes/rotten_marshes_1.png"),
		preload("res://img/backgrounds/rotten_marshes/rotten_marshes_2.png"),
		preload("res://img/backgrounds/rotten_marshes/rotten_marshes_3.png"),
		preload("res://img/backgrounds/rotten_marshes/rotten_marshes_4.png"),
		preload("res://img/backgrounds/rotten_marshes/rotten_marshes_5.png")
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


## Текстуры объектов по биомам и типам
const OBJECT_TEXTURES: Dictionary = {
	# Кротовые норы
	DataManager.Biome.MOLE_TUNNELS: {
		DataManager.ObjectType.CHEST: preload("res://img/objects/mole_tunnels/chest.png"),
		DataManager.ObjectType.IDOL: preload("res://img/objects/mole_tunnels/idol.png"),
		DataManager.ObjectType.TRAP: preload("res://img/objects/mole_tunnels/trap.png"),
		DataManager.ObjectType.CAULDRON: preload("res://img/objects/mole_tunnels/cauldron.png"),
		DataManager.ObjectType.TORTURE_RACK: preload("res://img/objects/mole_tunnels/torture_rack.png"),
		DataManager.ObjectType.BONFIRE: preload("res://img/objects/mole_tunnels/bonfire.png"),
		DataManager.ObjectType.SHOP: preload("res://img/objects/mole_tunnels/shop2.png"),
	},
	# 🆕 Гнилостные Топи
	DataManager.Biome.ROTTEN_MARSHES: {
		DataManager.ObjectType.CHEST: preload("res://img/objects/mole_tunnels/chest.png"),
		DataManager.ObjectType.IDOL: preload("res://img/objects/rotten_marshes/idol.png"),
		DataManager.ObjectType.TRAP: preload("res://img/objects/mole_tunnels/trap.png"),
		DataManager.ObjectType.CAULDRON: preload("res://img/objects/mole_tunnels/cauldron.png"),
		DataManager.ObjectType.TORTURE_RACK: preload("res://img/objects/mole_tunnels/torture_rack.png"),
		DataManager.ObjectType.BONFIRE: preload("res://img/objects/mole_tunnels/bonfire.png"),
		DataManager.ObjectType.SHOP: preload("res://img/objects/rotten_marshes/shop.png"),
	}
}

func get_object_texture(object_type: DataManager.ObjectType, biome: DataManager.Biome) -> Texture2D:
	var biome_dict = OBJECT_TEXTURES.get(biome, {})
	return biome_dict.get(object_type, null)


## ============================================================
## 11. ДАННЫЕ ВРАГОВ ДЛЯ БИОМОВ
## ============================================================

var _current_enemies_data: Resource = null

func load_biome_enemies(biome: Biome):
	match biome:
		Biome.MOLE_TUNNELS:
			_current_enemies_data = preload("res://data/biomes/mole_tunnels_enemies.gd").new()
		Biome.ROTTEN_MARSHES:  # 🆕
			_current_enemies_data = preload("res://data/biomes/rotten_marshes_enemies.gd").new()

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

## ============================================================
## СПРАЙТЫ ВРАГОВ (с поддержкой анимации)
## ============================================================

var _enemy_sprites: Dictionary = {}  # "biome_enemy_state" -> Texture2D

func load_enemy_sprites_for_biome(biome: DataManager.Biome, enemy_data: Array, base_path: String):
	# Соответствие состояний суффиксам файлов
	var state_suffix = {
		EnemyAnimationState.IDLE: "11",
		EnemyAnimationState.ATTACK: "22",
		EnemyAnimationState.GET_HIT: "33",
	}
	
	for enemy in enemy_data:
		var enemy_folder = base_path + enemy.folder + "/"
		for state in EnemyAnimationState.values():
			var suffix = state_suffix[state]
			var path = enemy_folder + enemy.file + "_" + suffix + ".png"
			_register_enemy_sprite(biome, enemy.id, state, path)

func load_enemy_sprites():
	# Кротовые норы
	load_enemy_sprites_for_biome(
		DataManager.Biome.MOLE_TUNNELS,
		[
			{id = DataManager.EnemyId.MOLE_MUTANT, folder = "mole_mutant", file = "mole_mutant"},
			{id = DataManager.EnemyId.STRONG_MOLE, folder = "strong_mole", file = "strong_mole"},
			{id = DataManager.EnemyId.RABID_RAT, folder = "rabid_rat", file = "rabid_rat"},
			{id = DataManager.EnemyId.MOLE_FUNGUS, folder = "mole_fungus", file = "mole_fungus"},
			{id = DataManager.EnemyId.MANY_HEADED_MOLE, folder = "many_headed_mole", file = "many_headed_mole"},
			{id = DataManager.EnemyId.FUNGAL_MINER, folder = "fungal_miner", file = "fungal_miner"},
			{id = DataManager.EnemyId.RODENT_MOUND, folder = "rodent_mound", file = "rodent_mound"},
		],
		"res://img/enemies/mole_tunnels/"
	)
	
	# 🆕 Гнилостные Топи
	load_enemy_sprites_for_biome(
		DataManager.Biome.ROTTEN_MARSHES,
		[
			{id = DataManager.EnemyId.TOXIC_IMP, folder = "toxic_imp", file = "toxic_imp"},
			{id = DataManager.EnemyId.THORNY_BLOOM, folder = "thorny_bloom", file = "thorny_bloom"},
			{id = DataManager.EnemyId.CRESTED_TOAD, folder = "crested_toad", file = "crested_toad"},
			{id = DataManager.EnemyId.ROTTING_SNAIL, folder = "rotting_snail", file = "rotting_snail"},
			{id = DataManager.EnemyId.ROTTEN_PORTER, folder = "rotten_porter", file = "rotten_porter"},
			{id = DataManager.EnemyId.FLESH_HOUND, folder = "flesh_hound", file = "flesh_hound"},
			{id = DataManager.EnemyId.MASTER_OF_ROT, folder = "master_of_rot", file = "master_of_rot"},
		],
		"res://img/enemies/rotten_marshes/"
	)

func _register_enemy_sprite(biome: DataManager.Biome, enemy_id, state: EnemyAnimationState, path: String):
	var key = str(biome) + "_" + str(enemy_id) + "_" + str(state)
	if ResourceLoader.exists(path):
		_enemy_sprites[key] = load(path)
	else:
		printerr("Enemy sprite not found: ", path, " for state: ", state)

## Получить спрайт врага для конкретного состояния
func get_enemy_sprite(enemy_id, biome: DataManager.Biome, state: EnemyAnimationState = EnemyAnimationState.IDLE) -> Texture2D:
	if _enemy_sprites.is_empty():
		load_enemy_sprites()
	
	var key = str(biome) + "_" + str(enemy_id) + "_" + str(state)
	var sprite = _enemy_sprites.get(key)
	
	# Если спрайт не найден, пробуем использовать IDLE для этого врага
	if not sprite and state != EnemyAnimationState.IDLE:
		# Пробуем найти IDLE спрайт
		var idle_key = str(biome) + "_" + str(enemy_id) + "_" + str(EnemyAnimationState.IDLE)
		sprite = _enemy_sprites.get(idle_key)
	
	# Если всё ещё не найден, возвращаем заглушку
	if not sprite:
		printerr("Missing sprite for enemy: ", enemy_id, " in biome: ", biome, " state: ", state)
		return _get_fallback_sprite()
	
	return sprite

func _get_fallback_sprite() -> Texture2D:
	# Заглушка на случай отсутствия спрайта
	return load("res://img/enemies/fallback.png")

## Получить все спрайты врага для анимации (возвращает словарь)
func get_enemy_animation_frames(enemy_id, biome: DataManager.Biome) -> Dictionary:
	var frames = {}
	for state in EnemyAnimationState.values():
		var sprite = get_enemy_sprite(enemy_id, biome, state)
		if sprite:
			frames[state] = sprite
	return frames



#
#var _enemy_sprites: Dictionary = {}  # "biome_enemy" -> Texture2D
#
#func load_enemy_sprites():
	## Кротовые норы (Mole Tunnels)
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.MOLE_MUTANT, "res://img/enemies/mole_tunnels/mole_mutant.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.STRONG_MOLE, "res://img/enemies/mole_tunnels/strong_mole.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.RABID_RAT, "res://img/enemies/mole_tunnels/rabid_rat.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.MOLE_FUNGUS, "res://img/enemies/mole_tunnels/mole_fungus.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.MANY_HEADED_MOLE, "res://img/enemies/mole_tunnels/many_headed_mole.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.FUNGAL_MINER, "res://img/enemies/mole_tunnels/fungal_miner.png")
	#_register_enemy_sprite(DataManager.Biome.MOLE_TUNNELS, DataManager.EnemyId.RODENT_MOUND, "res://img/enemies/mole_tunnels/rodent_mound.png")
#
#func _register_enemy_sprite(biome: DataManager.Biome, enemy_id, path: String):
	#var key = str(biome) + "_" + str(enemy_id)
	#if ResourceLoader.exists(path):
		#_enemy_sprites[key] = load(path)
	#else:
		#printerr("Enemy sprite not found: ", path)
#
#func get_enemy_sprite(enemy_id, biome: DataManager.Biome) -> Texture2D:
	#if _enemy_sprites.is_empty():
		#load_enemy_sprites()
	#
	#var key = str(biome) + "_" + str(enemy_id)
	#var sprite = _enemy_sprites.get(key)
	#
	## Если спрайт не найден, возвращаем заглушку
	#if not sprite:
		#printerr("Missing sprite for enemy: ", enemy_id, " in biome: ", biome)
		#return _get_fallback_sprite()
	#
	#return sprite
#
#func _get_fallback_sprite() -> Texture2D:
	## Заглушка на случай отсутствия спрайта
	#return load("res://img/enemies/fallback.png")
## ============================================================
## РЕСУРСЫ ВРАГОВ
## ============================================================

var _enemy_resources: Dictionary = {}  # MoleEnemy -> EnemyResource
var _enemy_resources_loaded: bool = false

func load_enemy_resources():
	if _enemy_resources_loaded:
		return
	
	# Кротовые норы
	_enemy_resources[EnemyId.MOLE_MUTANT] = load("res://resources/enemies/mole_tunnels/mole_mutant.tres")
	_enemy_resources[EnemyId.STRONG_MOLE] = load("res://resources/enemies/mole_tunnels/strong_mole.tres")
	_enemy_resources[EnemyId.RABID_RAT] = load("res://resources/enemies/mole_tunnels/rabid_rat.tres")
	_enemy_resources[EnemyId.MOLE_FUNGUS] = load("res://resources/enemies/mole_tunnels/mole_fungus.tres")
	_enemy_resources[EnemyId.MANY_HEADED_MOLE] = load("res://resources/enemies/mole_tunnels/many_headed_mole.tres")
	_enemy_resources[EnemyId.FUNGAL_MINER] = load("res://resources/enemies/mole_tunnels/fungal_miner.tres")
	_enemy_resources[EnemyId.RODENT_MOUND] = load("res://resources/enemies/mole_tunnels/rodent_mound.tres")
	# 🆕 Гнилостные Топи
	_enemy_resources[EnemyId.TOXIC_IMP] = load("res://resources/enemies/rotten_marshes/toxic_imp.tres")
	_enemy_resources[EnemyId.THORNY_BLOOM] = load("res://resources/enemies/rotten_marshes/thorny_bloom.tres")
	_enemy_resources[EnemyId.CRESTED_TOAD] = load("res://resources/enemies/rotten_marshes/crested_toad.tres")
	_enemy_resources[EnemyId.ROTTING_SNAIL] = load("res://resources/enemies/rotten_marshes/rotting_snail.tres")
	_enemy_resources[EnemyId.ROTTEN_PORTER] = load("res://resources/enemies/rotten_marshes/rotten_porter.tres")
	_enemy_resources[EnemyId.FLESH_HOUND] = load("res://resources/enemies/rotten_marshes/flesh_hound.tres")
	_enemy_resources[EnemyId.MASTER_OF_ROT] = load("res://resources/enemies/rotten_marshes/master_of_rot.tres")
	
	_enemy_resources_loaded = true


# DataManager.gd

func get_enemy_resource_name(enemy: EnemyId) -> String:
	match enemy:
		EnemyId.MOLE_MUTANT:
			return "Mole Mutant"
		EnemyId.STRONG_MOLE:
			return "Strong Mole"
		EnemyId.RABID_RAT:
			return "Rabid Rat"
		EnemyId.MOLE_FUNGUS:
			return "Mole Fungus"
		EnemyId.MANY_HEADED_MOLE:
			return "Many-Headed Mole"
		EnemyId.FUNGAL_MINER:
			return "Fungal Miner"
		EnemyId.RODENT_MOUND:
			return "Rodent Mound"
		_:
			return "Unknown"

func get_enemy_resource(enemy: EnemyId) -> EnemyResource:
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
	_register_card(CardId.BLOOD_TRAIL, "res://resources/cards/mole_tunnels/blood_trail.tres")
	_register_card(CardId.FROZEN_EARTH, "res://resources/cards/mole_tunnels/frozen_earth.tres")
	_register_card(CardId.RODENT_AGILITY, "res://resources/cards/mole_tunnels/rodent_agility.tres")
	_register_card(CardId.FROZEN_BITE, "res://resources/cards/mole_tunnels/frozen_bite.tres")
	_register_card(CardId.ROTTEN_CUT, "res://resources/cards/mole_tunnels/rotten_cut.tres")
	_register_card(CardId.BEAST_PULSE, "res://resources/cards/mole_tunnels/beast_pulse.tres")
	_register_card(CardId.BLOOD_THREAD, "res://resources/cards/mole_tunnels/blood_thread.tres")
	_register_card(CardId.MOLE_TOSS, "res://resources/cards/mole_tunnels/mole_toss.tres")
	_register_card(CardId.WORM_SPIRIT, "res://resources/cards/mole_tunnels/worm_spirit.tres")
	_register_card(CardId.FLESH_RAGE, "res://resources/cards/mole_tunnels/flesh_rage.tres")
	_register_card(CardId.TORN_WOUND, "res://resources/cards/mole_tunnels/torn_wound.tres")
	_register_card(CardId.SNAKE_BITE, "res://resources/cards/rotten_marshes/snake_bite.tres")
	_register_card(CardId.SWAMP_BLAST, "res://resources/cards/rotten_marshes/swamp_blast.tres")
	_register_card(CardId.BLESSING_OF_ROT, "res://resources/cards/rotten_marshes/blessing_of_rot.tres")
	_register_card(CardId.WEAK_SPOT, "res://resources/cards/rotten_marshes/weak_spot.tres")
	_register_card(CardId.BLOOM_OF_CORRUPTION, "res://resources/cards/rotten_marshes/bloom_of_corruption.tres")
	_register_card(CardId.MUD_SPLASH, "res://resources/cards/rotten_marshes/mud_splash.tres")
	_register_card(CardId.BLOOD_INFECTION, "res://resources/cards/rotten_marshes/blood_infection.tres")
	_register_card(CardId.EPIDEMIC, "res://resources/cards/rotten_marshes/epidemic.tres")
	_register_card(CardId.FOUL_WELL, "res://resources/cards/rotten_marshes/foul_well.tres")
	_register_card(CardId.STING_OF_CORRUPTION, "res://resources/cards/rotten_marshes/sting_of_corruption.tres")
	# penitent
	_register_card(CardId.BLACK_ENVY, "res://resources/cards/penitent/black_envy.tres")
	_register_card(CardId.TIME_TO_DIE, "res://resources/cards/penitent/time_to_die.tres")
	_register_card(CardId.BITTER_VENGEANCE, "res://resources/cards/penitent/bitter_vengeance.tres")
	_register_card(CardId.PURE_THOUGHTS, "res://resources/cards/penitent/pure_thoughts.tres")
	_register_card(CardId.BLIND_VENGEANCE, "res://resources/cards/penitent/blind_vengeance.tres")
	_register_card(CardId.GRIP_OF_DESPAIR, "res://resources/cards/penitent/grip_of_despair.tres")
	_register_card(CardId.FORGIVENESS, "res://resources/cards/penitent/forgiveness.tres")
	
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

	
## ============================================================
## ФОНЫ КАРТ
## ============================================================

var _card_backgrounds: Dictionary = {}

func load_card_backgrounds():
	# Фоны биомов
	_card_backgrounds["biome_" + str(Biome.MOLE_TUNNELS)] = preload("res://img/cards/backgrounds/mole_tunnels_card_bg.png")
	_card_backgrounds["biome_" + str(Biome.ROTTEN_MARSHES)] = preload("res://img/cards/backgrounds/rotten_marshes_card_bg.png")

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
	_card_illustrations[CardId.BLOOD_TRAIL] = preload("res://img/cards/mole_tunnels/blood_trail.png")
	_card_illustrations[CardId.FROZEN_EARTH] = preload("res://img/cards/mole_tunnels/frozen_earth.png")
	_card_illustrations[CardId.RODENT_AGILITY] = preload("res://img/cards/mole_tunnels/rodent_agility.png")
	_card_illustrations[CardId.FROZEN_BITE] = preload("res://img/cards/mole_tunnels/frozen_bite.png")
	_card_illustrations[CardId.ROTTEN_CUT] = preload("res://img/cards/mole_tunnels/rotten_cut.png")
	_card_illustrations[CardId.BEAST_PULSE] = preload("res://img/cards/mole_tunnels/beast_pulse.png")
	_card_illustrations[CardId.BLOOD_THREAD] = preload("res://img/cards/mole_tunnels/blood_thread.png")
	_card_illustrations[CardId.MOLE_TOSS] = preload("res://img/cards/mole_tunnels/mole_toss.png")
	_card_illustrations[CardId.WORM_SPIRIT] = preload("res://img/cards/mole_tunnels/worm_spirit.png")
	_card_illustrations[CardId.FLESH_RAGE] = preload("res://img/cards/mole_tunnels/flesh_rage.png")
	_card_illustrations[CardId.TORN_WOUND] = preload("res://img/cards/mole_tunnels/torn_wound.png")
	
	## Карты биома Гнилые болота
	_card_illustrations[CardId.SNAKE_BITE] = preload("res://img/cards/rotten_marshes/snake_bite.png")
	_card_illustrations[CardId.SWAMP_BLAST] = preload("res://img/cards/rotten_marshes/swamp_blast.png")
	_card_illustrations[CardId.BLESSING_OF_ROT] = preload("res://img/cards/rotten_marshes/blessing_of_rot.png")
	_card_illustrations[CardId.WEAK_SPOT] = preload("res://img/cards/rotten_marshes/weak_spot.png")
	_card_illustrations[CardId.BLOOM_OF_CORRUPTION] = preload("res://img/cards/rotten_marshes/bloom_of_corruption.png")
	_card_illustrations[CardId.MUD_SPLASH] = preload("res://img/cards/rotten_marshes/mud_splash.png")
	_card_illustrations[CardId.BLOOD_INFECTION] = preload("res://img/cards/rotten_marshes/blood_infection.png")
	_card_illustrations[CardId.FOUL_WELL] = preload("res://img/cards/rotten_marshes/foul_well.png")
	_card_illustrations[CardId.EPIDEMIC] = preload("res://img/cards/rotten_marshes/epidemic.png")  # 🆕
	_card_illustrations[CardId.STING_OF_CORRUPTION] = preload("res://img/cards/rotten_marshes/sting_of_corruption.png")
	#_card_illustrations[CardId.BLIND_FURY] = preload("res://img/cards/mole_tunnels/blind_fury.png")
	#_card_illustrations[CardId.SMELL_OF_BLOOD] = preload("res://img/cards/mole_tunnels/smell_of_blood.png")
	#_card_illustrations[CardId.MOLERAT_HIDE] = preload("res://img/cards/mole_tunnels/molerat_hide.png")
	#_card_illustrations[CardId.TUNNEL_AMBUSH] = preload("res://img/cards/mole_tunnels/tunnel_ambush.png")
	#_card_illustrations[CardId.BLOODLETTING] = preload("res://img/cards/mole_tunnels/bloodletting.png")
	# penitent
	_card_illustrations[CardId.BLACK_ENVY] = preload("res://img/cards/penitent/black_envy.png")
	_card_illustrations[CardId.TIME_TO_DIE] = preload("res://img/cards/penitent/time_to_die.png")
	_card_illustrations[CardId.BITTER_VENGEANCE] = preload("res://img/cards/penitent/bitter_vengeance.png")
	_card_illustrations[CardId.PURE_THOUGHTS] = preload("res://img/cards/penitent/pure_thoughts.png")
	_card_illustrations[CardId.BLIND_VENGEANCE] = preload("res://img/cards/penitent/blind_vengeance.png")
	_card_illustrations[CardId.GRIP_OF_DESPAIR] = preload("res://img/cards/penitent/grip_of_despair.png")
	_card_illustrations[CardId.FORGIVENESS] = preload("res://img/cards/penitent/forgiveness.png")

func get_card_illustration(card_id: CardId) -> Texture2D:
	if _card_illustrations.is_empty():
		load_card_illustrations()
	return _card_illustrations.get(card_id, null)


## Иконки валют
const CURRENCY_ICONS: Dictionary = {
	DataManager.CurrencyType.COIN: preload("res://img/icons/currency/coin1.png"),
	DataManager.CurrencyType.BONE: preload("res://img/icons/currency/bone1.png"),
}

## Иконки артефактов
const ARTIFACT_ICONS: Dictionary = {
	DataManager.ArtifactId.STRANGE_MUSHROOM: preload("res://img/icons/artifacts/strange_mushroom1.png"),
	DataManager.ArtifactId.HEROS_BROOCH: preload("res://img/icons/artifacts/heros_brooch1.png"),
	DataManager.ArtifactId.KINGS_ORDER: preload("res://img/icons/artifacts/kings_order1.png"),
	DataManager.ArtifactId.HEALERS_AMULET: preload("res://img/icons/artifacts/healers_amulet1.png"),
	DataManager.ArtifactId.ABYSS_DUST: preload("res://img/icons/artifacts/abyss_dust1.png"),
	DataManager.ArtifactId.TROLL_BLADE: preload("res://img/icons/artifacts/troll_blade1.png"),
	DataManager.ArtifactId.IMP_BLADE: preload("res://img/icons/artifacts/imp_blade1.png"),
	DataManager.ArtifactId.PLAGUE_AMULET: preload("res://img/icons/artifacts/plague_amulet1.png"),
	DataManager.ArtifactId.ARACHNID_BELT: preload("res://img/icons/artifacts/arachnid_belt1.png"),  # 🆕
	DataManager.ArtifactId.RUNIC_HELM: preload("res://img/icons/artifacts/runic_helm1.png"),  # 🆕
	DataManager.ArtifactId.DRAGON_BROOCH: preload("res://img/icons/artifacts/dragon_brooch1.png"),  # 🆕
	DataManager.ArtifactId.RUSTY_NAIL: preload("res://img/icons/artifacts/rusty_nail1.png"),  # 🆕
	DataManager.ArtifactId.THORN_CROWN: preload("res://img/icons/artifacts/thorn_crown1.png"),  # 🆕
	DataManager.ArtifactId.SERRATED_KNUCKLE: preload("res://img/icons/artifacts/serrated_knuckle1.png"),  # 🆕
	DataManager.ArtifactId.RING_OF_BARRICADE: preload("res://img/icons/artifacts/ring_of_barricade1.png"),  # 🆕
	DataManager.ArtifactId.LUCKY_PICK: preload("res://img/icons/artifacts/lucky_pick1.png"),  # 🆕
	DataManager.ArtifactId.INSATIABLE_BLADE: preload("res://img/icons/artifacts/insatiable_blade1.png"),  # 🆕
}


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
const COLOR_FLESH_CAVES_ART_BG_BRIGHT: Color = Color("9E1A1A")     # ярко-красный
const COLOR_FLESH_CAVES_ART_BG_PASTELE: Color = Color("7D2D2D")     # ярко-красный
const COLOR_BONE_LABYRINTH_ART_BG_DARK: Color = Color("332E26")  # тёмно-серый

# === СВЕТЛЫЕ ЦВЕТА (альтернативные) ===
const COLOR_PENITENT_ART_BG_LIGHT2: Color = Color("C47A7A")     # светло-бордовый
const COLOR_PENITENT_ART_BG_LIGHT: Color = Color("faeceb")     # светло-бордовый
const COLOR_WARRIOR_ART_BG_LIGHT: Color = Color("8A8ABF")      # светло-синий
const COLOR_MYSTIC_ART_BG_LIGHT: Color = Color("8A5ABF")       # светло-фиолетовый
const COLOR_ROGUE_ART_BG_LIGHT: Color = Color("6ABF6A")        # светло-зелёный

const COLOR_MOLE_TUNNELS_ART_BG_LIGHT: Color = Color("BFA86A")     # светло-коричневый
const COLOR_MOLE_TUNNELS_ART_BG_LIGHT2: Color = Color("e9dab0ff")     # светло-коричневый
const COLOR_FLESH_CAVES_ART_BG_LIGHT: Color = Color("BF6A6A")      # светло-красный
const COLOR_BONE_LABYRINTH_ART_BG_LIGHT: Color = Color("BFB8A6")   # светло-серый

# === ЦВЕТА БИОМА: ГНИЛОСТНЫЕ ТОПИ ===
const COLOR_ROTTEN_MARSHES_ART_BG_DARK: Color = Color("1A2A1A")      # тёмно-болотный (зелёный оттенок)
const COLOR_ROTTEN_MARSHES_ART_BG_LIGHT: Color = Color("6A8A5A")     # светло-болотный (зелёный)
const COLOR_ROTTEN_MARSHES_ART_BG_PASTEL: Color = Color("9AB88A")    # пастельно-болотный (светло-зелёный)
const COLOR_ROTTEN_MARSHES_CARD_BG: Color = Color("5A7A4A")          # грязно-болотный (фон карты)
const COLOR_ROTTEN_MARSHES_ART_BG_PURPLE: Color = Color("5A3A6A")    # фиолетовый (наросты, слизь)
const COLOR_ROTTEN_MARSHES_ART_BG_PALE_PURPLE: Color = Color("8A7A9E") # бледно-фиолетовый (плоть)
const COLOR_ROTTEN_MARSHES_ART_BG_DARK_PURPLE: Color = Color("3A2A4A") # тёмно-фиолетовый (глубокие тени)
const COLOR_ROTTEN_MARSHES_ART_BG_MINT: Color = Color("bfd0b7")      # бледно-мятный (светящиеся грибы, токсичные испарения)

const COLOR_DAMAGE_LOG: Color = Color(1, 0.3, 0.2)
const COLOR_HEAL_LOG: Color = Color(0.4, 0.8, 0.3)

const COLOR_GRAY_NEAR_BLACK: Color = Color("1A1510")   # почти чёрный серый
## ============================================================
## ЦВЕТА ИСКУПЛЕНИЯ (ATONEMENT)
## ============================================================

# Тёмный космический фиолетово-синий
const COLOR_ATONEMENT_DARK: Color = Color("1a0a2e")     # глубокий фиолетовый
const COLOR_ATONEMENT_MID: Color = Color("3d1f6d")      # средне-фиолетовый
const COLOR_ATONEMENT_LIGHT: Color = Color("7a4db3")    # светло-фиолетовый
const COLOR_ATONEMENT_GLOW: Color = Color("a87fd4")     # свечение

# Альтернативный вариант — глубокий синий с фиолетовым отливом
const COLOR_ATONEMENT_BLUE: Color = Color("0a1628")     # космический синий
const COLOR_ATONEMENT_PURPLE: Color = Color("2d1b4e")    # фиолетово-синий
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
# === НОВЫЕ ЦВЕТА ДЛЯ UI ===

# Серые (от светлого к тёмному)
const COLOR_GRAY_LIGHTEST: Color = Color("E8E6E3")      # очень светлый серый
const COLOR_GRAY_LIGHT: Color = Color("C4C0BA")        # светлый серый
const COLOR_GRAY_MID: Color = Color("8A8580")          # средний серый
const COLOR_GRAY_DARK: Color = Color("4A4540")         # тёмный серый
const COLOR_GRAY_DARKEST: Color = Color("2A2520")      # очень тёмный серый

# Дополнительные тёмные (для фонов)
const COLOR_DARK_RED: Color = Color("4A1A1A")           # тёмно-красный
const COLOR_DARK_BROWN: Color = Color("3A2A1A")         # тёмно-коричневый
const COLOR_DARK_GREEN: Color = Color("1A2A1A")         # тёмно-зелёный
const COLOR_DARK_BLUE: Color = Color("1A1A3A")          # тёмно-синий
const COLOR_DARK_PURPLE: Color = Color("2A1A3A")        # тёмно-фиолетовый

# Дополнительные светлые (для акцентов)
const COLOR_LIGHT_RED: Color = Color("D4A0A0")          # светло-красный
const COLOR_LIGHT_BROWN: Color = Color("D4C0A0")        # светло-коричневый
const COLOR_LIGHT_GREEN: Color = Color("A0D4A0")        # светло-зелёный
const COLOR_LIGHT_BLUE: Color = Color("A0A0D4")         # светло-синий
const COLOR_LIGHT_PURPLE: Color = Color("C0A0D4")       # светло-фиолетовый

# Акцентные цвета
const COLOR_ACCENT_GOLD: Color = Color("D4B040")        # золотой
const COLOR_ACCENT_COPPER: Color = Color("B08030")      # медный
const COLOR_ACCENT_BRONZE: Color = Color("8A6A2A")      # бронзовый
const COLOR_ACCENT_SILVER: Color = Color("C0C0C0")      # серебряный
const COLOR_ACCENT_IRON: Color = Color("6A6A6A")        # железный

# Цвета для состояний кнопок
const COLOR_BUTTON_DISABLED_BG: Color = Color("404040")      # фон отключённой кнопки
const COLOR_BUTTON_DISABLED_BORDER: Color = Color("606060")  # обводка отключённой кнопки
const COLOR_BUTTON_DISABLED_TEXT: Color = Color("808080")    # текст отключённой кнопки
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
				Biome.ROTTEN_MARSHES:  # 🆕
					return COLOR_ROTTEN_MARSHES_ART_BG_DARK
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
					return COLOR_MOLE_TUNNELS_ART_BG_LIGHT2
				Biome.FLESH_CAVES:
					return COLOR_FLESH_CAVES_ART_BG_LIGHT
				Biome.BONE_LABYRINTH:
					return COLOR_BONE_LABYRINTH_ART_BG_LIGHT
				Biome.ROTTEN_MARSHES:  # 🆕
					return COLOR_ROTTEN_MARSHES_ART_BG_MINT
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


## ============================================================
## ЗВУКОВЫЕ ЭФФЕКТЫ
## ============================================================

var _sounds: Dictionary = {}
var _sounds_loaded: bool = false

func load_sounds():
	if _sounds_loaded:
		return
	
	# UI
	_sounds[SoundType.CARD_HOVER] = preload("res://sound/JDSherbert - Tabletop Games SFX Pack - Piece Move - 1.mp3")
	#_sounds[SoundType.CARD_CLICK] = preload("res://audio/sfx/ui/card_click.wav")
	#_sounds[SoundType.CARD_PLAY] = preload("res://audio/sfx/ui/card_play.wav")
	#_sounds[SoundType.CARD_DISCARD] = preload("res://audio/sfx/ui/card_discard.wav")
	#_sounds[SoundType.CARD_BURN] = preload("res://audio/sfx/ui/card_burn.wav")
	_sounds[SoundType.CARD_DRAW] = preload("res://sound/JDSherbert - Tabletop Games SFX Pack - Deck Deal - 1.mp3")
	#_sounds[SoundType.BUTTON_CLICK] = preload("res://audio/sfx/ui/button_click.wav")
	#_sounds[SoundType.BUTTON_HOVER] = preload("res://audio/sfx/ui/button_hover.wav")
	
	# Бой
	_sounds[SoundType.ENEMY_GET_DAMAGE] = preload("res://sound/DesignedPunch4.wav")
	#_sounds[SoundType.ENEMY_ATTACK] = preload("res://audio/sfx/battle/enemy_attack.wav")
	_sounds[SoundType.PLAYER_GET_DAMAGE] = preload("res://sound/DesignedPunch4.wav")
	#_sounds[SoundType.PLAYER_ATTACK] = preload("res://audio/sfx/battle/player_attack.wav")
	_sounds[SoundType.BLOCK] = preload("res://sound/223630__ctcollab__shield-hit-1.wav")
	_sounds[SoundType.HEAL] = preload("res://sound/140849__garyq__skyrim-heal-start.wav")
	#_sounds[SoundType.DEATH] = preload("res://audio/sfx/battle/death.wav")
	_sounds[SoundType.APPLY_DEBUFF] = preload("res://sound/evade.wav")
	#
	## Статусы
	#_sounds[SoundType.POISON_TICK] = preload("res://audio/sfx/status/poison_tick.wav")
	#_sounds[SoundType.BLEED_TICK] = preload("res://audio/sfx/status/bleed_tick.wav")
	#_sounds[SoundType.BURN_TICK] = preload("res://audio/sfx/status/burn_tick.wav")
	#
	## Победа/поражение
	#_sounds[SoundType.VICTORY] = preload("res://audio/sfx/ui/victory.wav")
	#_sounds[SoundType.DEFEAT] = preload("res://audio/sfx/ui/defeat.wav")
	#
	## Музыка
	#_sounds[SoundType.MUSIC_MENU] = preload("res://audio/music/menu_theme.ogg")
	#_sounds[SoundType.MUSIC_GAMEPLAY] = preload("res://audio/music/gameplay_theme.ogg")
	#_sounds[SoundType.MUSIC_BOSS] = preload("res://audio/music/boss_theme.ogg")
	_sounds[SoundType.GET_GOLD] = preload("res://sound/270408__littlerobotsoundfactory__pickup_gold_00.wav")
	_sounds[SoundType.GET_POTION] = preload("res://sound/SmallGlassBottles1.wav")
	_sounds[SoundType.GET_SOMETHING] = preload("res://sound/PaperDocument1.wav")
	
	
	_sounds_loaded = true


func get_sound(sound_type: SoundType) -> AudioStream:
	if not _sounds_loaded:
		load_sounds()
	return _sounds.get(sound_type, null)


## ============================================================
## ШЕЙДЕРЫ ДЛЯ UI
## ============================================================

## Применяет шейдер напрямую к TextureRect
func apply_shader_to_icon(icon: TextureRect, shader_path: String, params: Dictionary = {}):
	var shader = load(shader_path)
	if not shader:
		printerr("Shader not found: ", shader_path)
		return null
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Применяем параметры
	for key in params.keys():
		shader_material.set_shader_parameter(key, params[key])
	
	icon.material = shader_material
	return shader_material


## Применяет шейдер через ColorRect-оверлей поверх TextureRect
func apply_shader_overlay(icon: TextureRect, shader_path: String, params: Dictionary = {}):
	var shader = load(shader_path)
	if not shader:
		printerr("Shader not found: ", shader_path)
		return null
	
	var overlay = ColorRect.new()
	overlay.color = Color(1, 1, 1, 1)  # полностью прозрачныйcreen_texture
	
	overlay.anchor_left = 0.0
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 1
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	for key in params.keys():
		shader_material.set_shader_parameter(key, params[key])
	
	overlay.material = shader_material
	
	icon.add_child(overlay)
	return overlay


## Удаляет оверлей с иконки
func remove_shader_overlay(icon: TextureRect):
	if icon.get_child_count() > 0:
		var overlay = icon.get_child(0)
		if overlay is ColorRect:
			icon.remove_child(overlay)
			overlay.queue_free()


## Удаляет шейдер с иконки
func remove_shader_from_icon(icon: TextureRect):
	icon.material = null


## Возвращает все карты
func get_all_cards() -> Dictionary:
	if not _cards_loaded:
		load_all_cards()
	return _cards


## Получить все ID карт
func get_all_card_ids() -> Array[CardId]:
	if not _cards_loaded:
		load_all_cards()
	return _cards.keys()


func get_currency_icon(currency_type: CurrencyType) -> Texture2D:
	return CURRENCY_ICONS.get(currency_type, null)


## Возвращает массив ID артефактов по грейду
func get_artifacts_by_grade(grade: ArtifactGrade) -> Array[ArtifactId]:
	if not _artifact_resources_loaded:
		load_artifact_resources()
	
	var result: Array[ArtifactId] = []
	for artifact_id in _artifact_resources.keys():
		var resource = _artifact_resources[artifact_id]
		if resource and resource.grade == grade:
			result.append(artifact_id)
	return result


func get_artifact_icon(artifact_id: ArtifactId) -> Texture2D:
	return ARTIFACT_ICONS.get(artifact_id, null)


func get_artifact_name(artifact_id: ArtifactId) -> String:
	match artifact_id:
		ArtifactId.STRANGE_MUSHROOM:
			return tr("artifact_strange_mushroom_name")
		ArtifactId.HEROS_BROOCH:
			return tr("artifact_heros_brooch_name")
		ArtifactId.KINGS_ORDER:
			return tr("artifact_kings_order_name")
		ArtifactId.HEALERS_AMULET:
			return tr("artifact_healers_amulet_name")
		ArtifactId.ABYSS_DUST:
			return tr("artifact_abyss_dust_name")
		ArtifactId.TROLL_BLADE:  # 🆕
			return tr("artifact_troll_blade_name")
		ArtifactId.IMP_BLADE:  # 🆕
			return tr("artifact_imp_blade_name")
		ArtifactId.PLAGUE_AMULET:  # 🆕
			return tr("artifact_plague_amulet_name")
		ArtifactId.ARACHNID_BELT:  # 🆕
			return tr("artifact_arachnid_belt_name")
		ArtifactId.RUNIC_HELM:  # 🆕
			return tr("artifact_runic_helm_name")
		ArtifactId.DRAGON_BROOCH:  # 🆕
			return tr("artifact_dragon_brooch_name")
		ArtifactId.RUSTY_NAIL:  # 🆕
			return tr("artifact_rusty_nail_name")
		ArtifactId.THORN_CROWN:  # 🆕
			return tr("artifact_thorn_crown_name")
		ArtifactId.SERRATED_KNUCKLE:  # 🆕
			return tr("artifact_serrated_knuckle_name")
		ArtifactId.RING_OF_BARRICADE:  # 🆕
			return tr("artifact_ring_of_barricade_name")
		ArtifactId.LUCKY_PICK:  # 🆕
			return tr("artifact_lucky_pick_name")
		ArtifactId.INSATIABLE_BLADE:  # 🆕
			return tr("artifact_insatiable_blade_name")
		_:
			return tr("artifact_unknown_name")

func get_artifact_description(artifact_id: ArtifactId) -> String:
	match artifact_id:
		ArtifactId.STRANGE_MUSHROOM:
			return tr("artifact_strange_mushroom_desc") % [
				ARTIFACT_STRANGE_MUSHROOM_HP_BONUS,
				ARTIFACT_STRANGE_MUSHROOM_POISON_DURATION
			]
		ArtifactId.HEROS_BROOCH:
			return tr("artifact_heros_brooch_desc") % [
				ARTIFACT_HEROS_BROOCH_TURN_INTERVAL,
				ARTIFACT_HEROS_BROOCH_STRENGTH_STACKS
			]
		ArtifactId.KINGS_ORDER:
			return tr("artifact_kings_order_desc") % [
				ARTIFACT_KINGS_ORDER_CARD_COUNT,
				ARTIFACT_KINGS_ORDER_DAMAGE_MULTIPLIER
			]
		ArtifactId.HEALERS_AMULET:
			return tr("artifact_healers_amulet_desc") % [
				ARTIFACT_HEALERS_AMULET_STATUS_THRESHOLD,
				ARTIFACT_HEALERS_AMULET_HEAL_AMOUNT
			]
		ArtifactId.ABYSS_DUST:
			return tr("artifact_abyss_dust_desc") % ARTIFACT_ABYSS_DUST_CARD_COST
		ArtifactId.TROLL_BLADE:  # 🆕
			return tr("artifact_troll_blade_desc")
		ArtifactId.IMP_BLADE:  # 🆕
			return tr("artifact_imp_blade_desc")
		ArtifactId.PLAGUE_AMULET:  # 🆕
			return tr("artifact_plague_amulet_desc")
		ArtifactId.ARACHNID_BELT:  # 🆕
			return tr("artifact_arachnid_belt_desc")
		ArtifactId.RUNIC_HELM:
			var artifact = get_artifact_resource(ArtifactId.RUNIC_HELM)
			if artifact and artifact.effects.size() > 0:
				var effect = artifact.effects[0]
				return tr("artifact_runic_helm_desc") % [
					effect.base_value  # количество щита
				]
			return tr("artifact_runic_helm_desc") % [10]  # fallback
		ArtifactId.DRAGON_BROOCH:  # 🆕
			var artifact = get_artifact_resource(ArtifactId.DRAGON_BROOCH)
			if artifact:
				return tr("artifact_dragon_brooch_desc") % [
					artifact.amount_check_conditional,  # процент здоровья
					artifact.effects[0].passive.starting_charges if artifact.effects.size() > 0 and artifact.effects[0].passive else 3
				]
			return tr("artifact_dragon_brooch_desc") % [50, 3]  # fallback
		ArtifactId.RUSTY_NAIL:
			var artifact = get_artifact_resource(ArtifactId.RUSTY_NAIL)
			if artifact and artifact.effects.size() > 0:
				var effect = artifact.effects[0]
				return tr("artifact_rusty_nail_desc") % [
					effect.value,    # стаки
					effect.duration  # длительность
				]
			return tr("artifact_rusty_nail_desc") % [1, 2]  # fallback
		ArtifactId.THORN_CROWN:  # 🆕
			var artifact = get_artifact_resource(ArtifactId.THORN_CROWN)
			if artifact and artifact.effects.size() >= 2:
				var damage_effect = artifact.effects[0]
				var denial_effect = artifact.effects[1]
				return tr("artifact_thorn_crown_desc") % [
					damage_effect.base_value,  # урон
					denial_effect.passive_duration  # заряды Denial
				]
			return tr("artifact_thorn_crown_desc") % [3, 3]  # fallback
		ArtifactId.SERRATED_KNUCKLE:  # 🆕
			return tr("artifact_serrated_knuckle_desc")
		ArtifactId.RING_OF_BARRICADE:  # 🆕
			var artifact = get_artifact_resource(ArtifactId.RING_OF_BARRICADE)
			if artifact:
				return tr("artifact_ring_of_barricade_desc") % [
					artifact.damage_threshold,  # порог
					artifact.effects[0].base_value if artifact.effects.size() > 0 else 10  # щит
				]
			return tr("artifact_ring_of_barricade_desc") % [8, 10]  # fallback
		ArtifactId.LUCKY_PICK:  # 🆕
			return tr("artifact_lucky_pick_desc")
		ArtifactId.INSATIABLE_BLADE:  # 🆕
			var artifact = get_artifact_resource(ArtifactId.INSATIABLE_BLADE)
			if artifact:
				return tr("artifact_insatiable_blade_desc") % [
					artifact.attack_threshold,
					artifact.effects[0].base_value if artifact.effects.size() > 0 else 3
				]
			return tr("artifact_insatiable_blade_desc") % [3, 3]
		_:
			return ""


var _artifact_resources: Dictionary = {}  # ArtifactId -> ArtifactResource
var _artifact_resources_loaded: bool = false

func load_artifact_resources() -> void:
	if _artifact_resources_loaded:
		return
	
	_artifact_resources[ArtifactId.STRANGE_MUSHROOM] = load("res://resources/artifacts/strange_mushroom.tres")
	_artifact_resources[ArtifactId.HEROS_BROOCH] = load("res://resources/artifacts/heros_brooch.tres")
	_artifact_resources[ArtifactId.KINGS_ORDER] = load("res://resources/artifacts/kings_order.tres")
	_artifact_resources[ArtifactId.HEALERS_AMULET] = load("res://resources/artifacts/healers_amulet.tres")
	_artifact_resources[ArtifactId.ABYSS_DUST] = load("res://resources/artifacts/abyss_dust.tres")
	_artifact_resources[ArtifactId.TROLL_BLADE] = load("res://resources/artifacts/troll_blade.tres")  # 🆕
	_artifact_resources[ArtifactId.IMP_BLADE] = load("res://resources/artifacts/imp_blade.tres")
	_artifact_resources[ArtifactId.PLAGUE_AMULET] = load("res://resources/artifacts/plague_amulet.tres")
	_artifact_resources[ArtifactId.ARACHNID_BELT] = load("res://resources/artifacts/arachnid_belt.tres")  # 🆕
	_artifact_resources[ArtifactId.RUNIC_HELM] = load("res://resources/artifacts/runic_helm.tres")  # 🆕
	_artifact_resources[ArtifactId.DRAGON_BROOCH] = load("res://resources/artifacts/dragon_brooch.tres")  # 🆕
	_artifact_resources[ArtifactId.RUSTY_NAIL] = load("res://resources/artifacts/rusty_nail.tres")  # 🆕
	_artifact_resources[ArtifactId.THORN_CROWN] = load("res://resources/artifacts/thorn_crown.tres")  # 🆕
	_artifact_resources[ArtifactId.SERRATED_KNUCKLE] = load("res://resources/artifacts/serrated_knuckle.tres")  # 🆕
	_artifact_resources[ArtifactId.RING_OF_BARRICADE] = load("res://resources/artifacts/ring_of_barricade.tres")  # 🆕
	_artifact_resources[ArtifactId.LUCKY_PICK] = load("res://resources/artifacts/lucky_pick.tres")  # 🆕
	_artifact_resources[ArtifactId.INSATIABLE_BLADE] = load("res://resources/artifacts/insatiable_blade.tres")  # 🆕
	_artifact_resources_loaded = true

func get_random_artifact_by_grade(grade: ArtifactGrade) -> ArtifactResource:
	var ids = get_artifacts_by_grade(grade)
	if ids.is_empty():
		return null
	var random_id = ids[randi() % ids.size()]
	return get_artifact_resource(random_id)


func get_artifact_resource(artifact_id: ArtifactId) -> ArtifactResource:
	if not _artifact_resources_loaded:
		load_artifact_resources()
	return _artifact_resources.get(artifact_id, null)


func get_all_artifact_ids() -> Array:
	if not _artifact_resources_loaded:
		load_artifact_resources()
	return _artifact_resources.keys()


## Размеры объектов по типам
const OBJECT_SIZES: Dictionary = {
	DataManager.ObjectType.CHEST: Vector2(256, 256),
	DataManager.ObjectType.IDOL: Vector2(360, 360),
	DataManager.ObjectType.TRAP: Vector2(160, 160),
	DataManager.ObjectType.CAULDRON: Vector2(256, 256),
	DataManager.ObjectType.TORTURE_RACK: Vector2(360, 360),
	DataManager.ObjectType.BONFIRE: Vector2(256, 256),
	DataManager.ObjectType.SHOP: Vector2(1024, 800),
	DataManager.ObjectType.EVENT: Vector2(1024, 800),
}

func get_object_size(object_type: DataManager.ObjectType) -> Vector2:
	return OBJECT_SIZES.get(object_type, Vector2(196, 196))


## Пул эффектов для преобразования карт
const TRANSFORM_EFFECT_POOL: Dictionary = {
	"DAMAGE": [DataManager.EffectCategory.DAMAGE],
	"BLOCK": [DataManager.EffectCategory.BLOCK],
	"HEAL": [DataManager.EffectCategory.HEAL],
	"APPLY_STATUS": [DataManager.EffectCategory.APPLY_STATUS],
	"DRAW_CARD": [DataManager.EffectCategory.DRAW_CARD],
	"GAIN_ENERGY": [DataManager.EffectCategory.GAIN_ENERGY],
}

func get_random_effect_from_pool(categories: Array) -> EffectEntry:
	var category = categories[randi() % categories.size()]
	var effect = EffectEntry.new()
	effect.category = category
	effect.target = DataManager.EffectTarget.SELF
	
	match category:
		DataManager.EffectCategory.DAMAGE:
			effect.base_value = randi() % 3 + 2  # 2-4
			effect.target = DataManager.EffectTarget.ENEMY
		DataManager.EffectCategory.BLOCK:
			effect.base_value = randi() % 4 + 3  # 3-6
		DataManager.EffectCategory.HEAL:
			effect.base_value = randi() % 3 + 2  # 2-4
		DataManager.EffectCategory.APPLY_STATUS:
			var statuses = [
				DataManager.Status.POISON,
				DataManager.Status.BLEED,
				DataManager.Status.WEAKNESS,
				DataManager.Status.VULNERABILITY,
			]
			var status_id = statuses[randi() % statuses.size()]
			effect.status = DataManager.get_status_resource(status_id)
			effect.value = randi() % 3 + 1  # 1-3
			effect.duration = randi() % 3 + 2  # 2-4
			effect.target = DataManager.EffectTarget.ENEMY
		DataManager.EffectCategory.DRAW_CARD:
			effect.amount = randi() % 2 + 1  # 1-2
		DataManager.EffectCategory.GAIN_ENERGY:
			effect.amount = 1
	
	return effect


const POTION_ICONS: Dictionary = {
	DataManager.PotionType.HEAL: preload("res://img/potions/heal_potion1.png"),
	DataManager.PotionType.ENERGY: preload("res://img/potions/energy_potion1.png"),
	DataManager.PotionType.DRAW: preload("res://img/potions/draw_potion1.png"),
	DataManager.PotionType.EXPLOSION: preload("res://img/potions/explosion_potion1.png"),
	DataManager.PotionType.STATUS_CLEANSE: preload("res://img/potions/status_cleanse_potion1.png"),
	DataManager.PotionType.POISON: preload("res://img/potions/poison_potion1.png"),
	DataManager.PotionType.BLOCK: preload("res://img/potions/block_potion1.png"),
}

func get_potion_icon(potion_type: DataManager.PotionType) -> Texture2D:
	return POTION_ICONS.get(potion_type, null)


var _potion_resources: Dictionary = {}  # PotionType -> PotionResource
var _potion_resources_loaded: bool = false

func load_potion_resources() -> void:
	if _potion_resources_loaded:
		return
	
	_potion_resources[DataManager.PotionType.HEAL] = load("res://resources/potions/heal_potion.tres")
	_potion_resources[DataManager.PotionType.ENERGY] = load("res://resources/potions/energy_potion.tres")
	_potion_resources[DataManager.PotionType.DRAW] = load("res://resources/potions/draw_potion.tres")
	_potion_resources[DataManager.PotionType.EXPLOSION] = load("res://resources/potions/explosion_potion.tres")
	_potion_resources[DataManager.PotionType.STATUS_CLEANSE] = load("res://resources/potions/cleanse_potion.tres")
	_potion_resources[DataManager.PotionType.POISON] = load("res://resources/potions/poison_potion.tres")
	_potion_resources[DataManager.PotionType.BLOCK] = load("res://resources/potions/block_potion.tres")
	
	_potion_resources_loaded = true

func get_potion_resource_by_type(potion_type: DataManager.PotionType) -> PotionResource:
	if not _potion_resources_loaded:
		load_potion_resources()
	return _potion_resources.get(potion_type, null)

func get_potion_resource_by_id(potion_id: String) -> PotionResource:
	if not _potion_resources_loaded:
		load_potion_resources()
	
	# Ищем по ключу (для обратной совместимости)
	for key in _potion_resources.keys():
		var resource = _potion_resources[key]
		if resource.resource_path == potion_id or resource.resource_path.get_file() == potion_id:
			return resource
	return null

func get_random_potions(count: int) -> Array[PotionResource]:
	if not _potion_resources_loaded:
		load_potion_resources()
	
	var result: Array[PotionResource] = []
	var potion_list = _potion_resources.values()
	
	potion_list.shuffle()
	
	for i in range(min(count, potion_list.size())):
		result.append(potion_list[i])
	
	return result


func create_button(text: String, button_type: ButtonType = ButtonType.DEFAULT, icon: Texture2D = null, is_potion: bool = false) -> Button:
	var button = Button.new()
	button.text = text
	if icon:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_theme_constant_override("icon_max_width", 32)
	
	# Настройка шрифта
	button.add_theme_font_override("font", FONT_HEADERS)
	button.add_theme_font_size_override("font_size", 20)
	
	# Настройка отступов
	button.add_theme_constant_override("h_separation", 8)
	button.focus_mode = Control.FOCUS_NONE
	

	# Настройка стилей
	var normal_style = _get_button_style(button_type, false, false, false, is_potion)
	var hover_style = _get_button_style(button_type, true, true, false, is_potion)
	var pressed_style = _get_button_style(button_type, true, false, false, is_potion)
	var disabled_style = _get_button_style(button_type, false, false, true, is_potion)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Цвета текста
	var normal_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var hover_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var pressed_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var disabled_color = COLOR_PENITENT_ART_BG_DARK
	
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", pressed_color)
	button.add_theme_color_override("font_disabled_color", disabled_color)
	
	if is_potion:
		button.add_theme_font_size_override("font_size", 14)
	
	return button

func _get_button_style(button_type: ButtonType, is_active: bool, is_hover: bool = false, is_disabled: bool = false, is_potion: bool = false) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	
	# --- ФОН ---
	if is_disabled:
		style.bg_color = COLOR_BUTTON_DISABLED_BG
	elif is_active:
		style.bg_color = COLOR_BONE_LABYRINTH_ART_BG_DARK
	else:
		# В зависимости от типа кнопки выбираем фон
		match button_type:
			ButtonType.PRIMARY:
				style.bg_color = Color.BLACK
			ButtonType.SECONDARY:
				style.bg_color = COLOR_GRAY_DARK
			ButtonType.DANGER:
				style.bg_color = COLOR_DARK_RED
			ButtonType.SUCCESS:
				style.bg_color = COLOR_DARK_GREEN
			_:
				style.bg_color = COLOR_GRAY_DARK
	
	# --- ОБВОДКА ---
	var border_color: Color
	if is_disabled:
		border_color = COLOR_PENITENT_ART_BG_DARK
	elif is_active:
		border_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	else:
		match button_type:
			ButtonType.PRIMARY:
				border_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
			ButtonType.SECONDARY:
				border_color = COLOR_GRAY_LIGHT
			ButtonType.DANGER:
				border_color = COLOR_FLESH_CAVES_ART_BG_LIGHT
			ButtonType.SUCCESS:
				border_color = COLOR_LIGHT_GREEN
			_:
				border_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT2
	
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = border_color
	
	# --- СКРУГЛЕНИЕ ---
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	
	# --- ОТСТУПЫ ---
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	
	if is_potion:
		# --- ОТСТУПЫ ---
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
	
	return style


func apply_button_style(button: Button, button_type: ButtonType = ButtonType.DEFAULT, icon: Texture2D = null, is_potion: bool = false) -> void:
	if icon:
		button.icon = icon
		button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		button.add_theme_constant_override("icon_max_width", 32)
	
	# Настройка шрифта
	button.add_theme_font_override("font", FONT_HEADERS)
	button.add_theme_font_size_override("font_size", 20)
	
	# Настройка отступов
	button.add_theme_constant_override("h_separation", 8)
	button.focus_mode = Control.FOCUS_NONE
	
	# Настройка стилей
	var normal_style = _get_button_style(button_type, false, false, false, is_potion)
	var hover_style = _get_button_style(button_type, true, true, false, is_potion)
	var pressed_style = _get_button_style(button_type, true, false, false, is_potion)
	var disabled_style = _get_button_style(button_type, false, false, true, is_potion)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("disabled", disabled_style)
	
	# Цвета текста
	var normal_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var hover_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var pressed_color = COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	var disabled_color = COLOR_PENITENT_ART_BG_DARK
	
	button.add_theme_color_override("font_color", normal_color)
	button.add_theme_color_override("font_hover_color", hover_color)
	button.add_theme_color_override("font_pressed_color", pressed_color)
	button.add_theme_color_override("font_disabled_color", disabled_color)
	
	if is_potion:
		button.add_theme_font_size_override("font_size", 14)


const EVENT_TEXTURES: Dictionary = {
	DataManager.Biome.MOLE_TUNNELS: {
		DataManager.EventType.MINER: preload("res://img/events/mole_tunnels/miner.png"),
		DataManager.EventType.DANGER_BEHIND: preload("res://img/events/mole_tunnels/danger_behind.png"),  # 🆕
		DataManager.EventType.LEONARDO_KROTINI: preload("res://img/events/mole_tunnels/leonardo_krotini.png"),  # 🆕
	},
	DataManager.Biome.ROTTEN_MARSHES: {  # 🆕
		DataManager.EventType.UNDERGROUND_POOL: preload("res://img/events/rotten_marshes/underground_pool.png"),
		DataManager.EventType.FLOWER: preload("res://img/events/rotten_marshes/flower.png"),  # 🆕
		DataManager.EventType.DIAMOND_WEDDING: preload("res://img/events/rotten_marshes/diamond_wedding.png"),  # 🆕
	},
}

func get_event_texture(event_type: DataManager.EventType, biome: DataManager.Biome) -> Texture2D:
	var biome_dict = EVENT_TEXTURES.get(biome, {})
	return biome_dict.get(event_type, null)


var _event_resources: Dictionary = {}  # biome -> Array[EventResource]
var _event_resources_loaded: bool = false

func load_event_resources() -> void:
	if _event_resources_loaded:
		return
	
	# TODO: загружать события для каждого биома
	# Пока заглушка
	_event_resources[DataManager.Biome.MOLE_TUNNELS] = [
		load("res://resources/events/mole_tunnels/miner.tres"),
		load("res://resources/events/mole_tunnels/danger_behind.tres"),  # 🆕
		load("res://resources/events/mole_tunnels/leonardo_krotini.tres"),  # 🆕
		#load("res://resources/events/mole_tunnels/merchant.tres"),
		# ... другие события
	]
	# 🆕 Гнилостные Топи
	_event_resources[DataManager.Biome.ROTTEN_MARSHES] = [
		load("res://resources/events/rotten_marshes/underground_pool.tres"),
		load("res://resources/events/rotten_marshes/flower.tres"),  # 🆕
		load("res://resources/events/rotten_marshes/diamond_wedding.tres"),  # 🆕
	
	]
	
	_event_resources_loaded = true

func get_event_for_biome(biome: DataManager.Biome) -> EventResource:
	if not _event_resources_loaded:
		load_event_resources()
	
	var events = _event_resources.get(biome, [])
	if events.is_empty():
		return null
	
	# Берём первый и переставляем в конец (циклический пул)
	var event = events.pop_front()
	events.append(event)
	return event


func get_enemies_for_biome(biome: DataManager.Biome) -> Array[DataManager.EnemyId]:
	match biome:
		DataManager.Biome.MOLE_TUNNELS:
			return [
				DataManager.EnemyId.MOLE_MUTANT,
				DataManager.EnemyId.STRONG_MOLE,
				DataManager.EnemyId.RABID_RAT,
				DataManager.EnemyId.MOLE_FUNGUS,
				DataManager.EnemyId.MANY_HEADED_MOLE,
				DataManager.EnemyId.FUNGAL_MINER,
				DataManager.EnemyId.RODENT_MOUND,
			]
		# DataManager.Biome.FLESH_CAVES:
			# return [...]
		_:
			return []


func get_room_label(room: RoomNode) -> String:
	if not room.is_revealed:
		return tr("room_unknown")
	
	match room.room_type:
		DataManager.RoomType.COMBAT:
			match room.combat_type:
				DataManager.CombatType.NORMAL:
					return tr("room_combat_normal")
				DataManager.CombatType.ELITE:
					return tr("room_combat_elite")
				DataManager.CombatType.BOSS:
					return tr("room_combat_boss")
				_:
					return tr("room_combat")
		DataManager.RoomType.OBJECT:
			match room.object_type:
				DataManager.ObjectType.SHOP:
					return tr("room_shop")
				DataManager.ObjectType.EVENT:
					return tr("room_event")
				DataManager.ObjectType.CHEST:
					return tr("room_chest")
				DataManager.ObjectType.TRAP:
					return tr("room_trap")
				DataManager.ObjectType.BONFIRE:
					return tr("room_bonfire")
				DataManager.ObjectType.IDOL:
					return tr("room_idol")
				DataManager.ObjectType.TORTURE_RACK:
					return tr("room_torture_rack")
				DataManager.ObjectType.CAULDRON:
					return tr("room_cauldron")
				_:
					return tr("room_object")
		_:
			return tr("room_unknown")


func get_glow_color_for_card(card: CardData) -> Color:
	match card.origin:
		DataManager.CardOrigin.CHARACTER:
			match card.character_class:
				DataManager.CharacterClass.PENITENT:
					return COLOR_PENITENT_ART_BG_DARK
				DataManager.CharacterClass.WARRIOR:
					return COLOR_WARRIOR_ART_BG_LIGHT
				DataManager.CharacterClass.MYSTIC:
					return COLOR_MYSTIC_ART_BG_LIGHT
				DataManager.CharacterClass.ROGUE:
					return COLOR_ROGUE_ART_BG_LIGHT
				_:
					return COLOR_PENITENT_ART_BG_LIGHT
		
		DataManager.CardOrigin.BIOME:
			match card.biome:
				DataManager.Biome.MOLE_TUNNELS:
					return COLOR_MOLE_TUNNELS_ART_BG_DARK
				DataManager.Biome.FLESH_CAVES:
					return COLOR_FLESH_CAVES_ART_BG_LIGHT
				DataManager.Biome.BONE_LABYRINTH:
					return COLOR_BONE_LABYRINTH_ART_BG_LIGHT
				DataManager.Biome.ROTTEN_MARSHES:  # 🆕
					return COLOR_ROTTEN_MARSHES_ART_BG_DARK
				DataManager.Biome.FROZEN_DEPTHS:
					return COLOR_WARRIOR_ART_BG_LIGHT
				DataManager.Biome.MAGMA_CORE:
					return COLOR_FLESH_CAVES_ART_BG_DARK
				_:
					return COLOR_MOLE_TUNNELS_ART_BG_LIGHT2
		
		_:
			return COLOR_PENITENT_ART_BG_LIGHT


func get_biome_name(biome: Biome) -> String:
	match biome:
		Biome.MOLE_TUNNELS:
			return tr("biome_mole_tunnels_name")
		Biome.ROTTEN_MARSHES:
			return tr("biome_rotten_marshes_name")
		Biome.FLESH_CAVES:
			return tr("biome_flesh_caves_name")
		Biome.BONE_LABYRINTH:
			return tr("biome_bone_labyrinth_name")
		_:
			return "Unknown Biome"

func get_biome_description(biome: Biome) -> String:
	match biome:
		Biome.MOLE_TUNNELS:
			return tr("biome_mole_tunnels_desc")
		Biome.ROTTEN_MARSHES:
			return tr("biome_rotten_marshes_desc")
		_:
			return ""

func get_biome_preview(biome: Biome) -> Texture2D:
	match biome:
		Biome.MOLE_TUNNELS:
			return preload("res://img/ui/biome_previews/mole_tunnels_preview.png")
		Biome.ROTTEN_MARSHES:
			return preload("res://img/ui/biome_previews/rotten_marshes_preview.png")
		_:
			return null

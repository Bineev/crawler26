# data_manager.gd
extends Node

## ============================================================
## 1. ОСНОВНЫЕ ПЕРЕЧИСЛЕНИЯ (ENUMS)
## ============================================================

## Базовые статы (flats) — числовые характеристики
enum FlatStat {
	HEALTH,
	MAX_HEALTH,
	ENERGY,
	MAX_ENERGY,
	BLOCK,
	HAND_SIZE,
	DRAW_PER_TURN,
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

## Типы эффектов карт
enum EffectCategory {
	DAMAGE,          # прямой урон
	BLOCK,           # блок
	HEAL,            # лечение
	MODIFY_STAT,     # изменить флэт-стат
	MODIFY_MODIFIER, # изменить модификатор
	APPLY_STATUS,    # наложить статус
	APPLY_PASSIVE,   # наложить пассивку
	DRAW_CARD,       # добор карт
	GAIN_ENERGY,     # получить энергию
	SACRIFICE_CARD,  # сжечь карту
	CONVERT,         # конвертировать одно в другое
	CONDITIONAL,     # условный эффект
}

## Цель эффекта
enum EffectTarget {
	SELF,           # на себя
	ENEMY,          # на врага
	ALL_ENEMIES,    # на всех врагов
	ALL_ALLIES,     # на всех союзников
	ANY,            # выбор цели
}

## Типы зарядов пассивок
enum PassiveChargeType {
	PERMANENT,      # постоянная
	TURN_BASED,     # тикает по ходам
	USAGE_BASED,    # тратится при активации
	CONDITIONAL,    # особые условия
}

## Все возможные пассивки
enum Passive {
	# Кротовые норы
	REGROWTH,           # Оживление (растущая регенерация)
	VENOMOUS_SHIELD,    # Ядовитый щит
	WRATH,              # Злость (+1 силы/ход)
	FREEZING_GROUND,    # Обмерзание
	DENIAL,             # Отрицание
	
	# Сломленный
	SHAME,              # Стыд
	DESPAIR,            # Отчаяние
	
	# Пещеры плоти
	FLESH_WARD,
	CRIMSON_FRENZY,
}

## Все возможные статусы
enum Status {
	POISON,         # Яд
	BLEED,          # Кровотечение
	BURN,           # Горение
	ICE,            # Лёд
	WEAKNESS,       # Слабость
	VULNERABILITY,  # Уязвимость
	SHAME,          # Стыд (Сломленный)
	DESPAIR,        # Отчаяние (Сломленный)
}

## Классы персонажей
enum CharacterClass {
	PENITENT,       # Сломленный
	WARRIOR,        # Воитель
	MYSTIC,         # Мистик
	ROGUE,          # Плут
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
	BLOCK,
	SKILL,
	POWER,
}


## ============================================================
## 2. БАЛАНСНЫЕ КОНСТАНТЫ
## ============================================================

## === Основные лимиты ===
const MAX_HAND_SIZE: int = 10
const STARTING_HAND_SIZE: int = 5
const STARTING_ENERGY: int = 3
const MAX_ENERGY: int = 3

## === Сломленный (Penitent) ===
const PENITENT_STARTING_HEALTH: int = 80
const PENITENT_MAX_ATONEMENT: int = 30
const PENITENT_ATONEMENT_GAIN_PER_DAMAGE: int = 1

## === Статусы ===

# Poison (Яд)
const POISON_BASE_DAMAGE_PER_STACK: int = 1
const POISON_TICK_INTERVAL: int = 1

# Bleed (Кровотечение)
const BLEED_BASE_DAMAGE_PER_STACK: int = 5
const BLEED_TICK_INTERVAL: int = 2

# Burn (Горение)
const BURN_BASE_DAMAGE_PER_STACK: int = 1
const BURN_TICK_INTERVAL: int = 1
const BURN_THRESHOLD_STACKS: int = 10
const BURN_EXPLOSION_DAMAGE_PER_STACK: int = 3

# Ice (Лёд)
const ICE_EFFECT_PERCENT_PER_STACK: float = 0.01   # 1% за стак
const ICE_MAX_EFFECT_PERCENT: float = 0.25        # макс 25%
const ICE_MIN_EFFECT_MULTIPLIER: float = 0.75

# Weakness (Слабость)
const WEAKNESS_DAMAGE_MULTIPLIER: float = 0.75    # -25% урона

# Vulnerability (Уязвимость)
const VULNERABILITY_DAMAGE_MULTIPLIER: float = 1.5   # +50% урона

# Shame (Стыд) — для Сломленного
const SHAME_DURATION: int = 2
const SHAME_DAMAGE_TAKEN_MULTIPLIER: float = 1.25  # +25% входящего урона
const SHAME_ATONEMENT_MULTIPLIER: float = 2.0

# Despair (Отчаяние) — для Сломленного
const DESPAIR_DURATION: int = 2
const DESPAIR_DAMAGE_DEALT_MULTIPLIER: float = 0.75   # -25% исходящего урона

## === Пассивки ===

# Regrowth (Оживление)
const REGROWTH_STARTING_HEAL: int = 2
const REGROWTH_INCREMENT: int = 1

# Venomous Shield (Ядовитый щит)
const VENOMOUS_SHIELD_POISON_STACKS: int = 1
const VENOMOUS_SHIELD_POISON_DURATION: int = 2

# Wrath (Злость)
const WRATH_STRENGTH_GAIN_PER_TURN: int = 1

# Freezing Ground (Обмерзание)
const FREEZING_GROUND_ICE_STACKS: int = 5
const FREEZING_GROUND_RECHARGE_TURN: int = 6

# Denial (Отрицание)
const DENIAL_STARTING_CHARGES: int = 3

## === Карты Сломленного ===

# Удар расплаты (Atonement Strike)
const ATONEMENT_STRIKE_DAMAGE: int = 8

# Греховный выпад (Sinful Strike)
const SINFUL_STRIKE_DAMAGE: int = 10

# Покаянное откровение (Penitent Revelation)
const PENITENT_REVELATION_THRESHOLD_1: int = 10
const PENITENT_REVELATION_THRESHOLD_2: int = 20
const PENITENT_REVELATION_THRESHOLD_3: int = 30
const PENITENT_REVELATION_DRAW_1: int = 1
const PENITENT_REVELATION_DRAW_2: int = 2
const PENITENT_REVELATION_DRAW_3: int = 3

# Искупительный барьер (Redemptive Barrier)
const REDEMPTIVE_BARRIER_SELF_DAMAGE: int = 5
const REDEMPTIVE_BARRIER_BLOCK_TIER_1: int = 10
const REDEMPTIVE_BARRIER_BLOCK_TIER_2: int = 16
const REDEMPTIVE_BARRIER_BLOCK_TIER_3: int = 22
const REDEMPTIVE_BARRIER_THRESHOLD_1: int = 10
const REDEMPTIVE_BARRIER_THRESHOLD_2: int = 20
const REDEMPTIVE_BARRIER_THRESHOLD_3: int = 30

# Кровавая жертва (Blood Sacrifice)
const BLOOD_SACRIFICE_SELF_DAMAGE: int = 5
const BLOOD_SACRIFICE_ATONEMENT_GAIN: int = 30
const BLOOD_SACRIFICE_MAX_ATONEMENT: int = 30

# Цена отчаяния (Price of Despair)
const PRICE_OF_DESPAIR_HEAL_TIER_1: int = 6
const PRICE_OF_DESPAIR_HEAL_TIER_2: int = 11
const PRICE_OF_DESPAIR_HEAL_TIER_3: int = 15

# Очищающее пламя (Scouring Flame)
const SCOURING_FLAME_SELF_DAMAGE_PER_STATUS: int = 3
const SCOURING_FLAME_ATONEMENT_PER_STATUS: int = 5

# Грех тщеславия (Sin of Vanity)
const SIN_OF_VANITY_BASE_DAMAGE: int = 4
const SIN_OF_VANITY_BONUS_PER_STATUS: int = 2

# Жажда кары (Thirst for Punishment)
const THIRST_FOR_PUNISHMENT_SELF_DAMAGE: int = 5
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_1: int = 1
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_2: int = 2
const THIRST_FOR_PUNISHMENT_ENERGY_TIER_3: int = 3

# Щит покаяния (Shield of Penance)
const SHIELD_OF_PENANCE_BASE_BLOCK: int = 5
const SHIELD_OF_PENANCE_BONUS_BLOCK: int = 5
const SHIELD_OF_PENANCE_STATUS_THRESHOLD: int = 2

# Удар пустоты (Void Strike)
const VOID_STRIKE_BASE_DAMAGE: int = 6
const VOID_STRIKE_BONUS_DAMAGE_IF_ZERO_ATONEMENT: int = 4

# Крик отчаяния (Cry of Despair)
const CRY_OF_DESPAIR_DAMAGE: int = 5
const CRY_OF_DESPAIR_HEAL_TIER_1: int = 5
const CRY_OF_DESPAIR_HEAL_TIER_2: int = 10
const CRY_OF_DESPAIR_HEAL_TIER_3: int = 15


## ============================================================
## 3. ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

## Проверка, является ли статус негативным
func is_negative_status(status: Status) -> bool:
	return status in [
		Status.POISON,
		Status.BLEED,
		Status.BURN,
		Status.ICE,
		Status.WEAKNESS,
		Status.VULNERABILITY,
		Status.DESPAIR,
	]

## Получить название статуса (для дебага)
func get_status_name(status: Status) -> String:
	match status:
		Status.POISON: return "Poison"
		Status.BLEED: return "Bleed"
		Status.BURN: return "Burn"
		Status.ICE: return "Ice"
		Status.WEAKNESS: return "Weakness"
		Status.VULNERABILITY: return "Vulnerability"
		Status.SHAME: return "Shame"
		Status.DESPAIR: return "Despair"
		_: return "Unknown"

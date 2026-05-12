# resources/statuses/status_resource.gd
extends Resource
class_name StatusResource

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID статуса (из DataManager.Status)
@export var id: DataManager.Status

## Ключи локализации
@export var name_key: String = ""
@export var description_key: String = ""

## Иконка статуса (64×64)
@export var icon: Texture2D


## ============================================================
## ТИК И УРОН
## ============================================================

## Является ли статус тикающим (наносит урон периодически)
@export var is_ticking: bool = false

## Интервал между тиками в ходах
@export var tick_interval: int = 1

## Игнорирует ли блок при нанесении урона
@export var ignore_block: bool = false

## Наносит ли урон владельцу статуса (для Горения)
@export var damage_owner: bool = false


## ============================================================
## СТАКИ
## ============================================================

## Имеет ли статус стаки
@export var is_stacking: bool = false

## Максимальное количество стаков (0 = безлимит)
@export var max_stacks: int = 0


## ============================================================
## ПОРОГОВЫЕ ЭФФЕКТЫ
## ============================================================

## Количество стаков для срабатывания порога (0 = нет порога)
@export var threshold_stacks: int = 0

## Эффект, который срабатывает при достижении порога
@export var threshold_effect: EffectEntry = null


## ============================================================
## МОДИФИКАТОРЫ
## ============================================================

## Модификаторы, которые накладывает статус
@export var modifiers: Array[ModifierEntry] = []


## ============================================================
## МЕТОДЫ (используют константы из DataManager)
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return DataManager.Status.keys()[id]
	return tr(name_key)

## Возвращает локализованное описание
func get_localized_description() -> String:
	if description_key.is_empty():
		return _generate_default_description()
	var desc = tr(description_key)
	
	# Подставляем значения из констант DataManager
	if is_ticking:
		match id:
			DataManager.Status.BLEED:
				desc = desc.format({"damage": DataManager.BLEED_BASE_DAMAGE_PER_STACK})
			DataManager.Status.POISON:
				desc = desc.format({"damage": DataManager.POISON_BASE_DAMAGE_PER_STACK})
			DataManager.Status.BURN:
				desc = desc.format({"damage": DataManager.BURN_BASE_DAMAGE_PER_STACK})
	
	if threshold_stacks > 0:
		desc += " " + tr("status_burn_threshold").format({"threshold": DataManager.BURN_THRESHOLD_STACKS})
	
	return desc

## Генерирует описание по умолчанию (используя константы DataManager)
func _generate_default_description() -> String:
	match id:
		DataManager.Status.POISON:
			return "Наносит %d урона в конце хода. Игнорирует броню." % DataManager.POISON_BASE_DAMAGE_PER_STACK
		DataManager.Status.BLEED:
			return "Наносит %d урона за каждый стак раз в 2 хода." % DataManager.BLEED_BASE_DAMAGE_PER_STACK
		DataManager.Status.BURN:
			var desc = "Наносит %d урона владельцу в конце хода." % DataManager.BURN_BASE_DAMAGE_PER_STACK
			if DataManager.BURN_THRESHOLD_STACKS > 0:
				desc += " При %d стаках взрывается." % DataManager.BURN_THRESHOLD_STACKS
			return desc
		DataManager.Status.ICE:
			return "Снижает исходящий урон на %.0f%% за стак (макс 25%%)." % (DataManager.ICE_EFFECT_PERCENT_PER_STACK * 100)
		DataManager.Status.WEAKNESS:
			return "Атаки наносят на %.0f%% меньше урона." % ((1.0 - DataManager.WEAKNESS_DAMAGE_MULTIPLIER) * 100)
		DataManager.Status.VULNERABILITY:
			return "Получает на %.0f%% больше урона от всех источников." % ((DataManager.VULNERABILITY_DAMAGE_MULTIPLIER - 1.0) * 100)
		DataManager.Status.SHAME:
			return "Получает +%.0f%% входящего урона. Удваивает получаемое Искупление." % ((DataManager.SHAME_DAMAGE_TAKEN_MULTIPLIER - 1.0) * 100)
		DataManager.Status.DESPAIR:
			return "Наносит на %.0f%% меньше урона." % ((1.0 - DataManager.DESPAIR_DAMAGE_DEALT_MULTIPLIER) * 100)
		_:
			return ""

## Проверяет, является ли статус негативным
func is_negative() -> bool:
	return id in [
		DataManager.Status.POISON,
		DataManager.Status.BLEED,
		DataManager.Status.BURN,
		DataManager.Status.ICE,
		DataManager.Status.WEAKNESS,
		DataManager.Status.VULNERABILITY,
		DataManager.Status.DESPAIR,
	]

## Получает урон за тик (с учётом стаков, используя константы)
func get_tick_damage(stacks: int) -> int:
	if not is_ticking:
		return 0
	
	match id:
		DataManager.Status.BLEED:
			return stacks * DataManager.BLEED_BASE_DAMAGE_PER_STACK
		DataManager.Status.POISON:
			return stacks * DataManager.POISON_BASE_DAMAGE_PER_STACK
		DataManager.Status.BURN:
			return stacks * DataManager.BURN_BASE_DAMAGE_PER_STACK
		_:
			return 0

## Получает текущий множитель эффекта (для Ice)
func get_effect_multiplier(stacks: int) -> float:
	match id:
		DataManager.Status.ICE:
			var total = 1.0 - (stacks * DataManager.ICE_EFFECT_PERCENT_PER_STACK)
			return max(total, DataManager.ICE_MIN_EFFECT_MULTIPLIER)
		_:
			return 1.0

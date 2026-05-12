# resources/effects/effect_entry.gd
extends Resource
class_name EffectEntry

## ============================================================
## ОСНОВНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип эффекта (из DataManager.EffectCategory)
@export var category: DataManager.EffectCategory

## Цель эффекта (из DataManager.EffectTarget)
@export var target: DataManager.EffectTarget = DataManager.EffectTarget.ENEMY

## Ключ локализации для названия (опционально)
@export var name_key: String = ""


## ============================================================
## ДЛЯ DAMAGE / BLOCK / HEAL
## ============================================================

## Базовое значение (урон, блок, лечение)
@export var base_value: int = 0

## Стат-множитель (например, урон зависит от Atonement)
@export var stat_multiplier: DataManager.FlatStat = DataManager.FlatStat.ENERGY
@export var stat_divisor: int = 10


## ============================================================
## ДЛЯ MODIFY_STAT (изменение флэт-статов)
## ============================================================

## Какой стат меняем
@export var target_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH

## На сколько изменить
@export var delta: int = 0


## ============================================================
## ДЛЯ MODIFY_MODIFIER (изменение процентных модификаторов)
## ============================================================

## Какой модификатор меняем
@export var target_modifier: DataManager.ModifierStat = DataManager.ModifierStat.DAMAGE_DEALT_PERCENT

## На сколько изменить в процентах (0.25 = +25%)
@export var delta_percent: float = 0.0

## Длительность в ходах (0 = постоянно)
@export var duration: int = 0


## ============================================================
## ДЛЯ APPLY_STATUS
## ============================================================

## Какой статус накладываем
@export var status: DataManager.Status = DataManager.Status.POISON

## Количество стаков
@export var stacks: int = 1

## Длительность в ходах (0 = пока не кончится)
@export var status_duration: int = 0


## ============================================================
## ДЛЯ APPLY_PASSIVE
## ============================================================

## Какую пассивку накладываем
@export var passive: DataManager.Passive = DataManager.Passive.SHAME

## Длительность в ходах (для временных пассивок)
@export var passive_duration: int = 0


## ============================================================
## ДЛЯ DRAW_CARD / GAIN_ENERGY
## ============================================================

## Количество карт / энергии
@export var amount: int = 0


## ============================================================
## ДЛЯ CONVERT
## ============================================================

## Из какого стата конвертируем
@export var from_stat: DataManager.FlatStat = DataManager.FlatStat.BLOCK

## В какой стат конвертируем
@export var to_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH


## ============================================================
## ДЛЯ CONDITIONAL
## ============================================================

## Скрипт условия (должен возвращать bool)
@export var condition_script: Script = null

## Эффект, если условие истинно
@export var true_effect: EffectEntry = null

## Эффект, если условие ложно
@export var false_effect: EffectEntry = null


## ============================================================
## МЕТОДЫ
## ============================================================

## Получить локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return DataManager.EffectCategory.keys()[category]
	return tr(name_key)

## Получить базовое значение с учётом множителя стата
func get_scaled_value(stat_value: int) -> int:
	if stat_multiplier == DataManager.FlatStat.ENERGY:
		# если нет связи, просто base_value
		return base_value
	return base_value + (stat_value / stat_divisor)

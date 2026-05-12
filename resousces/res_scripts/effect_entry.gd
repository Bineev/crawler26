# resources/effects/effect_entry.gd
extends Resource
class_name EffectEntry

## ============================================================
## ОСНОВНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип эффекта (DAMAGE, BLOCK, HEAL, APPLY_STATUS, APPLY_PASSIVE, ...)
@export var category: DataManager.EffectCategory

## Цель эффекта (SELF, ENEMY, ALL_ENEMIES, ALL_ALLIES, ANY)
@export var target: DataManager.EffectTarget = DataManager.EffectTarget.ENEMY


## ============================================================
## ДЛЯ DAMAGE / BLOCK / HEAL
## ============================================================

## Базовое значение (урон, блок, лечение)
@export var base_value: int = 0

## Стат-множитель (например, урон зависит от Atonement)
@export var stat_multiplier: DataManager.FlatStat = DataManager.FlatStat.ENERGY

## Делитель для стат-множителя
@export var stat_divisor: int = 10


## ============================================================
## ДЛЯ APPLY_STATUS
## ============================================================

## Ссылка на ресурс статуса
@export var status: StatusResource = null

## Значение (стаки для стакающихся статусов, или величина эффекта)
@export var value: int = 1

## Длительность в ходах (0 = бесконечно)
@export var duration: int = 0


## ============================================================
## ДЛЯ APPLY_PASSIVE
## ============================================================

## Ссылка на ресурс пассивки
@export var passive: PassiveResource = null

## Длительность пассивки в ходах
@export var passive_duration: int = 0


## ============================================================
## ДЛЯ MODIFY_STAT
## ============================================================

## Какой стат меняем (HEALTH, ENERGY, BLOCK, ...)
@export var target_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH

## На сколько изменить
@export var delta: int = 0


## ============================================================
## ДЛЯ MODIFY_MODIFIER
## ============================================================

## Какой модификатор меняем (DAMAGE_DEALT_PERCENT, DAMAGE_TAKEN_PERCENT, ...)
@export var target_modifier: DataManager.ModifierStat = DataManager.ModifierStat.DAMAGE_DEALT_PERCENT

## На сколько изменить в процентах (0.25 = +25%)
@export var delta_percent: float = 0.0

## Длительность модификатора в ходах
@export var modifier_duration: int = 0


## ============================================================
## ДЛЯ DRAW_CARD / GAIN_ENERGY
## ============================================================

## Количество карт или энергии
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
## РОСТ ЗНАЧЕНИЙ (для повторяющихся эффектов, например, в пассивках)
## ============================================================

## Тип роста (NONE, ADD, SUBTRACT, MULTIPLY, DIVIDE)
@export var grow_type: DataManager.GrowType = DataManager.GrowType.NONE

## Значение роста (+1, -1, ×2, /2)
@export var grow_value: int = 1

## Что именно растёт (VALUE, DURATION, BASE_VALUE, BOTH)
@export var grow_target: DataManager.GrowTarget = DataManager.GrowTarget.VALUE


## ============================================================
## СОСТОЯНИЕ (для копий ресурса)
## ============================================================

## Текущее значение (используется при росте вместо оригинального)
var current_value: int = 0

## Текущая длительность (используется при росте)
var current_duration: int = 0

## Флаг, что используются текущие значения (а не базовые)
var uses_custom_values: bool = false

## Счётчик применений (для роста)
var application_counter: int = 0


## ============================================================
## МЕТОДЫ
## ============================================================

## Создаёт копию эффекта для использования на конкретной цели
func duplicate_for_instance() -> EffectEntry:
	var copy = EffectEntry.new()
	
	# Копируем основные поля
	copy.category = category
	copy.target = target
	copy.base_value = base_value
	copy.stat_multiplier = stat_multiplier
	copy.stat_divisor = stat_divisor
	copy.status = status
	copy.value = value
	copy.duration = duration
	copy.passive = passive
	copy.passive_duration = passive_duration
	copy.target_stat = target_stat
	copy.delta = delta
	copy.target_modifier = target_modifier
	copy.delta_percent = delta_percent
	copy.modifier_duration = modifier_duration
	copy.amount = amount
	copy.from_stat = from_stat
	copy.to_stat = to_stat
	copy.condition_script = condition_script
	copy.grow_type = grow_type
	copy.grow_value = grow_value
	copy.grow_target = grow_target
	
	# Копируем состояние
	copy.current_value = current_value if uses_custom_values else value
	copy.current_duration = current_duration if uses_custom_values else duration
	copy.uses_custom_values = uses_custom_values
	copy.application_counter = application_counter
	
	# Копируем вложенные эффекты (рекурсивно)
	if true_effect:
		copy.true_effect = true_effect.duplicate_for_instance()
	if false_effect:
		copy.false_effect = false_effect.duplicate_for_instance()
	
	return copy


## Применяет рост значения перед использованием
func apply_growth():
	if grow_type == DataManager.GrowType.NONE:
		return
	
	uses_custom_values = true
	application_counter += 1
	
	match grow_target:
		DataManager.GrowTarget.VALUE:
			current_value = _apply_growth_to_value(current_value if uses_custom_values else value)
		DataManager.GrowTarget.DURATION:
			current_duration = _apply_growth_to_value(current_duration if uses_custom_values else duration)
		DataManager.GrowTarget.BASE_VALUE:
			base_value = _apply_growth_to_value(base_value)
		DataManager.GrowTarget.BOTH:
			current_value = _apply_growth_to_value(current_value if uses_custom_values else value)
			current_duration = _apply_growth_to_value(current_duration if uses_custom_values else duration)


## Возвращает текущее значение (с учётом роста)
func get_current_value() -> int:
	return current_value if uses_custom_values else value


## Возвращает текущую длительность (с учётом роста)
func get_current_duration() -> int:
	return current_duration if uses_custom_values else duration


## Применяет математическую операцию роста
func _apply_growth_to_value(val: int) -> int:
	match grow_type:
		DataManager.GrowType.ADD:
			return val + grow_value
		DataManager.GrowType.SUBTRACT:
			return max(0, val - grow_value)
		DataManager.GrowType.MULTIPLY:
			return val * grow_value
		DataManager.GrowType.DIVIDE:
			return max(1, val / grow_value)
		_:
			return val


## Проверяет, есть ли рост у эффекта
func has_growth() -> bool:
	return grow_type != DataManager.GrowType.NONE


## Сбрасывает состояние к базовым значениям (для переиспользования копии)
func clear_instance_state():
	uses_custom_values = false
	current_value = value
	current_duration = duration
	application_counter = 0


## Получает локализованное описание (для UI)
func get_localized_description() -> String:
	match category:
		DataManager.EffectCategory.DAMAGE:
			return tr("effect_damage").format({"value": get_current_value()})
		DataManager.EffectCategory.BLOCK:
			return tr("effect_block").format({"value": get_current_value()})
		DataManager.EffectCategory.HEAL:
			return tr("effect_heal").format({"value": get_current_value()})
		DataManager.EffectCategory.APPLY_STATUS:
			if status:
				return tr("effect_apply_status").format({"status": status.get_localized_name(), "value": get_current_value(), "duration": get_current_duration()})
			return ""
		DataManager.EffectCategory.APPLY_PASSIVE:
			if passive:
				return tr("effect_apply_passive").format({"passive": passive.get_localized_name(), "duration": passive_duration})
			return ""
		DataManager.EffectCategory.MODIFY_STAT:
			return tr("effect_modify_stat").format({"stat": DataManager.FlatStat.keys()[target_stat], "delta": delta})
		DataManager.EffectCategory.DRAW_CARD:
			return tr("effect_draw_card").format({"amount": amount})
		DataManager.EffectCategory.GAIN_ENERGY:
			return tr("effect_gain_energy").format({"amount": amount})
		_:
			return ""

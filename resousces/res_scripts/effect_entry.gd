# resources/effects/effect_entry.gd
extends Resource
class_name EffectEntry

## ============================================================
## ОСНОВНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип эффекта
@export var category: DataManager.EffectCategory

## Цель эффекта
@export var target: DataManager.EffectTarget = DataManager.EffectTarget.ENEMY


## ============================================================
## ДЛЯ DAMAGE / BLOCK / HEAL
## ============================================================

@export var base_value: int = 0
@export var stat_multiplier: DataManager.FlatStat = DataManager.FlatStat.ENERGY
@export var stat_divisor: int = 10


## ============================================================
## ДЛЯ SCALED_VALUE (значение зависит от tier ресурса)
## ============================================================

## Значения для каждого tier (индекс = tier)
@export var scaled_values: Array[int] = [0, 0, 0, 0]

## Тип значения (DAMAGE, BLOCK, HEAL, GAIN_ENERGY, DRAW_CARD)
@export var scaled_type: DataManager.ScaledType = DataManager.ScaledType.BLOCK


## ============================================================
## ДЛЯ APPLY_STATUS
## ============================================================

@export var status: StatusResource = null
@export var value: int = 1          # стаки или величина эффекта
@export var duration: int = 0


## ============================================================
## ДЛЯ APPLY_PASSIVE
## ============================================================

@export var passive: PassiveResource = null
@export var passive_duration: int = 0


## ============================================================
## ДЛЯ MODIFY_STAT (изменение FlatStat)
## ============================================================

@export var target_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH
@export var delta: int = 0


## ============================================================
## ДЛЯ MODIFY_MODIFIER (временное изменение ModifierStat)
## ============================================================

@export var target_modifier: DataManager.ModifierStat = DataManager.ModifierStat.DAMAGE_DEALT_PERCENT
@export var delta_percent: float = 0.0
@export var modifier_duration: int = 0


## ============================================================
## ДЛЯ DRAW_CARD / GAIN_ENERGY
## ============================================================

@export var amount: int = 0


## ============================================================
## ДЛЯ CONVERT
## ============================================================

@export var from_stat: DataManager.FlatStat = DataManager.FlatStat.BLOCK
@export var to_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH
@export var conversion_ratio: float = 1.0   # коэффициент (1.0 = 1:1)

## ============================================================
## ДЛЯ CONVERT_EXCESS_TO_BLOCK
## ============================================================

## Специализированный эффект для Кровавой жертвы
## Автоматически конвертирует излишек ATONEMENT в BLOCK


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
## ДЛЯ CUSTOM (сложная логика)
## ============================================================

## Скрипт с кастомной логикой (должен иметь метод apply)
@export var custom_script: Script = null


## ============================================================
## ДЛЯ РОСТА ЗНАЧЕНИЙ (для пассивок)
## ============================================================

@export var grow_type: DataManager.GrowType = DataManager.GrowType.NONE
@export var grow_value: int = 1
@export var grow_target: DataManager.GrowTarget = DataManager.GrowTarget.VALUE


## ============================================================
## СОСТОЯНИЕ (для копий ресурса)
## ============================================================

var current_value: int = 0
var current_duration: int = 0
var uses_custom_values: bool = false
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
	copy.scaled_values = scaled_values.duplicate()
	copy.scaled_type = scaled_type
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
	copy.custom_script = custom_script
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


## Возвращает значение для SCALED_TYPE (на основе tier)
func get_scaled_value(tier: int) -> int:
	if scaled_values.is_empty():
		return 0
	var index = clamp(tier, 0, scaled_values.size() - 1)
	return scaled_values[index]


## Применяет рост значения
func apply_growth():
	if grow_type == DataManager.GrowType.NONE:
		return
	
	uses_custom_values = true
	application_counter += 1
	
	match grow_target:
		DataManager.GrowTarget.VALUE:
			current_value = _apply(current_value if uses_custom_values else value)
		DataManager.GrowTarget.DURATION:
			current_duration = _apply(current_duration if uses_custom_values else duration)
		DataManager.GrowTarget.BASE_VALUE:
			base_value = _apply(base_value)
		DataManager.GrowTarget.BOTH:
			current_value = _apply(current_value if uses_custom_values else value)
			current_duration = _apply(current_duration if uses_custom_values else duration)


func _apply(val: int) -> int:
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


func get_current_value() -> int:
	return current_value if uses_custom_values else value


func get_current_duration() -> int:
	return current_duration if uses_custom_values else duration


func has_growth() -> bool:
	return grow_type != DataManager.GrowType.NONE


func clear_instance_state():
	uses_custom_values = false
	current_value = value
	current_duration = duration
	application_counter = 0

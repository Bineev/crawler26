# resources/effects/effect_entry.gd
extends Resource
class_name EffectEntry

## ============================================================
## ОСНОВНЫЕ ПАРАМЕТРЫ
## ============================================================


## Является ли урон прямым (от карты) или косвенным (от статусов, пассивок и т.д.)
@export var is_direct_damage: bool = true
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
## ДЛЯ SCALED_VALUE
## ============================================================

@export var scaled_values: Array[int] = [0, 0, 0, 0]
@export var scaled_thresholds: Array[int] = [0, 0, 0, 0]  # границы
@export var scaled_type: DataManager.ScaledType = DataManager.ScaledType.BLOCK
@export var scaled_resource: DataManager.ScaledResource = DataManager.ScaledResource.ATONEMENT
@export var scaled_compare: DataManager.ScaledCompare = DataManager.ScaledCompare.GREATER_EQUAL
@export var scaled_spend_resource: bool = false  # ← новое поле
## ============================================================
## ДЛЯ APPLY_STATUS
## ============================================================

@export var status: StatusResource = null
@export var value: int = 1
@export var duration: int = 0


## ============================================================
## ДЛЯ APPLY_PASSIVE
## ============================================================

@export var passive: PassiveResource = null
@export var passive_duration: int = 0


## ============================================================
## ДЛЯ MODIFY_STAT
## ============================================================

@export var target_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH
@export var delta: int = 0


## ============================================================
## ДЛЯ MODIFY_MODIFIER
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

@export var from_stat: DataManager.FlatStat = DataManager.FlatStat.ATONEMENT
@export var to_stat: DataManager.FlatStat = DataManager.FlatStat.HEALTH
@export var conversion_ratio: float = 1.0

## ДЛЯ CONVERT_STATUS
@export var convert_from_status: DataManager.Status = DataManager.Status.POISON
@export var convert_to_stat: DataManager.FlatStat = DataManager.FlatStat.ATONEMENT
@export var convert_conversion_ratio: float = 1.0

## ============================================================
## ДЛЯ CONDITIONAL
## ============================================================

@export var condition_script: Script = null
@export var true_effect: EffectEntry = null
@export var false_effect: EffectEntry = null


## ============================================================
## ДЛЯ CUSTOM
## ============================================================

@export var custom_script: Script = null


## ============================================================
## ДЛЯ РОСТА ЗНАЧЕНИЙ
## ============================================================

@export var grow_type: DataManager.GrowType = DataManager.GrowType.NONE
@export var grow_value: int = 1
@export var grow_target: DataManager.GrowTarget = DataManager.GrowTarget.VALUE


## ============================================================
## СОСТОЯНИЕ
## ============================================================

var current_value: int = 0
var current_duration: int = 0
var uses_custom_values: bool = false
var application_counter: int = 0


## ============================================================
## МЕТОДЫ
## ============================================================

func duplicate_for_instance() -> EffectEntry:
	var copy = EffectEntry.new()
	
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
	copy.conversion_ratio = conversion_ratio
	copy.condition_script = condition_script
	copy.custom_script = custom_script
	copy.grow_type = grow_type
	copy.grow_value = grow_value
	copy.grow_target = grow_target
	
	copy.current_value = current_value if uses_custom_values else value
	copy.current_duration = current_duration if uses_custom_values else duration
	copy.uses_custom_values = uses_custom_values
	copy.application_counter = application_counter
	
	if true_effect:
		copy.true_effect = true_effect.duplicate_for_instance()
	if false_effect:
		copy.false_effect = false_effect.duplicate_for_instance()
	
	return copy


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


## Проверка, является ли эффект условным
func is_conditional() -> bool:
	return category == DataManager.EffectCategory.CONDITIONAL


## Проверка, является ли эффект кастомным
func is_custom() -> bool:
	return category == DataManager.EffectCategory.CUSTOM


## Проверка, является ли эффект масштабируемым (scaled_value)
func is_scaled() -> bool:
	return category == DataManager.EffectCategory.SCALED_VALUE


func get_scaled_value(resource_value: int) -> int:
	if scaled_values.is_empty():
		return 0
	
	var tier = 0
	for i in range(scaled_thresholds.size()):
		var threshold = scaled_thresholds[i]
		match scaled_compare:
			DataManager.ScaledCompare.GREATER_EQUAL:
				if resource_value >= threshold:
					tier = i
			DataManager.ScaledCompare.LESSER_EQUAL:
				if resource_value <= threshold:
					tier = i
			DataManager.ScaledCompare.GREATER:
				if resource_value > threshold:
					tier = i
			DataManager.ScaledCompare.LESSER:
				if resource_value < threshold:
					tier = i
			DataManager.ScaledCompare.EQUAL:
				if resource_value == threshold:
					tier = i
	
	return scaled_values[tier] if tier < scaled_values.size() else scaled_values[0]

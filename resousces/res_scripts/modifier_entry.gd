# resources/effects/modifier_entry.gd
extends Resource
class_name ModifierEntry

## ============================================================
## МОДИФИКАТОР СТАТА
## ============================================================

## Какой модификатор меняем (из DataManager.ModifierStat)
@export var stat: DataManager.ModifierStat

## Множитель (1.25 = +25%, 0.75 = -25%)
@export var multiplier: float = 1.0

## Флэт-бонус (например, +2 к урону для Силы)
@export var flat_bonus: int = 0


## ============================================================
## МЕТОДЫ
## ============================================================

## Применить модификатор к текущему значению
func apply_to_value(current_value: float) -> float:
	var result = current_value
	if flat_bonus != 0:
		result += flat_bonus
	if multiplier != 1.0:
		result *= multiplier
	return result

## Получить итоговое значение модификатора (для отображения в UI)
func get_total_modifier() -> float:
	var total = 1.0
	if multiplier != 1.0:
		total = multiplier
	if flat_bonus != 0:
		total += flat_bonus
	return total

## Получить строковое представление (для UI)
func get_modifier_string() -> String:
	var parts = []
	if multiplier != 1.0:
		var percent = (multiplier - 1.0) * 100
		if percent > 0:
			parts.append("+%.0f%%" % percent)
		else:
			parts.append("%.0f%%" % percent)
	if flat_bonus != 0:
		if flat_bonus > 0:
			parts.append("+%d" % flat_bonus)
		else:
			parts.append("%d" % flat_bonus)
	return " ".join(parts)

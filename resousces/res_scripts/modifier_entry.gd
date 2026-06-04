# resources/effects/modifier_entry.gd
extends Resource
class_name ModifierEntry

## Какой модификатор меняем (DataManager.ModifierStat или DataManager.FlatStat)
@export var stat: int

## Тип изменения
@export var change_type: DataManager.ModifierChangeType = DataManager.ModifierChangeType.MULTIPLIER

## Значение (1.25 = +25%, 5 = +5)
@export var value: float = 1.0

## Длительность в ходах (0 = постоянно)
@export var duration: int = 0


func apply_to_flat(current: int) -> int:
	if change_type == DataManager.ModifierChangeType.FLAT_BONUS:
		return current + int(value)
	return current


func apply_to_modifier(current: float) -> float:
	match change_type:
		DataManager.ModifierChangeType.MULTIPLIER:
			return current * value
		DataManager.ModifierChangeType.PERCENT:
			return current + value
		_:
			return current


func get_modifier_string() -> String:
	match change_type:
		DataManager.ModifierChangeType.MULTIPLIER:
			var percent = (value - 1.0) * 100
			return "+%.0f%%" % percent if percent > 0 else "%.0f%%" % percent
		DataManager.ModifierChangeType.PERCENT:
			return "+%.0f%%" % value if value > 0 else "%.0f%%" % value
		DataManager.ModifierChangeType.FLAT_BONUS:
			return "+%d" % int(value) if value > 0 else "%d" % int(value)
	return ""


## Проверка, является ли модификатор постоянным
func is_permanent() -> bool:
	return duration == 0


## Создаёт копию модификатора
func duplicate_for_instance() -> ModifierEntry:
	var copy = ModifierEntry.new()
	copy.stat = stat
	copy.change_type = change_type
	copy.value = value
	copy.duration = duration
	return copy

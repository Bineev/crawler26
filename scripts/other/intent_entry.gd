# scripts/enemies/intent_entry.gd
class_name IntentEntry

## Тип намерения (DataManager.IntentType)
var intent_type: DataManager.IntentType

## Эффекты намерения (массив EffectEntry)
var effects: Array = []

## Ключ локализации для описания (опционально)
var description_key: String = ""


## Возвращает локализованное описание
func get_localized_description() -> String:
	if not description_key.is_empty():
		return tr(description_key)
	return _generate_default_description()


## Генерирует описание по умолчанию на основе типа намерения
func _generate_default_description() -> String:
	match intent_type:
		DataManager.IntentType.ATTACK:
			return "Наносит урон"
		DataManager.IntentType.DEFEND:
			return "Защищается"
		DataManager.IntentType.BUFF:
			return "Усиливается"
		DataManager.IntentType.DEBUFF:
			return "Ослабляет игрока"
		DataManager.IntentType.HEAL:
			return "Лечится"
		DataManager.IntentType.SUMMON:
			return "Призывает союзников"
		DataManager.IntentType.UNKNOWN:
			return "??? (неизвестно)"
		_:
			return "Действует"

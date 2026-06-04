# resources/enemies/intent_entry.gd
extends Resource
class_name IntentEntry

## ============================================================
## НАМЕРЕНИЕ ВРАГА
## ============================================================

## Тип намерения (ATTACK, DEFEND, BUFF, DEBUFF, APPLY_STATUS, APPLY_PASSIVE, UNKNOWN, SUMMON)
@export var intent_type: DataManager.IntentType = DataManager.IntentType.ATTACK

## Ключ локализации для описания (опционально, если нужен уникальный текст)
@export var description_key: String = ""

## Эффекты, которые выполняются при действии
@export var effects: Array[EffectEntry] = []


## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное описание
func get_localized_description() -> String:
	if not description_key.is_empty():
		return tr(description_key)
	return _generate_default_description()

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
		DataManager.IntentType.UNKNOWN:
			return "??? (неизвестно)"
		DataManager.IntentType.SUMMON:
			return "Призывает союзников"
		_:
			return "Действует"

## Получить иконку через DataManager (вместо прямого поля)
func get_icon() -> Texture2D:
	return DataManager.get_intent_icon(intent_type)

## Создаёт копию намерения для экземпляра врага
func duplicate_for_instance() -> IntentEntry:
	var copy = IntentEntry.new()
	copy.intent_type = intent_type
	copy.description_key = description_key
	
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	
	return copy

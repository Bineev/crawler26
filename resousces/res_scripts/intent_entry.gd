# resources/enemies/intent_entry.gd
extends Resource
class_name IntentEntry

## ============================================================
## НАМЕРЕНИЕ ВРАГА
## ============================================================

## Тип намерения (ATTACK, DEFEND, BUFF, DEBUFF, APPLY_STATUS, APPLY_PASSIVE)
@export var intent_type: DataManager.IntentType = DataManager.IntentType.ATTACK

## Иконка намерения (для UI)
@export var icon: Texture2D

## Ключ локализации для описания
@export var description_key: String = ""

## Эффекты, которые выполняются при действии
@export var effects: Array[EffectEntry] = []


## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное описание
func get_localized_description() -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key)

func _generate_default_description() -> String:
	match intent_type:
		DataManager.IntentType.ATTACK:
			return "Наносит урон"
		DataManager.IntentType.DEFEND:
			return "Защищается"
		DataManager.IntentType.BUFF:
			return "Усиливается"
		DataManager.IntentType.DEBUFF:
			return "Ослабляет"
		DataManager.IntentType.APPLY_STATUS:
			return "Накладывает статус"
		DataManager.IntentType.APPLY_PASSIVE:
			return "Накладывает пассивку"
		_:
			return ""

## Создаёт копию намерения для экземпляра врага
func duplicate_for_instance() -> IntentEntry:
	var copy = IntentEntry.new()
	copy.intent_type = intent_type
	copy.icon = icon
	copy.description_key = description_key
	
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	
	return copy

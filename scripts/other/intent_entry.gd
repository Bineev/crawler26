# resources/effects/intent_entry.gd
extends Resource
class_name IntentEntry

var effects = []
var intent_types: Array[DataManager.IntentType] = []


func get_localized_description() -> String:
	if intent_types.is_empty():
		return "???"
	
	var descriptions: Array[String] = []
	for intent_type in intent_types:
		descriptions.append(_get_description_for_type(intent_type))
	
	return ", ".join(descriptions)


func _get_description_for_type(intent_type: DataManager.IntentType) -> String:
	match intent_type:
		DataManager.IntentType.ATTACK:
			return "Атака"
		DataManager.IntentType.DEFEND:
			return "Защита"
		DataManager.IntentType.BUFF:
			return "Усиление"
		DataManager.IntentType.DEBUFF:
			return "Ослабление"
		DataManager.IntentType.HEAL:
			return "Лечение"
		DataManager.IntentType.SUMMON:
			return "Призыв"
		DataManager.IntentType.UNKNOWN:
			return "???"
		_:
			return "Действие"


func get_icon() -> Texture2D:
	if intent_types.is_empty():
		return DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
	
	# Показываем иконку первого типа, если их несколько
	return DataManager.get_intent_icon(intent_types[0])


func get_intent_types() -> Array[DataManager.IntentType]:
	return intent_types

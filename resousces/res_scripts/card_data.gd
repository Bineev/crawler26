# resources/cards/card_data.gd
extends Resource
class_name CardData

@export var id: String = ""
@export var name_key: String = ""
@export var description_key: String = ""
@export var texture: Texture2D
@export var grade: DataManager.CardGrade = DataManager.CardGrade.COMMON
@export var card_type: DataManager.CardType = DataManager.CardType.ATTACK
@export var cost: int = 1
@export var effects: Array[EffectEntry] = []
@export var card_modifiers: Array[ModifierEntry] = []
@export var overlay_type: String = ""

func get_localized_name() -> String:
	if name_key.is_empty():
		return id.capitalize()
	return tr(name_key)

func get_localized_description(placeholders: Dictionary = {}) -> String:
	if description_key.is_empty():
		return ""
	return tr(description_key).format(placeholders)

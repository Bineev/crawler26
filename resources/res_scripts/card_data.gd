# resources/cards/card_data.gd
extends Resource
class_name CardData

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID карты
@export var id: DataManager.CardId

## Происхождение карты (персонаж или биом)
@export var origin: DataManager.CardOrigin = DataManager.CardOrigin.CHARACTER

## Для карт персонажа
@export var character_class: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT

## Для карт биома
@export var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

## Ключ локализации для названия
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Иллюстрация карты
@export var texture: Texture2D

## Теги карты
@export var tags: Array[DataManager.CardTag] = []

## ============================================================
## ИГРОВЫЕ ПАРАМЕТРЫ
## ============================================================

## Грейд карты
@export var grade: DataManager.CardGrade = DataManager.CardGrade.COMMON

## Стоимость энергии
@export var cost: int = 1

## Список эффектов
@export var effects: Array[EffectEntry] = []

## ============================================================
## ВИЗУАЛЬНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип оверлея
@export var overlay_type: String = ""

## Ручное указание типов
@export var manual_card_types: Array[DataManager.CardType] = []


## ============================================================
## МЕТОДЫ
## ============================================================

func get_localized_name() -> String:
	if not name_key.is_empty():
		return tr(name_key)
	return DataManager.get_card_default_name(id)


func get_localized_description(placeholders: Dictionary = {}) -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key).format(placeholders)


func get_card_background() -> Texture2D:
	match origin:
		DataManager.CardOrigin.CHARACTER:
			return DataManager.get_card_background_for_class(character_class)
		DataManager.CardOrigin.BIOME:
			return DataManager.get_card_background_for_biome(biome)
		_:
			return null


func get_base_color() -> Color:
	match origin:
		DataManager.CardOrigin.CHARACTER:
			match character_class:
				DataManager.CharacterClass.PENITENT:
					return Color(0.35, 0.15, 0.15)  # тёмно-бордовый
				_:
					return Color(0.2, 0.2, 0.2)
		DataManager.CardOrigin.BIOME:
			match biome:
				DataManager.Biome.MOLE_TUNNELS:
					return Color(0.15, 0.1, 0.05)  # тёмно-коричневый
				_:
					return Color(0.1, 0.1, 0.1)
		_:
			return Color(0.2, 0.2, 0.2)


func has_tag(tag: DataManager.CardTag) -> bool:
	return tag in tags


func get_card_types() -> Array[DataManager.CardType]:
	if not manual_card_types.is_empty():
		return manual_card_types.duplicate()
	return _analyze_card_types()


func _analyze_card_types() -> Array[DataManager.CardType]:
	var types: Array[DataManager.CardType] = []
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				_add_type_unique(types, DataManager.CardType.ATTACK)
			DataManager.EffectCategory.BLOCK:
				_add_type_unique(types, DataManager.CardType.DEFEND)
			DataManager.EffectCategory.HEAL:
				_add_type_unique(types, DataManager.CardType.HEAL)
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.target == DataManager.EffectTarget.SELF:
					_add_type_unique(types, DataManager.CardType.BUFF_SELF)
				else:
					_add_type_unique(types, DataManager.CardType.DEBUFF)
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.target == DataManager.EffectTarget.SELF:
					_add_type_unique(types, DataManager.CardType.BUFF_SELF)
				else:
					_add_type_unique(types, DataManager.CardType.DEBUFF)
			DataManager.EffectCategory.DRAW_CARD, \
			DataManager.EffectCategory.GAIN_ENERGY, \
			DataManager.EffectCategory.SACRIFICE_CARD, \
			DataManager.EffectCategory.CONVERT, \
			DataManager.EffectCategory.CONVERT_EXCESS_TO_BLOCK, \
			DataManager.EffectCategory.MODIFY_STAT, \
			DataManager.EffectCategory.MODIFY_MODIFIER:
				_add_type_unique(types, DataManager.CardType.UTILITY)
	return types


func _add_type_unique(types: Array[DataManager.CardType], type: DataManager.CardType):
	if not types.has(type):
		types.append(type)


func _generate_default_description() -> String:
	var desc_parts = []
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				desc_parts.append("Наносит %d урона." % effect.base_value)
			DataManager.EffectCategory.BLOCK:
				desc_parts.append("Даёт %d блока." % effect.base_value)
			DataManager.EffectCategory.HEAL:
				desc_parts.append("Лечит %d HP." % effect.base_value)
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.status:
					desc_parts.append("Накладывает %d %s." % [effect.value, effect.status.get_localized_name()])
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive:
					desc_parts.append("Накладывает %s." % effect.passive.get_localized_name())
			DataManager.EffectCategory.MODIFY_STAT:
				desc_parts.append("Изменяет %s на %d." % [DataManager.FlatStat.keys()[effect.target_stat], effect.delta])
			DataManager.EffectCategory.DRAW_CARD:
				desc_parts.append("Добирает %d карт." % effect.amount)
			DataManager.EffectCategory.GAIN_ENERGY:
				desc_parts.append("Даёт %d энергии." % effect.amount)
	return "\n".join(desc_parts)


func duplicate_for_instance() -> CardData:
	var copy = CardData.new()
	copy.id = id
	copy.origin = origin
	copy.character_class = character_class
	copy.biome = biome
	copy.name_key = name_key
	copy.description_key = description_key
	copy.texture = texture
	copy.tags = tags.duplicate()
	copy.grade = grade
	copy.cost = cost
	copy.overlay_type = overlay_type
	copy.manual_card_types = manual_card_types.duplicate()
	
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	
	return copy

func get_illustration() -> Texture2D:
	return DataManager.get_card_illustration(id)


func get_art_background_color(use_light: bool = false) -> Color:
	return DataManager.get_card_art_background_color(origin, character_class, biome, use_light)

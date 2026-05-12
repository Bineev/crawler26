# resources/cards/card_data.gd
extends Resource
class_name CardData

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID карты (например, "sinful_strike")
@export var id: String = ""

## Ключи локализации
@export var name_key: String = ""           # ключ для названия
@export var description_key: String = ""    # ключ для описания

## Иллюстрация карты (Graphic symbol)
@export var texture: Texture2D

## ============================================================
## ИГРОВЫЕ ПАРАМЕТРЫ
## ============================================================

## Грейд карты (Common, Rare, Epic, Legendary, Mythic)
@export var grade: DataManager.CardGrade = DataManager.CardGrade.COMMON

## Тип карты (Attack, Block, Skill, Power)
@export var card_type: DataManager.CardType = DataManager.CardType.ATTACK

## Стоимость энергии
@export var cost: int = 1

## Список эффектов, которые выполняются при разыгрывании
@export var effects: Array[EffectEntry] = []

## Список модификаторов, навешиваемых на карту (например, Потрошитель)
@export var card_modifiers: Array[ModifierEntry] = []

## ============================================================
## ВИЗУАЛЬНЫЕ ПАРАМЕТРЫ (для шейдерных эффектов)
## ============================================================

## Тип оверлея (для утилити модификаторов)
@export var overlay_type: String = ""   # "etheral", "golden", "fiery"

## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return id.capitalize()
	return tr(name_key)

## Возвращает локализованное описание с подстановкой значений
func get_localized_description(placeholders: Dictionary = {}) -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key).format(placeholders)

## Генерирует описание по умолчанию (если нет ключа локализации)
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
				desc_parts.append("Накладывает %d стаков %s на %d ходов." % [effect.stacks, DataManager.get_status_name(effect.status), effect.status_duration])
			DataManager.EffectCategory.APPLY_PASSIVE:
				desc_parts.append("Накладывает %s на %d ходов." % [DataManager.get_passive_name(effect.passive), effect.passive_duration])
			DataManager.EffectCategory.DRAW_CARD:
				desc_parts.append("Добирает %d карт." % effect.amount)
			DataManager.EffectCategory.GAIN_ENERGY:
				desc_parts.append("Даёт %d энергии." % effect.amount)
	return "\n".join(desc_parts)

## Возвращает иконку грейда
func get_grade_icon() -> Texture2D:
	match grade:
		DataManager.CardGrade.COMMON:
			return load("res://ui/grades/star_empty.png")
		DataManager.CardGrade.RARE:
			return load("res://ui/grades/star.png")
		DataManager.CardGrade.EPIC:
			return load("res://ui/grades/star_epic.png")
		DataManager.CardGrade.LEGENDARY:
			return load("res://ui/grades/star_legendary.png")
		DataManager.CardGrade.MYTHIC:
			return load("res://ui/grades/star_mythic.png")
		_:
			return null

## Возвращает цвет подложки карты (зависит от персонажа)
func get_base_color() -> Color:
	# Здесь можно вернуть цвет в зависимости от персонажа
	# Пока заглушка для Сломленного
	return Color(0.35, 0.15, 0.15)  # тёмно-бордовый

# resources/cards/card_data.gd
extends Resource
class_name CardData

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID карты
@export var id: String = ""

## Ключ локализации для названия
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Иллюстрация карты (Graphic symbol)
@export var texture: Texture2D

## Теги карты (сгорающая и т.д.)
@export var tags: Array[DataManager.CardTag] = []


## ============================================================
## ИГРОВЫЕ ПАРАМЕТРЫ
## ============================================================

## Грейд карты (Common, Rare, Epic, Legendary, Mythic)
@export var grade: DataManager.CardGrade = DataManager.CardGrade.COMMON

## Стоимость энергии
@export var cost: int = 1

## Список эффектов, которые выполняются при разыгрывании
@export var effects: Array[EffectEntry] = []


## ============================================================
## ВИЗУАЛЬНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип оверлея (для утилити модификаторов)
@export var overlay_type: String = ""   # "etheral", "golden", "fiery"


## ============================================================
## РУЧНОЕ ПЕРЕОПРЕДЕЛЕНИЕ ТИПОВ
## ============================================================

## Ручное указание типов (если пусто — используется автоматический анализ)
@export var manual_card_types: Array[DataManager.CardType] = []


## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return id.capitalize()
	return tr(name_key)


## Возвращает локализованное описание
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
				if effect.status:
					desc_parts.append("Накладывает %d %s на %d ходов." % [effect.value, effect.status.get_localized_name(), effect.duration])
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive:
					desc_parts.append("Накладывает %s на %d ходов." % [effect.passive.get_localized_name(), effect.passive_duration])
			DataManager.EffectCategory.MODIFY_STAT:
				desc_parts.append("Изменяет %s на %d." % [DataManager.FlatStat.keys()[effect.target_stat], effect.delta])
			DataManager.EffectCategory.DRAW_CARD:
				desc_parts.append("Добирает %d карт." % effect.amount)
			DataManager.EffectCategory.GAIN_ENERGY:
				desc_parts.append("Даёт %d энергии." % effect.amount)
			DataManager.EffectCategory.CONVERT:
				desc_parts.append("Конвертирует %s в %s с коэффициентом %.1f." % [DataManager.FlatStat.keys()[effect.from_stat], DataManager.FlatStat.keys()[effect.to_stat], effect.conversion_ratio])
	return "\n".join(desc_parts)


## ============================================================
## ТИПЫ КАРТ (для UI)
## ============================================================

## Возвращает массив типов карты
func get_card_types() -> Array[DataManager.CardType]:
	# Если указаны вручную — используем их
	if not manual_card_types.is_empty():
		return manual_card_types.duplicate()
	
	# Иначе — автоматический анализ
	return _analyze_card_types()


## Анализирует эффекты для определения типов
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
			
			DataManager.EffectCategory.MODIFY_STAT:
				if effect.target_stat == DataManager.FlatStat.ATONEMENT:
					_add_type_unique(types, DataManager.CardType.RESOURCE)
			
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
			
			DataManager.EffectCategory.DRAW_CARD:
				_add_type_unique(types, DataManager.CardType.UTILITY)
			
			DataManager.EffectCategory.GAIN_ENERGY:
				_add_type_unique(types, DataManager.CardType.UTILITY)
			
			DataManager.EffectCategory.SACRIFICE_CARD:
				_add_type_unique(types, DataManager.CardType.UTILITY)
	
	return types


func _add_type_unique(types: Array[DataManager.CardType], type: DataManager.CardType):
	if not types.has(type):
		types.append(type)


## ============================================================
## ВИЗУАЛЬНЫЕ ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

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


## Возвращает цвет подложки карты (зависит от персонажа/биома)
func get_base_color() -> Color:
	# Пока заглушка для Сломленного
	return Color(0.35, 0.15, 0.15)  # тёмно-бордовый


## ============================================================
## ТЕГИ
## ============================================================

## Проверяет наличие тега
func has_tag(tag: DataManager.CardTag) -> bool:
	return tag in tags


## ============================================================
## КОПИРОВАНИЕ (если нужно)
## ============================================================

## Создаёт копию карты (для боя)
func duplicate_for_instance() -> CardData:
	var copy = CardData.new()
	copy.id = id
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

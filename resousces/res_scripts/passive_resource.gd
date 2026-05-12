# resources/passives/passive_resource.gd
extends Resource
class_name PassiveResource

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID пассивки (из DataManager.Passive)
@export var id: DataManager.Passive

## Ключи локализации
@export var name_key: String = ""
@export var description_key: String = ""

## Иконка пассивки (64×64)
@export var icon: Texture2D


## ============================================================
## МЕХАНИКА ПАССИВКИ
## ============================================================

## Тип зарядов (PERMANENT / TURN_BASED / USAGE_BASED / CONDITIONAL)
@export var charge_type: DataManager.PassiveChargeType = DataManager.PassiveChargeType.PERMANENT

## Стартовое количество зарядов (0 = безлимит для PERMANENT)
@export var starting_charges: int = 0

## Эффекты, которые срабатывают при активации (для USAGE_BASED / CONDITIONAL)
@export var activation_effects: Array[EffectEntry] = []

## Эффекты в конце хода (для TURN_BASED)
@export var end_of_turn_effects: Array[EffectEntry] = []

## Постоянные модификаторы (действуют, пока активна пассивка)
@export var modifiers: Array[ModifierEntry] = []

## Специальная логика (для сложных пассивок, например, Оживление)
@export var custom_logic_script: Script = null


## ============================================================
## МЕТОДЫ
## ============================================================

func get_localized_name() -> String:
	if name_key.is_empty():
		return DataManager.Passive.keys()[id]
	return tr(name_key)

func get_localized_description() -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key)

func _generate_default_description() -> String:
	match id:
		DataManager.Passive.SHAME:
			return "Увеличивает входящий урон на 25% и удваивает получаемое Искупление."
		DataManager.Passive.DESPAIR:
			return "Снижает исходящий урон на 25%."
		DataManager.Passive.REGROWTH:
			return "Растущая регенерация: +2, +3, +4... каждый ход."
		DataManager.Passive.VENOMOUS_SHIELD:
			return "При получении урона накладывает Яд на атакующего."
		DataManager.Passive.WRATH:
			return "В конце каждого хода даёт +1 Силы."
		DataManager.Passive.FREEZING_GROUND:
			return "При получении атаки накладывает Лёд на атакующего. Перезарядка 6 ходов."
		DataManager.Passive.DENIAL:
			return "Блокирует первые 3 негативных статуса."
		_:
			return ""

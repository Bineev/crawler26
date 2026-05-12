# resources/passives/passive_resource.gd
extends Resource
class_name PassiveResource

@export var id: DataManager.Passive
@export var name_key: String = ""
@export var description_key: String = ""
@export var icon: Texture2D

@export var charge_type: DataManager.PassiveChargeType = DataManager.PassiveChargeType.PERMANENT
@export var starting_charges: int = 0

## Триггер активации
@export var trigger: DataManager.PassiveTrigger = DataManager.PassiveTrigger.ON_TAKE_DAMAGE

## Эффекты, которые активируются
@export var effects: Array[EffectEntry] = []

## Постоянные модификаторы
@export var modifiers: Array[ModifierEntry] = []

## Сложная логика
@export var custom_logic_script: Script = null

## ============================================================
## СОСТОЯНИЕ (для копий ресурса)
## ============================================================

## Текущие заряды (для копий)
var current_charges: int = 0

## Счётчик применения эффектов (для роста)
var effect_application_counters: Dictionary = {}  # key: EffectEntry, value: counter


## ============================================================
## МЕТОДЫ
## ============================================================

## Создаёт копию пассивки для использования на конкретной цели
func duplicate_for_instance() -> PassiveResource:
	var instance = PassiveResource.new()
	
	# Копируем основные поля
	instance.id = id
	instance.name_key = name_key
	instance.description_key = description_key
	instance.icon = icon
	instance.charge_type = charge_type
	instance.starting_charges = starting_charges
	instance.trigger = trigger
	instance.custom_logic_script = custom_logic_script
	
	# Копируем эффекты (глубокое копирование)
	for effect in effects:
		instance.effects.append(effect.duplicate_for_instance())
	
	# Копируем модификаторы
	for mod in modifiers:
		instance.modifiers.append(mod.duplicate(true))
	
	# Копируем состояние
	instance.current_charges = current_charges
	instance.effect_application_counters = effect_application_counters.duplicate()
	
	return instance


## Создаёт копию (синоним для удобства)
func create_instance() -> PassiveResource:
	return duplicate_for_instance()


## Инициализирует состояние копии перед использованием
func init_instance():
	current_charges = starting_charges
	effect_application_counters.clear()


## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return DataManager.Passive.keys()[id]
	return tr(name_key)


## Возвращает локализованное описание
func get_localized_description() -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key)


## Генерирует описание по умолчанию
func _generate_default_description() -> String:
	match id:
		DataManager.Passive.REGROWTH:
			return "Каждый ход лечит на растущую величину."
		DataManager.Passive.VENOMOUS_SHIELD:
			return "При получении урона накладывает Яд на атакующего."
		DataManager.Passive.WRATH:
			return "В конце каждого хода даёт +1 Силы."
		DataManager.Passive.FREEZING_GROUND:
			return "При получении атаки накладывает Лёд на атакующего. 3 заряда."
		DataManager.Passive.DENIAL:
			return "Блокирует первые 3 негативных статуса."
		_:
			return ""


## Проверяет, имеет ли пассивка постоянные заряды
func has_charges() -> bool:
	return charge_type != DataManager.PassiveChargeType.PERMANENT


## Тратит один заряд
func consume_charge() -> bool:
	if not has_charges():
		return true
	
	if current_charges <= 0:
		return false
	
	current_charges -= 1
	return true


## Получает количество оставшихся зарядов (для UI)
func get_remaining_charges() -> int:
	return current_charges


## Получает счётчик применений для эффекта (для роста)
func get_effect_counter(effect: EffectEntry) -> int:
	return effect_application_counters.get(effect.get_instance_id(), 0)


## Увеличивает счётчик применений для эффекта
func increment_effect_counter(effect: EffectEntry):
	var key = effect.get_instance_id()
	effect_application_counters[key] = effect_application_counters.get(key, 0) + 1


## Сбрасывает счётчик применений для эффекта
func reset_effect_counter(effect: EffectEntry):
	effect_application_counters.erase(effect.get_instance_id())


## Проверяет, активна ли пассивка (есть ли заряды)
func is_active() -> bool:
	if not has_charges():
		return true
	return current_charges > 0

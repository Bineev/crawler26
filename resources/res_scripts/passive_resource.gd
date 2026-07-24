# resources/passives/passive_resource.gd
extends Resource
class_name PassiveResource

## ============================================================
## ОСНОВНЫЕ ПАРАМЕТРЫ
## ============================================================

## Уникальный ID пассивки (из DataManager.Passive)
@export var id: DataManager.Passive

## Ключи локализации
@export var name_key: String = ""
@export var description_key: String = ""

## Иконка пассивки (64×64)
@export var icon: Texture2D


## ============================================================
## ТИП ПАССИВКИ
## ============================================================

## Тип зарядов (PERMANENT, TURN_BASED, USAGE_BASED, CONDITIONAL)
@export var charge_type: DataManager.PassiveChargeType = DataManager.PassiveChargeType.PERMANENT

## Стартовое количество зарядов (0 = безлимит для PERMANENT)
@export var starting_charges: int = 0

## Триггер активации
@export var trigger: DataManager.PassiveTrigger = DataManager.PassiveTrigger.ON_TAKE_DAMAGE


## ============================================================
## ЭФФЕКТЫ
## ============================================================

## Эффекты, которые активируются при срабатывании триггера
@export var effects: Array[EffectEntry] = []

## Постоянные модификаторы (действуют, пока активна пассивка)
@export var modifiers: Array[ModifierEntry] = []

## Сложная логика (для пассивок, которые не покрываются эффектами/модификаторами)
@export var custom_logic_script: Script = null


## ============================================================
## СОСТОЯНИЕ (для копий ресурса)
## ============================================================

## Текущие заряды
var current_charges: int = 0

## Счётчик применений эффектов (для роста)
var effect_application_counters: Dictionary = {}  # key: EffectEntry.get_instance_id(), value: counter


## ============================================================
## МЕТОДЫ КОПИРОВАНИЯ
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
	
	# Копируем модификаторы (глубокое копирование)
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


## Очищает состояние (при удалении пассивки)
func clear_instance_state():
	current_charges = 0
	effect_application_counters.clear()


## ============================================================
## ЛОКАЛИЗАЦИЯ
## ============================================================

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
			return tr("passive_regrowth_desc")
		DataManager.Passive.VENOMOUS_SHIELD:
			return tr("passive_venomous_shield_desc")
		DataManager.Passive.WRATH:
			return tr("passive_wrath_desc")
		DataManager.Passive.FREEZING_GROUND:
			return tr("passive_freezing_ground_desc")
		DataManager.Passive.DENIAL:
			return tr("passive_denial_desc")
		DataManager.Passive.SHAME:
			return tr("passive_shame_desc")
		_:
			return tr("passive_unknown_desc")


## ============================================================
## УПРАВЛЕНИЕ ЗАРЯДАМИ
## ============================================================

## Проверяет, имеет ли пассивка заряды
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


## Восстанавливает заряды до стартового значения
func restore_charges():
	current_charges = starting_charges


## Получает количество оставшихся зарядов (для UI)
func get_remaining_charges() -> int:
	return current_charges


## ============================================================
## СЧЁТЧИКИ ДЛЯ РОСТА ЭФФЕКТОВ
## ============================================================

## Получает счётчик применений для эффекта
func get_effect_counter(effect: EffectEntry) -> int:
	return effect_application_counters.get(effect.get_instance_id(), 0)


## Увеличивает счётчик применений для эффекта
func increment_effect_counter(effect: EffectEntry):
	var key = effect.get_instance_id()
	effect_application_counters[key] = effect_application_counters.get(key, 0) + 1


## Сбрасывает счётчик применений для эффекта
func reset_effect_counter(effect: EffectEntry):
	effect_application_counters.erase(effect.get_instance_id())


## ============================================================
## ПРОВЕРКИ
## ============================================================

## Проверяет, активна ли пассивка (есть ли заряды)
func is_active() -> bool:
	if not has_charges():
		return true
	return current_charges > 0


## Возвращает триггер активации
func get_trigger() -> DataManager.PassiveTrigger:
	return trigger


## ============================================================
## UI МЕТОДЫ
## ============================================================

## Возвращает иконку пассивки (через DataManager)
func get_icon() -> Texture2D:
	return DataManager.get_passive_icon(id)


## Возвращает строковое представление зарядов (для UI)
func get_charges_string() -> String:
	if not has_charges():
		return ""
	return str(current_charges) + "/" + str(starting_charges)

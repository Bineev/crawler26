# resources/enemies/enemy_resource.gd
extends Resource
class_name EnemyResource

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID врага
@export var id: String = ""

## Ключи локализации
@export var name_key: String = ""
@export var description_key: String = ""

## Иконка / портрет врага
@export var icon: Texture2D

## Спрайт врага (для боя)
@export var sprite: Texture2D


## ============================================================
## БАЗОВЫЕ ХАРАКТЕРИСТИКИ
## ============================================================

## Максимальное здоровье
@export var max_health: int = 30

## Базовая сила атаки (может меняться от статусов)
@export var base_strength: int = 5


## ============================================================
## ПАССИВКИ (постоянные эффекты)
## ============================================================

## Пассивки, которые есть у врага с самого начала боя
@export var starting_passives: Array[PassiveResource] = []


## ============================================================
## НАМЕРЕНИЯ (действия по ходам)
## ============================================================

## Цикл намерений (последовательность или случайная)
@export var intent_cycle: Array[IntentEntry] = []

## Тип цикла (SEQUENTIAL, RANDOM, RANDOM_WITHOUT_REPEAT)
@export var cycle_type: DataManager.IntentCycleType = DataManager.IntentCycleType.SEQUENTIAL


## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return id.capitalize()
	return tr(name_key)

## Возвращает локализованное описание
func get_localized_description() -> String:
	if description_key.is_empty():
		return ""
	return tr(description_key)

## Создаёт копию врага для боя
func create_instance() -> EnemyInstance:
	var instance = EnemyInstance.new()
	instance.resource = self
	instance.max_health = max_health
	instance.current_health = max_health
	instance.base_strength = base_strength
	
	# Копируем пассивки
	for passive in starting_passives:
		instance.starting_passives.append(passive.duplicate_for_instance())
	
	# Копируем намерения
	for intent in intent_cycle:
		instance.intent_cycle.append(intent.duplicate_for_instance())
	
	instance.cycle_type = cycle_type
	instance.current_cycle_index = 0
	
	return instance

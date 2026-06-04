# resources/statuses/status_resource.gd
extends Resource
class_name StatusResource

@export var id: DataManager.Status
@export var name_key: String = ""
@export var description_key: String = ""
@export var icon: Texture2D

## Тикание
@export var is_ticking: bool = false
@export var tick_interval: int = 1
@export var ignore_block: bool = false
@export var damage_owner: bool = false

## Стаки
@export var is_stacking: bool = false
@export var max_stacks: int = 0
@export var effect_per_stack: float = 0.0

## Порог
@export var threshold_stacks: int = 0
@export var threshold_effect: EffectEntry = null

## Постоянные модификаторы
@export var modifiers: Array[ModifierEntry] = []

## Что делает при тике
@export var tick_effect: EffectEntry = null


## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	if name_key.is_empty():
		return DataManager.get_status_name(id)
	return tr(name_key)


## Возвращает локализованное описание
func get_localized_description() -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key)


## Генерирует описание по умолчанию
func _generate_default_description() -> String:
	match id:
		DataManager.Status.POISON:
			return "Наносит %d урона в конце хода. Игнорирует броню." % DataManager.POISON_BASE_DAMAGE_PER_STACK
		DataManager.Status.BLEED:
			return "Наносит %d урона за каждый стак раз в 2 хода." % DataManager.BLEED_BASE_DAMAGE_PER_STACK
		DataManager.Status.BURN:
			var desc = "Наносит %d урона владельцу в конце хода." % DataManager.BURN_BASE_DAMAGE_PER_STACK
			if DataManager.BURN_THRESHOLD_STACKS > 0:
				desc += " При %d стаках взрывается." % DataManager.BURN_THRESHOLD_STACKS
			return desc
		DataManager.Status.COLD:
			return "Снижает исходящий урон на %.0f%% за стак (макс 25%%)." % (DataManager.COLD_EFFECT_PERCENT_PER_STACK * 100)
		DataManager.Status.WEAKNESS:
			return "Атаки наносят на 25%% меньше урона."
		DataManager.Status.VULNERABILITY:
			return "Получает на 50%% больше урона от всех источников."
		DataManager.Status.STRENGTH:
			return "Увеличивает урон на %d за стак." % DataManager.STRENGTH_FLAT_BONUS_PER_STACK
		DataManager.Status.REGEN:
			return "Лечит %d HP в конце хода за каждый стак." % DataManager.REGEN_HEAL_PER_STACK
		DataManager.Status.SHIELD:
			return "Поглощает входящий урон. Сбрасывается в конце хода."
		_:
			return ""


## Получает урон за тик
func get_tick_damage(stacks: int) -> int:
	match id:
		DataManager.Status.BLEED:
			return stacks * DataManager.BLEED_BASE_DAMAGE_PER_STACK
		DataManager.Status.POISON:
			return stacks * DataManager.POISON_BASE_DAMAGE_PER_STACK
		DataManager.Status.BURN:
			return stacks * DataManager.BURN_BASE_DAMAGE_PER_STACK
		DataManager.Status.REGEN:
			return stacks * DataManager.REGEN_HEAL_PER_STACK
		_:
			return 0


## Получает множитель эффекта (для Cold)
func get_effect_multiplier(stacks: int) -> float:
	if id == DataManager.Status.COLD:
		var total = 1.0 - (stacks * DataManager.COLD_EFFECT_PERCENT_PER_STACK)
		return max(total, DataManager.COLD_MIN_EFFECT_MULTIPLIER)
	return 1.0


## Проверка, является ли статус негативным
func is_negative() -> bool:
	return DataManager.is_negative_status(id)


## Создаёт копию статуса для использования на конкретной цели
func duplicate_for_instance() -> StatusResource:
	var copy = StatusResource.new()
	copy.id = id
	copy.name_key = name_key
	copy.description_key = description_key
	copy.icon = icon
	copy.is_ticking = is_ticking
	copy.tick_interval = tick_interval
	copy.ignore_block = ignore_block
	copy.damage_owner = damage_owner
	copy.is_stacking = is_stacking
	copy.max_stacks = max_stacks
	copy.effect_per_stack = effect_per_stack
	copy.threshold_stacks = threshold_stacks
	copy.modifiers = modifiers.duplicate(true)
	
	if threshold_effect:
		copy.threshold_effect = threshold_effect.duplicate_for_instance()
	if tick_effect:
		copy.tick_effect = tick_effect.duplicate_for_instance()
	
	return copy


## Очищает состояние копии (если нужно)
func clear_instance_state():
	pass  # У статусов нет состояния, всё в CharacterStats

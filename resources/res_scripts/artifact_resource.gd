# resources/res_scripts/artifact_resource.gd
extends Resource
class_name ArtifactResource

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## ID артефакта
@export var id: DataManager.ArtifactId

## Грейд стоимости в магазине
@export var cost_grade: DataManager.CostGrade = DataManager.CostGrade.EXPENSIVE

## Грейд артефакта
@export var grade: DataManager.ArtifactGrade = DataManager.ArtifactGrade.NORMAL

## Тип срабатывания (может быть несколько)
@export var triggers: Array[DataManager.ArtifactTrigger] = []


## ============================================================
## ЛОКАЛИЗАЦИЯ
## ============================================================

## Ключ локализации для названия
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Ключ локализации для лор-описания
@export var lore_key: String = ""

## Для CONDITIONAL (HEALTH_DROPPED_BELOW)
@export var is_one_time_conditional: bool = false
@export var amount_check_conditional: int = 0
@export var is_amount_check_percent: bool = false
## ============================================================
## ВИЗУАЛ
## ============================================================

## Иконка артефакта
@export var icon: Texture2D


## ============================================================
## ПАРАМЕТРЫ (для разных типов)
## ============================================================

## Для ONE_TIME / TURN_COUNT_*
@export var trigger_count: int = 0          # количество срабатываний / ходов

## Для CARD_PLAYED_COUNTER
@export var card_count_threshold: int = 0   # количество сыгранных карт

## Для CONDITIONAL
@export var condition_script: Script = null # скрипт условия

## Статус, который нужно отслеживать (для ADD_ACTION_WHEN_APPLY_CONCRETE_STATUS_TO_ENEMY)
@export var tracked_status: DataManager.Status = DataManager.Status.POISON

## Для DAMAGE_THRESHOLD — порог урона
@export var damage_threshold: int = 0
## ============================================================
## ЭФФЕКТЫ
## ============================================================

## Эффекты, которые применяются при срабатывании
@export var effects: Array[EffectEntry] = []

@export var attack_threshold: int = 0
## ============================================================
## МЕТОДЫ
## ============================================================

## Возвращает локализованное название
func get_localized_name() -> String:
	#if not name_key.is_empty():
		#return tr(name_key)
	return DataManager.get_artifact_name(id)

## Возвращает локализованное описание
func get_localized_description() -> String:
	#if not description_key.is_empty():
		#return tr(description_key)
	return DataManager.get_artifact_description(id)

## Возвращает локализованное лор-описание
func get_localized_lore() -> String:
	if not lore_key.is_empty():
		return tr(lore_key)
	return ""

## Возвращает иконку
func get_icon() -> Texture2D:
	if icon:
		return icon
	return DataManager.get_artifact_icon(id)

## Проверяет, есть ли у артефакта указанный триггер
func has_trigger(trigger: DataManager.ArtifactTrigger) -> bool:
	return trigger in triggers

## Создаёт копию артефакта для использования в забеге
func duplicate_for_instance() -> ArtifactResource:
	var copy = ArtifactResource.new()
	copy.id = id
	copy.grade = grade
	copy.triggers = triggers.duplicate()
	copy.name_key = name_key
	copy.description_key = description_key
	copy.lore_key = lore_key
	copy.icon = icon
	copy.trigger_count = trigger_count
	copy.card_count_threshold = card_count_threshold
	copy.condition_script = condition_script
	
	# 🆕 Новые поля
	copy.is_one_time_conditional = is_one_time_conditional
	copy.amount_check_conditional = amount_check_conditional
	copy.is_amount_check_percent = is_amount_check_percent
	copy.tracked_status = tracked_status
	copy.damage_threshold = damage_threshold
	copy.attack_threshold = attack_threshold
	
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	
	return copy


func get_cost_grade() -> DataManager.CostGrade:
	return cost_grade

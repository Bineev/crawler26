# scripts/enemy_instance.gd
extends Node
class_name EnemyInstance

## ============================================================
## ССЫЛКИ
## ============================================================

## Ресурс-шаблон врага
var resource: EnemyResource = null

## Компонент характеристик
var stats: CharacterStats = null


## ============================================================
## ХАРАКТЕРИСТИКИ (копия для боя)
## ============================================================

var max_health: int = 0
var current_health: int = 0
var base_strength: int = 0

## Активные пассивки (экземпляры)
var active_passives: Array[PassiveResource] = []

## Стартовые пассивки (копии)
var starting_passives: Array[PassiveResource] = []


## ============================================================
## НАМЕРЕНИЯ
## ============================================================

## Цикл намерений (копии)
var intent_cycle: Array[IntentEntry] = []

## Тип цикла
var cycle_type: DataManager.IntentCycleType = DataManager.IntentCycleType.SEQUENTIAL

## Текущий индекс в цикле (для SEQUENTIAL)
var current_cycle_index: int = 0

## Текущее намерение (показывается игроку)
var current_intent: IntentEntry = null


## ============================================================
## МЕТОДЫ
## ============================================================

## Инициализация врага
func init():
	stats = CharacterStats.new()
	stats.set_flat(DataManager.FlatStat.MAX_HEALTH, max_health)
	stats.set_flat(DataManager.FlatStat.HEALTH, current_health)
	
	# Добавляем стартовые пассивки
	for passive in starting_passives:
		stats.apply_passive(passive)
		active_passives.append(passive)


## Выбрать следующее намерение
func select_next_intent() -> IntentEntry:
	match cycle_type:
		DataManager.IntentCycleType.SEQUENTIAL:
			current_intent = intent_cycle[current_cycle_index]
			current_cycle_index = (current_cycle_index + 1) % intent_cycle.size()
		
		DataManager.IntentCycleType.RANDOM:
			var random_index = randi() % intent_cycle.size()
			current_intent = intent_cycle[random_index]
		
		DataManager.IntentCycleType.RANDOM_WITHOUT_REPEAT:
			var available_indices = []
			for i in range(intent_cycle.size()):
				if i != current_cycle_index:
					available_indices.append(i)
			if available_indices.is_empty():
				available_indices.append(0)
			var random_index = available_indices[randi() % available_indices.size()]
			current_intent = intent_cycle[random_index]
			current_cycle_index = random_index
	
	return current_intent


## Выполнить текущее намерение
func execute_intent(target: CharacterStats):
	if not current_intent:
		return
	
	for effect in current_intent.effects:
		EffectExecutor.execute(effect, stats, [target])


## Обработка конца хода
func process_end_of_turn():
	stats.process_end_of_turn()


## Проверка жив ли враг
func is_alive() -> bool:
	return stats.get_health() > 0


## ============================================================
## UI МЕТОДЫ
## ============================================================

## Получить текущее здоровье (для UI)
func get_health() -> int:
	return stats.get_health()


## Получить максимальное здоровье (для UI)
func get_max_health() -> int:
	return stats.get_max_health()


## Получить текущий блок (для UI)
func get_block() -> int:
	return stats.get_block()


## Получить иконку текущего намерения (через DataManager)
func get_current_intent_icon() -> Texture2D:
	if not current_intent:
		return DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
	
	# Преобразуем тип намерения из IntentEntry в IntentType
	var intent_type = _get_intent_type_from_entry(current_intent)
	return DataManager.get_intent_icon(intent_type)


## Получить описание текущего намерения
func get_current_intent_description() -> String:
	if current_intent:
		return current_intent.get_localized_description()
	return ""


## Преобразовать IntentEntry в IntentType
func _get_intent_type_from_entry(intent: IntentEntry) -> DataManager.IntentType:
	match intent.intent_type:
		DataManager.IntentType.ATTACK:
			return DataManager.IntentType.ATTACK
		DataManager.IntentType.DEFEND:
			return DataManager.IntentType.DEFEND
		DataManager.IntentType.BUFF:
			return DataManager.IntentType.BUFF
		DataManager.IntentType.DEBUFF:
			return DataManager.IntentType.DEBUFF
		DataManager.IntentType.APPLY_STATUS:
			return DataManager.IntentType.DEBUFF  # статус = дебафф
		DataManager.IntentType.APPLY_PASSIVE:
			return DataManager.IntentType.BUFF    # пассивка на себя = бафф
		_:
			return DataManager.IntentType.UNKNOWN


## ============================================================
## ДОПОЛНИТЕЛЬНЫЕ UI МЕТОДЫ
## ============================================================

## Получить активные статусы (с иконками и стаками)
func get_active_statuses_for_ui() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for status_id in stats.active_statuses.keys():
		var status_data = stats.active_statuses[status_id]
		var icon = DataManager.get_status_icon(status_id)
		if icon:
			result.append({
				"icon": icon,
				"stacks": status_data.stacks,
				"duration": status_data.duration,
				"name": DataManager.get_status_name(status_id)
			})
	return result


## Получить активные пассивки (с иконками)
func get_active_passives_for_ui() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for passive in active_passives:
		var icon = DataManager.get_passive_icon(passive.id)
		if icon:
			result.append({
				"icon": icon,
				"name": passive.get_localized_name(),
				"description": passive.get_localized_description()
			})
	return result

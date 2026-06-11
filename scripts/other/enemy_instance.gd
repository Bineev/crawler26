# scripts/enemy_instance.gd
extends CharacterStats
class_name EnemyInstance

## ============================================================
## ССЫЛКИ
## ============================================================

var resource: EnemyResource = null
var stats: CharacterStats = null
var enemy_ui: EnemyUI = null  # ссылка на UI

## ============================================================
## ХАРАКТЕРИСТИКИ
## ============================================================

var max_health: int = 0
var current_health: int = 0
var base_strength: int = 0


## ============================================================
## НАМЕРЕНИЯ
## ============================================================

var intent_cycle: Array = []  # Array[Dictionary]
var cycle_type: DataManager.IntentCycleType = DataManager.IntentCycleType.SEQUENTIAL
var current_cycle_index: int = 0
var current_intent: IntentEntry = null


## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

func init(floor_level: int = 1, biome_index: int = 1):
	stats = CharacterStats.new()
	
	var scale_multiplier = _calculate_scale(floor_level, biome_index)
	var scaled_max_health = int(resource.base_max_health * scale_multiplier)
	stats.set_flat(DataManager.FlatStat.MAX_HEALTH, scaled_max_health)
	stats.set_flat(DataManager.FlatStat.HEALTH, scaled_max_health)
	base_strength = int(resource.base_strength * scale_multiplier)
	
	for passive in resource.starting_passives:
		var passive_copy = passive.duplicate_for_instance()
		passive_copy.init_instance()
		stats.apply_passive(passive_copy)


func _calculate_scale(floor_level: int, biome_index: int) -> float:
	var scale = 1.0
	scale += (biome_index - 1) * 0.3
	scale += (floor_level - 1) * 0.1
	return scale


## ============================================================
## НАМЕРЕНИЯ
## ============================================================

func load_intents():
	var enemy_id = resource.get_enemy_id()
	intent_cycle.clear()
	
	var intents_list = DataManager.get_enemy_intents_list(enemy_id)
	for intent_data in intents_list:
		intent_cycle.append(intent_data)
	
	cycle_type = DataManager.get_enemy_cycle_type(enemy_id)


func _create_intent_from_data(data: Dictionary) -> IntentEntry:
	var intent = IntentEntry.new()
	intent.effects = []
	
	for effect_data in data:
		var effect = EffectEntry.new()
		effect.category = effect_data.get("category", 0)
		effect.target = effect_data.get("target", DataManager.EffectTarget.ENEMY)
		
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				effect.base_value = effect_data.get("base_value", 0)
			DataManager.EffectCategory.BLOCK:
				effect.base_value = effect_data.get("base_value", 0)
			DataManager.EffectCategory.HEAL:
				effect.base_value = effect_data.get("base_value", 0)
			DataManager.EffectCategory.APPLY_STATUS:
				var status_id = effect_data.get("status", 0)
				effect.status = DataManager.get_status_by_enum(status_id)
				effect.value = effect_data.get("value", 1)
				effect.duration = effect_data.get("duration", 0)
			DataManager.EffectCategory.APPLY_PASSIVE:
				var passive_id = effect_data.get("passive", 0)
				effect.passive = DataManager.get_passive_by_enum(passive_id)
				effect.passive_duration = effect_data.get("passive_duration", 0)
			_:
				continue
		
		intent.effects.append(effect)
	
	# Определяем тип намерения по эффектам
	intent.intent_type = _determine_intent_type(intent.effects)
	return intent


func _determine_intent_type(effects: Array[EffectEntry]) -> DataManager.IntentType:
	var has_damage = false
	var has_block = false
	var has_heal = false
	var has_debuff = false
	
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				has_damage = true
			DataManager.EffectCategory.HEAL:
				has_heal = true
			DataManager.EffectCategory.BLOCK:
				has_block = true
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.target == DataManager.EffectTarget.ENEMY:
					has_debuff = true
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.target == DataManager.EffectTarget.ENEMY:
					has_debuff = true
	
	if has_damage:
		return DataManager.IntentType.ATTACK
	if has_block:
		return DataManager.IntentType.DEFEND
	if has_heal:
		return DataManager.IntentType.HEAL
	if has_debuff:
		return DataManager.IntentType.DEBUFF
	
	return DataManager.IntentType.UNKNOWN


func select_next_intent() -> IntentEntry:
	if intent_cycle.is_empty():
		return null
	
	var selected_data = null
	
	match cycle_type:
		DataManager.IntentCycleType.SEQUENTIAL:
			selected_data = intent_cycle[current_cycle_index]
			current_cycle_index = (current_cycle_index + 1) % intent_cycle.size()
		
		DataManager.IntentCycleType.RANDOM:
			var random_index = randi() % intent_cycle.size()
			selected_data = intent_cycle[random_index]
		
		DataManager.IntentCycleType.RANDOM_WITHOUT_REPEAT:
			var available_indices = []
			for i in range(intent_cycle.size()):
				if i != current_cycle_index:
					available_indices.append(i)
			if available_indices.is_empty():
				available_indices.append(0)
			var random_index = available_indices[randi() % available_indices.size()]
			selected_data = intent_cycle[random_index]
			current_cycle_index = random_index
	
	if selected_data != null:
		current_intent = _create_intent_from_data(selected_data)
	
	return current_intent


func execute_intent(target: CharacterStats):
	if not current_intent:
		return
	
	for effect in current_intent.effects:
		EffectExecutor.execute(effect, stats, [target])


## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	stats.process_end_of_turn()


## ============================================================
## ПРОВЕРКИ
## ============================================================

func is_alive() -> bool:
	return stats.get_health() > 0


## ============================================================
## UI МЕТОДЫ
## ============================================================

func get_health() -> int:
	return stats.get_health()


func get_max_health() -> int:
	return stats.get_max_health()


func get_block() -> int:
	return stats.get_block()


func get_current_intent_icon() -> Texture2D:
	if not current_intent:
		return DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
	return DataManager.get_intent_icon(current_intent.intent_type)


func get_current_intent_description() -> String:
	if current_intent:
		return current_intent.get_localized_description()
	return ""


## ============================================================
## СТАТУСЫ И ПАССИВКИ ДЛЯ UI
## ============================================================

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


func get_sprite() -> Texture2D:
	if resource:
		return resource.get_sprite()
	return null

extends CharacterStats
class_name EnemyInstance

## ============================================================
## ССЫЛКИ
## ============================================================

var resource: EnemyResource = null
var enemy_ui: EnemyUI = null
var click_area: Area2D = null

## ============================================================
## ХАРАКТЕРИСТИКИ
## ============================================================

var base_strength: int = 0
var is_aiming_mode: bool = false

## ============================================================
## НАМЕРЕНИЯ
## ============================================================

var intent_cycle: Array = []
var cycle_type: DataManager.IntentCycleType = DataManager.IntentCycleType.SEQUENTIAL
var current_cycle_index: int = 0
var current_intent: IntentEntry = null


## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

func _ready():
	SignalManager.selecting_target_changed.connect(_on_selecting_target_changed)
	SignalManager.enemy_died.connect(_on_self_died)


func init(floor_level: int = 1):
	var scale_multiplier = _calculate_scale(floor_level)
	var scaled_max_health = int(resource.base_max_health * scale_multiplier)
	
	# Используем self, а не stats
	set_flat(DataManager.FlatStat.MAX_HEALTH, scaled_max_health)
	set_flat(DataManager.FlatStat.HEALTH, scaled_max_health)
	base_strength = int(resource.base_strength * scale_multiplier)
	
	for passive in resource.starting_passives:
		var passive_copy = passive.duplicate_for_instance()
		passive_copy.init_instance()
		# starting_charges уже установлены в ресурсе
		apply_passive(passive_copy)

	# Находим компоненты
	enemy_ui = $EnemyUI
	click_area = $EnemyUI/ClickArea
	
	if click_area:
		click_area.mouse_entered.connect(_on_mouse_entered)
		click_area.mouse_exited.connect(_on_mouse_exited)


func _calculate_scale(floor_level: int) -> float:
	var scale = 1.0
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
	print("intents loaded")


func _create_intent_from_data(data: Array) -> IntentEntry:
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
	
	intent.intent_types = _determine_intent_types(intent.effects)
	return intent


func _determine_intent_types(effects) -> Array[DataManager.IntentType]:
	var types: Array[DataManager.IntentType] = []
	
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				if DataManager.IntentType.ATTACK not in types:
					types.append(DataManager.IntentType.ATTACK)
			DataManager.EffectCategory.HEAL:
				if DataManager.IntentType.HEAL not in types:
					types.append(DataManager.IntentType.HEAL)
			DataManager.EffectCategory.BLOCK:
				if DataManager.IntentType.DEFEND not in types:
					types.append(DataManager.IntentType.DEFEND)
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.target == DataManager.EffectTarget.ENEMY:
					if DataManager.IntentType.DEBUFF not in types:
						types.append(DataManager.IntentType.DEBUFF)
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.target == DataManager.EffectTarget.ENEMY:
					if DataManager.IntentType.DEBUFF not in types:
						types.append(DataManager.IntentType.DEBUFF)
				elif effect.target == DataManager.EffectTarget.SELF:
					if DataManager.IntentType.BUFF not in types:
						types.append(DataManager.IntentType.BUFF)
	
	if types.is_empty():
		types.append(DataManager.IntentType.UNKNOWN)
	
	return types


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
		print("Intent created with ", current_intent.effects.size(), " effects")
	
	return current_intent


func execute_intent(target: CharacterStats):
	if not current_intent:
		return
	SignalManager.log_message.emit("%s атакует!" % get_display_name())
	for effect in current_intent.effects:
		EffectExecutor.execute(effect, self, [target])  # ← self вместо stats


## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	super.process_end_of_turn()  # ← вызываем родительский


## ============================================================
## ПРОВЕРКИ
## ============================================================

func is_alive() -> bool:
	return get_health() > 0  # ← используем self


## ============================================================
## СТАТУСЫ И ПАССИВКИ ДЛЯ UI
## ============================================================

func get_active_statuses_for_ui() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for status_id in active_statuses.keys():
		var status_data = active_statuses[status_id]
		var icon = DataManager.get_status_icon(status_id)
		if icon:
			result.append({
				"status_id": status_id,  # ← добавляем
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
				"passive_id": passive.id,
				"icon": icon,
				"name": passive.get_localized_name(),
				"description": passive.get_localized_description(),
				"charges": passive.current_charges if passive.has_charges() else 0,
				"passive": passive,  # 🆕 нужно добавить сам ресурс
			})
	return result


func get_sprite() -> Texture2D:
	if resource:
		return resource.get_sprite()
	return null


func get_display_name() -> String:
	if resource:
		return resource.get_localized_name()
	return "Враг"


func _on_selecting_target_changed(is_selecting: bool):
	is_aiming_mode = is_selecting
	if not is_selecting:
		SignalManager.enemy_highlight_requested.emit(self, false)


func _on_mouse_entered():
	if is_aiming_mode:
		SignalManager.enemy_highlight_requested.emit(self, true)


func _on_mouse_exited():
	SignalManager.enemy_highlight_requested.emit(self, false)


func _on_self_died(enemy: CharacterStats):
	if enemy == self:
		die()


func die():
	# 🆕 Даём кости за убийство
	_give_bones_on_death()
	
	if enemy_ui:
		enemy_ui.die()
	else:
		queue_free()


func execute_intent_with_animation(target: CharacterStats):
	if not current_intent:
		return
	
	var has_damage = false
	var has_debuff = false
	
	for effect in current_intent.effects:
		if effect.category == DataManager.EffectCategory.DAMAGE:
			has_damage = true
		elif effect.category == DataManager.EffectCategory.APPLY_STATUS or effect.category == DataManager.EffectCategory.APPLY_PASSIVE:
			if effect.target == DataManager.EffectTarget.ENEMY:
				has_debuff = true
	
	# Проигрываем анимацию
	if enemy_ui:
		if has_damage:
			await enemy_ui.play_attack_animation()
		elif has_debuff:
			await enemy_ui.play_debuff_animation()
		else:
			await get_tree().create_timer(0.3).timeout
	
	# Выполняем эффекты с правильными целями
	SignalManager.log_message.emit("%s атакует!" % get_display_name())
	for effect in current_intent.effects:
		var targets = _get_targets_for_effect(effect, target)
		EffectExecutor.execute(effect, self, targets)


func _get_targets_for_effect(effect: EffectEntry, target: CharacterStats) -> Array:
	match effect.target:
		DataManager.EffectTarget.SELF:
			return [self]
		
		DataManager.EffectTarget.ENEMY:
			# Враг атакует игрока (цель — это игрок)
			if target:
				return [target]
			# Если цели нет — берём игрока из BattleManager
			var player = BattleManager.get_player()
			return [player] if player else []
		
		DataManager.EffectTarget.ALL_ENEMIES:
			# ALL_ENEMIES для врага — это игрок (один)
			var player = BattleManager.get_player()
			return [player] if player else []
		
		DataManager.EffectTarget.ALL_ALLIES:
			# Союзники врага — все враги (включая себя)
			return BattleManager.get_enemies()
		
		DataManager.EffectTarget.ANY:
			# Для ANY — если есть цель, берём её, иначе игрока
			if target:
				return [target]
			var player = BattleManager.get_player()
			return [player] if player else []
		
		_:
			if target:
				return [target]
			var player = BattleManager.get_player()
			return [player] if player else []


func _give_bones_on_death() -> void:
	# Количество костей зависит от размера врага
	var bones_amount = 0
	match resource.size:
		DataManager.EnemySize.WEAK:
			bones_amount = DataManager.REWARD_BONES_DEFAULT
		DataManager.EnemySize.NORMAL:
			bones_amount = DataManager.REWARD_BONES_DEFAULT * 2
		DataManager.EnemySize.ELITE:
			bones_amount = DataManager.REWARD_BONES_DEFAULT * 3
		DataManager.EnemySize.BOSS:
			bones_amount = DataManager.REWARD_BONES_DEFAULT * 4
	
	if bones_amount > 0:
		RunManager.add_bones(bones_amount)
		SignalManager.log_message.emit("Получено %d костей" % bones_amount)

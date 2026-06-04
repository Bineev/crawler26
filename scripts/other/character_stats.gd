# scripts/components/character_stats.gd
extends Node
class_name CharacterStats

## ============================================================
## СИГНАЛЫ
## ============================================================

signal health_changed(current: int, max: int)
signal energy_changed(current: int, max: int)
signal block_changed(current: int)
signal atonement_changed(current: int, max: int)  # Для PenitentStats
signal status_added(status_id: int, stacks: int, duration: int)
signal status_removed(status_id: int)
signal passive_added(passive_id: int)
signal passive_removed(passive_id: int)


## ============================================================
## БАЗОВЫЕ СТАТЫ (FLATS)
## ============================================================

var flats: Dictionary = {
	DataManager.FlatStat.HEALTH: 0,
	DataManager.FlatStat.MAX_HEALTH: 0,
	DataManager.FlatStat.ENERGY: 0,
	DataManager.FlatStat.MAX_ENERGY: 0,
	DataManager.FlatStat.BLOCK: 0,
	DataManager.FlatStat.HAND_SIZE: 5,
	DataManager.FlatStat.DRAW_PER_TURN: 5,
	DataManager.FlatStat.ATONEMENT: 0,
	DataManager.FlatStat.MAX_ATONEMENT: 30,
}


## ============================================================
## МОДИФИКАТОРЫ (PROCENT)
## ============================================================

var modifiers: Dictionary = {
	DataManager.ModifierStat.DAMAGE_DEALT_PERCENT: 1.0,
	DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT: 1.0,
	DataManager.ModifierStat.BLOCK_GAINED_PERCENT: 1.0,
	DataManager.ModifierStat.HEALING_RECEIVED_PERCENT: 1.0,
	DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER: 1.0,
	DataManager.ModifierStat.DAMAGE_FLAT_BONUS: 0,
}


## ============================================================
## СТАТУСЫ
## ============================================================

## Активные статусы: { status_id: { stacks: int, duration: int, resource: StatusResource } }
var active_statuses: Dictionary = {}


## ============================================================
## ПАССИВКИ
## ============================================================

## Активные пассивки (экземпляры PassiveResource)
var active_passives: Array[PassiveResource] = []


## ============================================================
## ИММУНИТЕТЫ (для взаимодействий)
## ============================================================

var immunity: Dictionary = {}  # status_id -> remaining_duration


## ============================================================
## МЕТОДЫ ДОСТУПА К СТАТАМ
## ============================================================

func get_flat(stat: DataManager.FlatStat) -> int:
	return flats.get(stat, 0)


func set_flat(stat: DataManager.FlatStat, value: int):
	flats[stat] = value
	_emit_flat_signal(stat)


func modify_flat(stat: DataManager.FlatStat, delta: int):
	flats[stat] = flats.get(stat, 0) + delta
	_emit_flat_signal(stat)


func get_modifier(stat: DataManager.ModifierStat) -> float:
	return modifiers.get(stat, 1.0)


func modify_modifier(stat: DataManager.ModifierStat, delta: float, duration: int = 0):
	modifiers[stat] = modifiers.get(stat, 1.0) + delta
	if duration > 0:
		# TODO: временные модификаторы с таймером
		pass


## ============================================================
## СИГНАЛЫ ДЛЯ UI
## ============================================================

func _emit_flat_signal(stat: DataManager.FlatStat):
	match stat:
		DataManager.FlatStat.HEALTH:
			health_changed.emit(get_flat(DataManager.FlatStat.HEALTH), get_flat(DataManager.FlatStat.MAX_HEALTH))
		DataManager.FlatStat.ENERGY:
			energy_changed.emit(get_flat(DataManager.FlatStat.ENERGY), get_flat(DataManager.FlatStat.MAX_ENERGY))
		DataManager.FlatStat.BLOCK:
			block_changed.emit(get_flat(DataManager.FlatStat.BLOCK))
		DataManager.FlatStat.ATONEMENT:
			atonement_changed.emit(get_flat(DataManager.FlatStat.ATONEMENT), get_flat(DataManager.FlatStat.MAX_ATONEMENT))


## ============================================================
## ЗДОРОВЬЕ, БЛОК, УРОН
## ============================================================

func get_health() -> int:
	return get_flat(DataManager.FlatStat.HEALTH)


func get_max_health() -> int:
	return get_flat(DataManager.FlatStat.MAX_HEALTH)


func get_block() -> int:
	return get_flat(DataManager.FlatStat.BLOCK)


func add_block(amount: int):
	var final_block = floor(amount * get_modifier(DataManager.ModifierStat.BLOCK_GAINED_PERCENT))
	modify_flat(DataManager.FlatStat.BLOCK, final_block)


func take_damage(amount: int, ignore_block: bool = false):
	var damage = amount
	
	# Применяем Холод (уменьшает входящий урон)
	if has_status(DataManager.Status.COLD):
		var cold_stacks = get_status_stacks(DataManager.Status.COLD)
		var cold_multiplier = 1.0 - (cold_stacks * DataManager.COLD_EFFECT_PERCENT_PER_STACK)
		damage *= max(cold_multiplier, DataManager.COLD_MIN_EFFECT_MULTIPLIER)
	
	damage = floor(damage)
	
	# Применяем блок
	if not ignore_block and get_block() > 0:
		var block_amount = get_block()
		if block_amount >= damage:
			modify_flat(DataManager.FlatStat.BLOCK, -damage)
			damage = 0
		else:
			modify_flat(DataManager.FlatStat.BLOCK, -block_amount)
			damage -= block_amount
	
	if damage > 0:
		modify_flat(DataManager.FlatStat.HEALTH, -damage)
		# Получение классового ресурса (переопределяется в PenitentStats)
		on_take_damage_gain_resource(damage)
		# Обработка пассивок ON_TAKE_DAMAGE
		_process_passive_triggers(DataManager.PassiveTrigger.ON_TAKE_DAMAGE, damage)


func heal(amount: int):
	var final_heal = floor(amount * get_modifier(DataManager.ModifierStat.HEALING_RECEIVED_PERCENT))
	var new_health = get_health() + final_heal
	set_flat(DataManager.FlatStat.HEALTH, min(new_health, get_max_health()))


## Для переопределения в наследниках
func on_take_damage_gain_resource(amount: int):
	pass


## ============================================================
## УПРАВЛЕНИЕ ИММУНИТЕТОМ
## ============================================================

func apply_immunity(status_id: DataManager.Status, duration: int):
	immunity[status_id] = duration


func has_immunity(status_id: DataManager.Status) -> bool:
	return immunity.has(status_id) and immunity[status_id] > 0


func _update_immunity_timer():
	var to_remove = []
	for status_id in immunity.keys():
		immunity[status_id] -= 1
		if immunity[status_id] <= 0:
			to_remove.append(status_id)
	for status_id in to_remove:
		immunity.erase(status_id)


## ============================================================
## УПРАВЛЕНИЕ СТАТУСАМИ
## ============================================================

func get_applied_statuses() -> Array:
	return active_statuses.keys()


func add_status(status: StatusResource, value: int, duration: int, passive_context: PassiveResource = null):
	if not status:
		return
	
	# Проверка иммунитета
	if _check_denial(status):
		return
	
	# Проверка возможности наложения через StatusInteractionManager
	if not StatusInteractionManager.can_apply(self, status.id):
		return
	
	var status_id = status.id
	var existing = active_statuses.get(status_id)
	
	if existing:
		# Обновляем существующий статус
		existing.stacks += value
		existing.duration = max(existing.duration, duration)
	else:
		# Новый статус
		active_statuses[status_id] = {
			"stacks": value,
			"duration": duration,
			"resource": status
		}
		_apply_status_modifiers(status)
		StatusInteractionManager.on_status_applied(self, status_id, value)
	
	# Особые эффекты статусов
	if status_id == DataManager.Status.BURN:
		# Горение даёт +1 Силы при наложении
		var strength_status = _get_strength_status_resource()
		if strength_status:
			add_status(strength_status, DataManager.BURN_STRENGTH_STACKS, DataManager.BURN_STRENGTH_DURATION)
	
	signal_emit(status_added, status_id, value, duration)


func _get_strength_status_resource() -> StatusResource:
	if DataManager.has_method("get_status_resource"):
		return DataManager.get_status_resource(DataManager.Status.STRENGTH)
	return null


func remove_status(status_id: DataManager.Status):
	if not active_statuses.has(status_id):
		return
	
	var data = active_statuses[status_id]
	var status = data["resource"]
	active_statuses.erase(status_id)
	
	_remove_status_modifiers(status)
	StatusInteractionManager.on_status_removed(self, status_id)
	signal_emit(status_removed, status_id)


func has_status(status_id: DataManager.Status) -> bool:
	return active_statuses.has(status_id)


func get_status_stacks(status_id: DataManager.Status) -> int:
	var data = active_statuses.get(status_id)
	return data["stacks"] if data else 0


func reduce_status_stacks(status_id: DataManager.Status, amount: int):
	if not active_statuses.has(status_id):
		return
	var data = active_statuses[status_id]
	data.stacks = max(0, data.stacks - amount)
	if data.stacks == 0:
		remove_status(status_id)


func freeze_poison():
	# Яд не тикает, пока есть холод
	pass


func unfreeze_poison():
	pass


func trigger_poison_immediately():
	# Мгновенная активация всего яда
	if has_status(DataManager.Status.POISON):
		var stacks = get_status_stacks(DataManager.Status.POISON)
		var damage = stacks * DataManager.POISON_BASE_DAMAGE_PER_STACK
		take_damage(damage, true)
		remove_status(DataManager.Status.POISON)


func _apply_status_modifiers(status: StatusResource):
	for mod in status.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) + mod.flat_bonus


func _remove_status_modifiers(status: StatusResource):
	for mod in status.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) - mod.flat_bonus


func _check_denial(status: StatusResource) -> bool:
	for passive in active_passives:
		if passive.id == DataManager.Passive.DENIAL and passive.is_active():
			if DataManager.is_negative_status(status.id):
				passive.consume_charge()
				return passive.is_active()
	return false


## ============================================================
## УПРАВЛЕНИЕ ПАССИВКАМИ
## ============================================================

func apply_passive(passive: PassiveResource, duration: int = -1):
	if not passive:
		return
	
	var instance = passive.duplicate_for_instance()
	instance.init_instance()
	
	if instance.charge_type == DataManager.PassiveChargeType.TURN_BASED and duration > 0:
		instance.current_charges = duration
	
	active_passives.append(instance)
	
	for mod in instance.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) + mod.flat_bonus
	
	signal_emit(passive_added, instance.id)


func remove_passive(passive: PassiveResource):
	var idx = active_passives.find(passive)
	if idx != -1:
		active_passives.remove_at(idx)
		for mod in passive.modifiers:
			modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.multiplier
			if mod.flat_bonus != 0:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0) - mod.flat_bonus
		signal_emit(passive_removed, passive.id)


func _process_passive_triggers(trigger: DataManager.PassiveTrigger, value = null):
	for passive in active_passives:
		if passive.trigger == trigger and passive.is_active():
			for effect in passive.effects:
				EffectExecutor.execute(effect, self, [self], {}, passive)


## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	var statuses_to_remove = []
	
	for status_id in active_statuses.keys():
		var data = active_statuses[status_id]
		var status = data["resource"]
		
		# Тикающие статусы
		if status.is_ticking:
			data.duration -= 1
			
			# Наносим урон/лечение от статуса
			if status.tick_effect:
				var tick_effect = status.tick_effect.duplicate_for_instance()
				tick_effect.value = status.get_tick_damage(data.stacks)
				
				if status.damage_owner:
					# Урон владельцу (Горение)
					EffectExecutor.execute(tick_effect, self, [self])
				else:
					# Урон врагам (Яд, Кровотечение) или лечение (Регенерация)
					if status.id == DataManager.Status.REGEN:
						# Регенерация лечит владельца
						EffectExecutor.execute(tick_effect, self, [self])
					else:
						var enemies = get_tree().get_nodes_in_group("enemies")
						EffectExecutor.execute(tick_effect, self, enemies)
			
			# Проверка взрыва Горения
			if status.id == DataManager.Status.BURN and data.stacks >= DataManager.BURN_THRESHOLD_STACKS:
				_trigger_burn_explosion(data.stacks)
				statuses_to_remove.append(status_id)
			
			# Удаляем, если длительность истекла
			if data.duration <= 0:
				statuses_to_remove.append(status_id)
	
	# Удаляем истекшие статусы
	for status_id in statuses_to_remove:
		remove_status(status_id)
	
	# Обновляем иммунитеты
	_update_immunity_timer()
	
	# Тик пассивок
	for passive in active_passives:
		if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.current_charges > 0:
			passive.current_charges -= 1
			if passive.current_charges <= 0:
				remove_passive(passive)
	
	# Триггер ON_TURN_END
	_process_passive_triggers(DataManager.PassiveTrigger.ON_TURN_END)


## ============================================================
## ВЗРЫВ ГОРЕНИЯ
## ============================================================

func _trigger_burn_explosion(stacks: int):
	var explosion_damage = stacks * DataManager.BURN_EXPLOSION_DAMAGE_PER_STACK
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(explosion_damage)
	remove_status(DataManager.Status.BURN)


## ============================================================
## МОДИФИКАТОР ИСХОДЯЩЕГО УРОНА (для Холода и других)
## ============================================================

func get_damage_multiplier() -> float:
	var multiplier = 1.0
	multiplier *= get_modifier(DataManager.ModifierStat.DAMAGE_DEALT_PERCENT)
	
	# Применяем Холод (уменьшает исходящий урон)
	if has_status(DataManager.Status.COLD):
		var cold_stacks = get_status_stacks(DataManager.Status.COLD)
		var cold_multiplier = 1.0 - (cold_stacks * DataManager.COLD_EFFECT_PERCENT_PER_STACK)
		multiplier *= max(cold_multiplier, DataManager.COLD_MIN_EFFECT_MULTIPLIER)
	
	return multiplier


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func signal_emit(sig: Signal, arg1 = null, arg2 = null, arg3 = null):
	if arg3 != null:
		sig.emit(arg1, arg2, arg3)
	elif arg2 != null:
		sig.emit(arg1, arg2)
	elif arg1 != null:
		sig.emit(arg1)
	else:
		sig.emit()

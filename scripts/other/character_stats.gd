# scripts/components/character_stats.gd
extends Node
class_name CharacterStats

## ============================================================
## СИГНАЛЫ
## ============================================================

signal health_changed(current: int, max: int)
signal energy_changed(current: int, max: int)
signal block_changed(current: int)
signal atonement_changed(current: int, max: int)
signal status_added(status_id: int, stacks: int, duration: int)
signal status_removed(status_id: int)
signal passive_added(passive_id: int)
signal passive_removed(passive_id: int)
signal died()


## ============================================================
## БАЗОВЫЕ СТАТЫ (FLATS)
## ============================================================

var flats: Dictionary[DataManager.FlatStat, int] = {
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

## Активные статусы: { status_id: { stacks: int, duration: int, resource: StatusResource, caster: CharacterStats } }
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
func _init():
	_init_flat_stats()


func _init_flat_stats():
	flats[DataManager.FlatStat.HEALTH] = DataManager.PENITENT_STARTING_HEALTH
	flats[DataManager.FlatStat.MAX_HEALTH] = DataManager.PENITENT_STARTING_HEALTH
	flats[DataManager.FlatStat.ENERGY] = DataManager.STARTING_ENERGY
	flats[DataManager.FlatStat.MAX_ENERGY] = DataManager.MAX_ENERGY
	flats[DataManager.FlatStat.BLOCK] = 0
	flats[DataManager.FlatStat.ATONEMENT] = 0
	flats[DataManager.FlatStat.MAX_ATONEMENT] = DataManager.PENITENT_MAX_ATONEMENT


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
			var current = get_flat(DataManager.FlatStat.HEALTH)
			var max_val = get_flat(DataManager.FlatStat.MAX_HEALTH)
			health_changed.emit(current, max_val)
			# Для глобальной шины
			SignalManager.health_changed.emit(current, max_val)
			# Если это враг
			if self is EnemyInstance:
				SignalManager.enemy_health_changed.emit(self, current, max_val)
		
		DataManager.FlatStat.ENERGY:
			var current = get_flat(DataManager.FlatStat.ENERGY)
			var max_val = get_flat(DataManager.FlatStat.MAX_ENERGY)
			energy_changed.emit(current, max_val)
			SignalManager.energy_changed.emit(current, max_val)
		
		DataManager.FlatStat.BLOCK:
			var current = get_flat(DataManager.FlatStat.BLOCK)
			block_changed.emit(current)
			SignalManager.block_changed.emit(current)
		
		DataManager.FlatStat.ATONEMENT:
			var current = get_flat(DataManager.FlatStat.ATONEMENT)
			var max_val = get_flat(DataManager.FlatStat.MAX_ATONEMENT)
			atonement_changed.emit(current, max_val)
			SignalManager.atonement_changed.emit(current, max_val)


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
		SignalManager.log_message.emit("%s получил %d урона" % [name, damage])
		modify_flat(DataManager.FlatStat.HEALTH, -damage)
		on_take_damage_gain_resource(damage)
		_process_passive_triggers(DataManager.PassiveTrigger.ON_TAKE_DAMAGE, damage)
		
		# Проверка смерти
		if get_health() <= 0:
			died.emit()
			SignalManager.enemy_died.emit(self)  # Для врагов


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


func get_status_caster(status_id: DataManager.Status) -> CharacterStats:
	var data = active_statuses.get(status_id)
	return data.get("caster", null) if data else null


func add_status(status: StatusResource, value: int, duration: int, caster: CharacterStats = null, passive_context: PassiveResource = null):
	if not status:
		return
	
	if _check_denial(status):
		return
	
	if not StatusInteractionManager.can_apply(self, status.id):
		return
	
	var status_id = status.id
	var existing = active_statuses.get(status_id)
	
	if existing:
		existing.stacks += value
		existing.duration = max(existing.duration, duration)
	else:
		active_statuses[status_id] = {
			"stacks": value,
			"duration": duration,
			"resource": status,
			"caster": caster if caster else self
		}
		_apply_status_modifiers(status)
		StatusInteractionManager.on_status_applied(self, status_id, value)
	
	if status_id == DataManager.Status.BURN:
		var strength_status = _get_strength_status_resource()
		if strength_status:
			add_status(strength_status, DataManager.BURN_STRENGTH_STACKS, DataManager.BURN_STRENGTH_DURATION, self, passive_context)
	
	# Локальный сигнал
	status_added.emit(status_id, value, duration)
	# Глобальный сигнал
	SignalManager.status_added.emit(self, status_id, value, duration)
	# Для врага отдельно
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	SignalManager.log_message.emit("Наложен %s: %d стаков на %d ходов" % [status.get_localized_name(), value, duration])


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
	
	# Локальный сигнал
	status_removed.emit(status_id)
	# Глобальный сигнал
	SignalManager.status_removed.emit(self, status_id)
	# Для врага отдельно
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)


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
	pass


func unfreeze_poison():
	pass


func trigger_poison_immediately():
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
		#BUG
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) + mod.flat_bonus
	
	# Локальный сигнал
	passive_added.emit(instance.id)
	# Глобальный сигнал
	SignalManager.passive_added.emit(self, instance.id)


func remove_passive(passive: PassiveResource):
	var idx = active_passives.find(passive)
	if idx != -1:
		active_passives.remove_at(idx)
		for mod in passive.modifiers:
			modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.multiplier
			if mod.flat_bonus != 0:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0) - mod.flat_bonus
		
		# Локальный сигнал
		passive_removed.emit(passive.id)
		# Глобальный сигнал
		SignalManager.passive_removed.emit(self, passive.id)


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
		
		if status.is_ticking:
			data.duration -= 1
			
			if status.tick_effect:
				var tick_effect = status.tick_effect.duplicate_for_instance()
				var caster = data.get("caster", null)
				tick_effect.value = status.get_tick_value(data.stacks, caster)
				EffectExecutor.execute(tick_effect, self, [self])
			
			if status.id == DataManager.Status.BURN and data.stacks >= DataManager.BURN_THRESHOLD_STACKS:
				_trigger_burn_explosion(data.stacks)
				statuses_to_remove.append(status_id)
			
			if data.duration <= 0:
				statuses_to_remove.append(status_id)
	
	for status_id in statuses_to_remove:
		remove_status(status_id)
	
	_update_immunity_timer()
	
	for passive in active_passives:
		if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.current_charges > 0:
			passive.current_charges -= 1
			if passive.current_charges <= 0:
				remove_passive(passive)
	
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
## МОДИФИКАТОР ИСХОДЯЩЕГО УРОНА
## ============================================================

func get_damage_multiplier() -> float:
	var multiplier = 1.0
	multiplier *= get_modifier(DataManager.ModifierStat.DAMAGE_DEALT_PERCENT)
	
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


## ============================================================
## БОНУС ОТ СИЛЫ (STRENGTH)
## ============================================================

func get_strength_bonus() -> int:
	return get_status_stacks(DataManager.Status.STRENGTH)


func set_energy(value: int):
	modify_flat(DataManager.FlatStat.ENERGY, value - get_flat(DataManager.FlatStat.ENERGY))


func get_max_energy() -> int:
	return get_flat(DataManager.FlatStat.MAX_ENERGY)


func restore_energy():
	set_energy(get_max_energy())

func get_energy() -> int:
	return get_flat(DataManager.FlatStat.ENERGY)

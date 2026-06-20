# scripts/components/character_stats.gd
extends Node
class_name CharacterStats

## ============================================================
## БАЗОВЫЕ СТАТЫ (FLATS)
## ============================================================

var flats: Dictionary[DataManager.FlatStat, int] = {
	DataManager.FlatStat.HEALTH: 0,
	DataManager.FlatStat.MAX_HEALTH: 0,
	DataManager.FlatStat.ENERGY: 0,
	DataManager.FlatStat.MAX_ENERGY: 0,
	#DataManager.FlatStat.BLOCK: 0,
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

var active_statuses: Dictionary = {}

## ============================================================
## ПАССИВКИ
## ============================================================

var active_passives: Array[PassiveResource] = []

## ============================================================
## ИММУНИТЕТЫ
## ============================================================

var immunity: Dictionary = {}

## ============================================================
## МЕТОДЫ ДОСТУПА К СТАТАМ
## ============================================================

func _init():
	_init_flat_stats()

func _init_flat_stats():
	pass

func get_flat(stat: DataManager.FlatStat) -> int:
	return flats.get(stat, 0)

func set_flat(stat: DataManager.FlatStat, value: int):
	# Ограничиваем здоровье
	if stat == DataManager.FlatStat.HEALTH:
		var max_health = get_flat(DataManager.FlatStat.MAX_HEALTH)
		flats[stat] = clamp(value, 0, max_health)
	else:
		flats[stat] = value
	_emit_flat_signal(stat)

func modify_flat(stat: DataManager.FlatStat, delta: int):
	var new_value = flats.get(stat, 0) + delta
	
	match stat:
		DataManager.FlatStat.HEALTH:
			var max_health = get_flat(DataManager.FlatStat.MAX_HEALTH)
			new_value = clamp(new_value, 0, max_health)
		
		DataManager.FlatStat.ATONEMENT:
			var max_atonement = get_flat(DataManager.FlatStat.MAX_ATONEMENT)
			new_value = clamp(new_value, 0, max_atonement)
		
		DataManager.FlatStat.ENERGY:
			var max_energy = get_flat(DataManager.FlatStat.MAX_ENERGY)
			new_value = clamp(new_value, 0, max_energy)
	
	flats[stat] = new_value
	_emit_flat_signal(stat)

func get_modifier(stat: DataManager.ModifierStat) -> float:
	return modifiers.get(stat, 1.0)

func modify_modifier(stat: DataManager.ModifierStat, delta: float, duration: int = 0):
	modifiers[stat] = modifiers.get(stat, 1.0) + delta
	if duration > 0:
		pass

## ============================================================
## СИГНАЛЫ ДЛЯ UI (через SignalManager)
## ============================================================

func _emit_flat_signal(stat: DataManager.FlatStat):
	match stat:
		DataManager.FlatStat.HEALTH:
			var current = get_flat(DataManager.FlatStat.HEALTH)
			var max_val = get_flat(DataManager.FlatStat.MAX_HEALTH)
			SignalManager.health_changed.emit(current, max_val)
			if self is EnemyInstance:
				SignalManager.enemy_health_changed.emit(self, current, max_val)
		
		DataManager.FlatStat.ENERGY:
			var current = get_flat(DataManager.FlatStat.ENERGY)
			var max_val = get_flat(DataManager.FlatStat.MAX_ENERGY)
			SignalManager.energy_changed.emit(current, max_val)
		
		#DataManager.FlatStat.BLOCK:
			#var current = get_flat(DataManager.FlatStat.BLOCK)
			#SignalManager.block_changed.emit(current)
		
		DataManager.FlatStat.ATONEMENT:
			var current = get_flat(DataManager.FlatStat.ATONEMENT)
			var max_val = get_flat(DataManager.FlatStat.MAX_ATONEMENT)
			SignalManager.atonement_changed.emit(current, max_val)

## ============================================================
## ЗДОРОВЬЕ, БЛОК, УРОН
## ============================================================

func get_health() -> int:
	return get_flat(DataManager.FlatStat.HEALTH)

func get_max_health() -> int:
	return get_flat(DataManager.FlatStat.MAX_HEALTH)

func get_block() -> int:
	return get_status_stacks(DataManager.Status.SHIELD)


func add_block(amount: int):
	var final_block = floor(amount * get_modifier(DataManager.ModifierStat.BLOCK_GAINED_PERCENT))
	if final_block > 0:
		var shield_status = DataManager.get_status_resource(DataManager.Status.SHIELD)
		add_status(shield_status, final_block, 1, self)  # на 1 ход

func take_damage(amount: int, ignore_block: bool = false, attacker: CharacterStats = null):
	var damage = amount
	
	if has_status(DataManager.Status.COLD):
		var cold_stacks = get_status_stacks(DataManager.Status.COLD)
		var cold_multiplier = 1.0 - (cold_stacks * DataManager.COLD_EFFECT_PERCENT_PER_STACK)
		damage *= max(cold_multiplier, DataManager.COLD_MIN_EFFECT_MULTIPLIER)
	
	damage = floor(damage)
	
	if not ignore_block and has_status(DataManager.Status.SHIELD):
		var shield_stacks = get_status_stacks(DataManager.Status.SHIELD)
		if shield_stacks >= damage:
			reduce_status_stacks(DataManager.Status.SHIELD, damage)
			damage = 0
		else:
			reduce_status_stacks(DataManager.Status.SHIELD, shield_stacks)
			damage -= shield_stacks
	if self is PenitentStats:
		SignalManager.player_damage_dealt.emit(damage)
	if damage > 0:
		SignalManager.log_message.emit("%s получил %d урона" % [get_display_name(), damage])
		SignalManager.damage_dealt.emit(self, damage)
		SignalManager.get_hit.emit(self)
		if self is PenitentStats:
			SignalManager.player_took_damage.emit(damage)
			#SignalManager.player_damage_dealt.emit(damage)
		modify_flat(DataManager.FlatStat.HEALTH, -damage)
		on_take_damage_gain_resource(damage)
		_process_passive_triggers(DataManager.PassiveTrigger.ON_TAKE_DAMAGE, attacker)  # ← передаём атакующего, а не урон
		
	# Проверка смерти ВСЕГДА, даже если damage == 0
	if get_health() <= 0:
		_on_death()
	

func heal(amount: int):
	var final_heal = floor(amount * get_modifier(DataManager.ModifierStat.HEALING_RECEIVED_PERCENT))
	if final_heal <= 0:
		return
	
	var current_health = get_health()
	var max_health = get_max_health()
	
	# Если здоровье уже полное — не лечим и не показываем цифры
	if current_health >= max_health:
		return
	
	var new_health = min(current_health + final_heal, max_health)
	var actual_heal = new_health - current_health
	
	if actual_heal <= 0:
		return
	
	set_flat(DataManager.FlatStat.HEALTH, new_health)
	SignalManager.log_message.emit("%s восстановил %d здоровья" % [get_display_name(), actual_heal])
	SignalManager.heal_received.emit(self, actual_heal)


func on_take_damage_gain_resource(amount: int):
	pass

## ============================================================
## УПРАВЛЕНИЕ СТАТУСАМИ
## ============================================================

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
	
	SignalManager.status_added.emit(self, status_id, value, duration)
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	SignalManager.log_message.emit("Наложен %s: %d стаков на %d ходов" % [status.get_localized_name(), value, duration])

func remove_status(status_id: DataManager.Status):
	if not active_statuses.has(status_id):
		return
	
	var data = active_statuses[status_id]
	var status = data["resource"]
	active_statuses.erase(status_id)
	
	_remove_status_modifiers(status)
	StatusInteractionManager.on_status_removed(self, status_id)
	
	SignalManager.status_removed.emit(self, status_id)
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
	
	# Для TURN_BASED используем duration или starting_charges
	if instance.charge_type == DataManager.PassiveChargeType.TURN_BASED:
		if duration > 0:
			instance.current_charges = duration
		else:
			instance.current_charges = instance.starting_charges
	else:
		instance.current_charges = instance.starting_charges
	
	# Проверяем, есть ли уже такая пассивка
	for existing in active_passives:
		if existing.id == instance.id:
			# Для PERMANENT не стакаем
			if instance.charge_type == DataManager.PassiveChargeType.PERMANENT:
				return
			# Для всех остальных просто складываем заряды
			existing.current_charges += instance.current_charges
			return
	
	active_passives.append(instance)
	
	# Применяем модификаторы
	for mod in instance.modifiers:
		match mod.change_type:
			DataManager.ModifierChangeType.MULTIPLIER:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.value
			DataManager.ModifierChangeType.PERCENT:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) + mod.value
			DataManager.ModifierChangeType.FLAT_BONUS:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) + mod.value
	
	SignalManager.passive_added.emit(self, instance.id)


func remove_passive(passive: PassiveResource):
	var idx = active_passives.find(passive)
	if idx != -1:
		active_passives.remove_at(idx)
		
		for mod in passive.modifiers:
			match mod.change_type:
				DataManager.ModifierChangeType.MULTIPLIER:
					modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.value
				DataManager.ModifierChangeType.PERCENT:
					modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) - mod.value
				DataManager.ModifierChangeType.FLAT_BONUS:
					modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) - mod.value
		
		SignalManager.passive_removed.emit(self, passive.id)
		print("Passive removed: ", passive.get_localized_name())  # ← отладка


func _process_passive_triggers(trigger: DataManager.PassiveTrigger, attacker = null):
	for passive in active_passives:
		if passive.trigger == trigger and passive.is_active():
			for effect in passive.effects:
				var targets = []
				match effect.target:
					DataManager.EffectTarget.SELF:
						targets = [self]
					DataManager.EffectTarget.ANY:
						if attacker:
							targets = [attacker]
						else:
							targets = [self]
					_:
						targets = [self]
				
				EffectExecutor.execute(effect, self, targets, {}, passive)

## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	# Убираем тик статусов (он теперь в process_start_of_turn)
	# Оставляем только уменьшение длительности и удаление истекших статусов
	var statuses_to_remove = []
	
	for status_id in active_statuses.keys():
		var data = active_statuses[status_id]
		var status = data["resource"]
		
		# SHIELD не уменьшается в конце хода (снимается в начале)
		if status.id == DataManager.Status.SHIELD:
			continue
		
		# Уменьшаем длительность
		data.duration -= 1
		
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
## БОНУС ОТ СИЛЫ (STRENGTH)
## ============================================================

func get_strength_bonus() -> int:
	return get_status_stacks(DataManager.Status.STRENGTH)

func get_energy() -> int:
	return get_flat(DataManager.FlatStat.ENERGY)

func get_max_energy() -> int:
	return get_flat(DataManager.FlatStat.MAX_ENERGY)

func set_energy(value: int):
	modify_flat(DataManager.FlatStat.ENERGY, value - get_flat(DataManager.FlatStat.ENERGY))

func restore_energy():
	set_energy(get_max_energy())

func get_display_name() -> String:
	return name if name != "" else "Персонаж"

func _get_strength_status_resource() -> StatusResource:
	if DataManager.has_method("get_status_resource"):
		return DataManager.get_status_resource(DataManager.Status.STRENGTH)
	return null


func _update_immunity_timer():
	var to_remove = []
	for status_id in immunity.keys():
		immunity[status_id] -= 1
		if immunity[status_id] <= 0:
			to_remove.append(status_id)
	for status_id in to_remove:
		immunity.erase(status_id)


func apply_immunity(status_id: DataManager.Status, duration: int):
	immunity[status_id] = duration

func has_immunity(status_id: DataManager.Status) -> bool:
	return immunity.has(status_id) and immunity[status_id] > 0


func _on_death():
	SignalManager.log_message.emit("%s погиб!" % get_display_name())
	
	if self is EnemyInstance:
		SignalManager.enemy_died.emit(self)
	elif self is PenitentStats:
		SignalManager.player_died.emit(self)


func get_applied_statuses() -> Array:
	return active_statuses.keys()


func process_start_of_turn():
	# Снимаем SHIELD в начале хода
	if has_status(DataManager.Status.SHIELD):
		remove_status(DataManager.Status.SHIELD)
	var statuses_to_remove = []
	
	for status_id in active_statuses.keys():
		var data = active_statuses[status_id]
		var status = data["resource"]
		
		if status.is_ticking:
			data.turn_counter = data.get("turn_counter", 0) + 1
			
			if data.turn_counter >= status.tick_interval:
				if status.tick_effect:
					var tick_effect = status.tick_effect.duplicate_for_instance()
					var caster = data.get("caster", null)
					
					# Вычисляем значение тика
					var tick_value = status.get_tick_value(data.stacks, caster)
					
					# В зависимости от категории эффекта
					match tick_effect.category:
						DataManager.EffectCategory.DAMAGE:
							tick_effect.base_value = tick_value
						DataManager.EffectCategory.HEAL:
							tick_effect.base_value = tick_value
						DataManager.EffectCategory.BLOCK:
							tick_effect.base_value = tick_value
						DataManager.EffectCategory.APPLY_STATUS:
							tick_effect.value = tick_value
						_:
							tick_effect.base_value = tick_value
					
					EffectExecutor.execute(tick_effect, self, [self])
				
				data.turn_counter = 0
			
			if status.id == DataManager.Status.BURN and data.stacks >= DataManager.BURN_THRESHOLD_STACKS:
				_trigger_burn_explosion(data.stacks)
				statuses_to_remove.append(status_id)
	
	for status_id in statuses_to_remove:
		remove_status(status_id)


func trigger_poison_immediately():
	if has_status(DataManager.Status.POISON):
		var stacks = get_status_stacks(DataManager.Status.POISON)
		var damage = stacks * DataManager.POISON_BASE_DAMAGE_PER_STACK
		take_damage(damage, true)
		remove_status(DataManager.Status.POISON)
		SignalManager.log_message.emit("Яд сработал мгновенно! %d урона" % damage)

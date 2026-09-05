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
	DataManager.FlatStat.HAND_SIZE: DataManager.STARTING_HAND_SIZE,
	DataManager.FlatStat.DRAW_PER_TURN: DataManager.CARDS_TO_DRAW_PER_TURN,
	DataManager.FlatStat.ATONEMENT: 0,
	DataManager.FlatStat.MAX_ATONEMENT: DataManager.PENITENT_MAX_ATONEMENT,
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
	
	# 🆕 Новые модификаторы
	DataManager.ModifierStat.DAMAGE_DEALT_DIRECT_PERCENT: 1.0,
	DataManager.ModifierStat.DAMAGE_DEALT_DOT_PERCENT: 1.0,
	DataManager.ModifierStat.DAMAGE_TAKEN_DIRECT_PERCENT: 1.0,
	DataManager.ModifierStat.DAMAGE_TAKEN_DOT_PERCENT: 1.0,

	# 🆕 Модификаторы статусов
	DataManager.ModifierStat.BURN_STACKS_MULTIPLIER: 1.0,
	DataManager.ModifierStat.POISON_STACKS_MULTIPLIER: 1.0,
	DataManager.ModifierStat.BLEED_STACKS_MULTIPLIER: 1.0,
	DataManager.ModifierStat.COLD_STACKS_MULTIPLIER: 1.0,
	
	DataManager.ModifierStat.BURN_DAMAGE_MULTIPLIER: 1.0,
	DataManager.ModifierStat.POISON_DAMAGE_MULTIPLIER: 1.0,
	DataManager.ModifierStat.BLEED_DAMAGE_MULTIPLIER: 1.0,
}

var is_direct_ignore_shield: bool = false
## ============================================================
## СТАТУСЫ
## ============================================================

var active_statuses: Dictionary = {}
var _frozen_statuses: Dictionary = {}  # сохранённые статусы на время заморозки
var status_application_order: Array = []  # порядок наложения статусов (для UI и взаимодействий)
## ============================================================
## ПАССИВКИ
## ============================================================

var active_passives: Array[PassiveResource] = []

var _frozen_at_turn_start: bool = false
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
			
		DataManager.FlatStat.MAX_HEALTH:
			var current = get_flat(DataManager.FlatStat.HEALTH)
			var max_val = get_flat(DataManager.FlatStat.MAX_HEALTH)
			SignalManager.health_changed.emit(current, max_val)
			if self is EnemyInstance:
				SignalManager.enemy_health_changed.emit(self, current, max_val)
		DataManager.FlatStat.MAX_ENERGY:  # 🆕
			var current = get_flat(DataManager.FlatStat.ENERGY)
			var max_val = get_flat(DataManager.FlatStat.MAX_ENERGY)
			SignalManager.energy_changed.emit(current, max_val)
		
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
		# 🆕 Звук получения щита
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.BLOCK))

func take_damage(amount: int, ignore_block: bool = false, attacker: CharacterStats = null, is_direct: bool = true, status_icon: Texture2D = null):    # Проверка на заморозку (если заморожена — урон не проходит)
	# Сохраняем состояние до применения урона
	var health_before = get_health()
	var max_health = get_max_health()
	var percent_before = (float(health_before) / max_health) * 100.0
	
	var damage = amount
	# Если заморожен — -50% урона
	if has_status(DataManager.Status.FROZEN):
		damage = floor(damage * 0.5)
		SignalManager.log_message.emit("%s заморожен! Урон снижен на 50%%." % get_display_name())

	if has_status(DataManager.Status.COLD):
		var cold_stacks = get_status_stacks(DataManager.Status.COLD)
		var cold_multiplier = 1.0 - (cold_stacks * RunManager.cold_effect_percent)
		if is_direct:
			damage *= max(cold_multiplier, RunManager.cold_min_multiplier)
	
	damage = floor(damage)

	# 🆕 Проверяем, должен ли урон игнорировать блок (Фатум)
	var should_ignore_block = ignore_block
	if is_direct and attacker and attacker.is_direct_ignore_shield:
		should_ignore_block = true

	if not should_ignore_block and has_status(DataManager.Status.SHIELD):
		var shield_stacks = get_status_stacks(DataManager.Status.SHIELD)
		if shield_stacks >= damage:
			modify_status_stacks(DataManager.Status.SHIELD, -damage)
			# TODO отобразить эффект удара в щит
			SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.BLOCK))
			if self is EnemyInstance:
				SignalManager.get_hit_in_shield.emit(self)
			elif self is PenitentStats:
				SignalManager.player_hit_in_shield.emit()
			damage = 0
		else:
			modify_status_stacks(DataManager.Status.SHIELD, -shield_stacks)
			damage -= shield_stacks
			
	# 🆕 Если есть статус BLISTER — урон идёт в пузырь
	if has_status(DataManager.Status.BLISTER):
		var status_data = active_statuses.get(DataManager.Status.BLISTER)
		if status_data and status_data.has("blister_data"):
			var blister_data = status_data["blister_data"]
			blister_data.current_health -= damage
			
			if blister_data.current_health <= 0:
				# Пузырь уничтожен — взрыв
				_explode_blister()
				return
			else:
				SignalManager.log_message.emit("Чёрный пузырь поглотил %d урона. Осталось %d прочности." % [damage, blister_data.current_health])
				return  # урон не проходит на цель
			
	if self is EnemyInstance:
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.ENEMY_GET_DAMAGE))
	if self is PenitentStats:
		SignalManager.player_damage_dealt.emit(damage, status_icon)
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.PLAYER_GET_DAMAGE))
	if damage > 0:
	# TODO эффекты
	# Визуальный эффект удара для игрока
		if self is PenitentStats:
			var portrait = GameTestManager.get_player_portrait()
			if portrait:
				portrait.apply_hit_effect()
		SignalManager.log_message.emit("%s получил %d урона" % [get_display_name(), damage])
		SignalManager.damage_dealt.emit(self, damage, status_icon)
		if is_direct:
			if damage > 0 and self is EnemyInstance:
				var enemy_ui = self.enemy_ui
				if enemy_ui:
					# Урон — среднее отталкивание
					enemy_ui.push_back()
		SignalManager.get_hit.emit(self)
		if self is PenitentStats:
			#if is_direct:
				SignalManager.player_took_damage.emit(damage)
			#SignalManager.player_damage_dealt.emit(damage)
		modify_flat(DataManager.FlatStat.HEALTH, -damage)
		
		# 🆕 Проверяем артефакты с триггером DAMAGE_THRESHOLD
		if not self is EnemyInstance:
			RunManager.process_artifact_on_damage_threshold(damage)
		
		# 🆕 Пассивки ON_TAKE_DIRECT_DAMAGE
		if is_direct and self and self.has_method("_process_passive_triggers"):
			# Проверяем, жив ли получатель урона
			if has_method("is_alive") and not is_alive():
				pass
			else:
				self._process_passive_triggers(DataManager.PassiveTrigger.ON_TAKE_DIRECT_DAMAGE, attacker)
		# Сохраняем состояние после применения урона
		var health_after = get_health()
		var percent_after = (float(health_after) / max_health) * 100.0
		
		# 🆕 Обрабатываем артефакты с триггером CONDITIONAL
		if self is PenitentStats:
			RunManager.process_health_dropped_below(health_before, health_after, percent_before, percent_after)
		
		on_take_damage_gain_resource(damage)
		_process_passive_triggers(DataManager.PassiveTrigger.ON_TAKE_DAMAGE, attacker)  # ← передаём атакующего, а не урон
		if damage > 0 and is_direct and attacker and is_instance_valid(attacker) and attacker.has_method("_process_passive_triggers"):
			# Проверяем, жив ли атакующий (если враг умер от отражённого урона — пассивка не срабатывает)
			# BUG 
			if attacker.has_method("is_alive") and not attacker.is_alive():
				pass
			else:
				attacker._process_passive_triggers(DataManager.PassiveTrigger.ON_DEAL_DIRECT_DAMAGE, self)
		
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
	
	# 🆕 Звук лечения
	SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.HEAL))
	
	SignalManager.log_message.emit("%s восстановил %d здоровья" % [get_display_name(), actual_heal])
	SignalManager.heal_received.emit(self, actual_heal)
	# Сигнал только для игрока (для UI)
	if self is PenitentStats:
		SignalManager.player_heal_received.emit(actual_heal)


func on_take_damage_gain_resource(amount: int):
	pass

## ============================================================
## УПРАВЛЕНИЕ СТАТУСАМИ
## ============================================================

func add_status(status: StatusResource, value: int, duration: int, caster: CharacterStats = null, passive_context: PassiveResource = null):
	if not status:
		return
	
	if has_status(DataManager.Status.FROZEN):
		SignalManager.log_message.emit("%s заморожен! Нельзя наложить статус." % get_display_name())
		return
	
	# 🆕 Проверяем все пассивки на блокировку статусов (вместо _check_denial)
	if _check_status_denial(status):
		return
	
	if not StatusInteractionManager.can_apply(self, status.id):
		return
	
	var status_id = status.id
	var stacks = value
	var dur = duration

	var multiplier = 1.0
	match status_id:
		DataManager.Status.BURN:
			multiplier = get_modifier(DataManager.ModifierStat.BURN_STACKS_MULTIPLIER)
		DataManager.Status.POISON:
			multiplier = get_modifier(DataManager.ModifierStat.POISON_STACKS_MULTIPLIER)
		DataManager.Status.BLEED:
			multiplier = get_modifier(DataManager.ModifierStat.BLEED_STACKS_MULTIPLIER)
		DataManager.Status.COLD:
			multiplier = get_modifier(DataManager.ModifierStat.COLD_STACKS_MULTIPLIER)

	stacks = floor(stacks * multiplier)

	# 🆕 Проверяем, если кастер — игрок, а цель — враг, и статус — BLEED
	if caster and not caster is EnemyInstance and self is EnemyInstance and status_id == DataManager.Status.BLEED:
		dur += RunManager.player_bleed_duration_bonus
	
	# 🆕 Сначала обрабатываем Burn ↔ Cold
	if status_id == DataManager.Status.BURN or status_id == DataManager.Status.COLD:
		var opposite = DataManager.Status.COLD if status_id == DataManager.Status.BURN else DataManager.Status.BURN
		if has_status(opposite):
			# Если есть противоположный статус — обрабатываем взаимодействие
			var result = StatusInteractionManager._handle_burn_cold(self, status_id, stacks, dur)
			# Если после взаимодействия не осталось стаков — выходим
			if result == 0:
				return
			# Иначе продолжаем с остатком
			stacks = result
			# Убираем противоположный статус (он уже обработан)
			remove_status(opposite)
	# 🆕 Звук применения дебаффа (если статус негативный и цель — враг)
	if DataManager.is_negative_status(status_id) and self is EnemyInstance:
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.APPLY_DEBUFF))
	# 🆕 Взаимодействия статусов (только НЕ для врагов)
	var can_use_interactions = not self is EnemyInstance
	
	# Проверяем наличие взаимодействия (только для игрока)
	if can_use_interactions and StatusInteractionManager.has_interaction(self, status_id):
		StatusInteractionManager.handle_interaction(self, status_id, stacks, dur, status, caster)
	else:
		_add_status_direct(status, stacks, dur, caster)

	if StatusInteractionManager.has_interaction(self, status_id):
		StatusInteractionManager.handle_interaction(self, status_id, stacks, dur, status, caster)
	else:
		_add_status_direct(status, stacks, dur, caster)


func _add_status_direct(status: StatusResource, stacks: int, duration: int, caster: CharacterStats = null, from_passive: bool = false):
	var status_id = status.id
	var existing = active_statuses.get(status_id)
	
	if existing:
		# 🆕 Разная логика стакания в зависимости от статуса
		match status_id:
			# Стакаются по стакам + макс длительность
			DataManager.Status.BLEED, DataManager.Status.COLD, DataManager.Status.BURN, DataManager.Status.REGEN:
				existing.stacks += stacks
				existing.duration = max(existing.duration, duration)
			
			# Стакаются только по длительности (стаки не меняются)
			DataManager.Status.POISON, DataManager.Status.WEAKNESS, DataManager.Status.VULNERABILITY, DataManager.Status.RESIN, DataManager.Status.COMBUSTIBLE:  # 🆕
				existing.duration += duration
				# Если duration стало больше, чем max_stacks — обрезаем
				if status.max_stacks > 0 and existing.duration > status.max_stacks:
					existing.duration = status.max_stacks
			
			# Стакаются только по стакам (длительность остаётся старая)
			DataManager.Status.GANGRENE, DataManager.Status.SHIELD, DataManager.Status.STRENGTH:
				existing.stacks += stacks
				# Длительность остаётся без изменений
			
			# Для всех остальных — стандартное поведение (стаки + макс длительность)
			_:
				existing.stacks += stacks
				existing.duration = max(existing.duration, duration)
	else:
		# Определяем, нужно ли пропустить первый тик
		var skip_first = false
		if not from_passive:
			skip_first = (caster == self and BattleManager.is_player_turn() and self is PenitentStats) or \
						 (caster == self and BattleManager.is_enemy_turn() and self is EnemyInstance)
		
		active_statuses[status_id] = {
			"stacks": stacks,
			"duration": duration,
			"resource": status,
			"caster": caster if caster else self,
			"tick_counter": 0,
			"skip_first_tick": skip_first
		}
		status_application_order.append(status_id)
		_apply_status_modifiers(status)
	
	# Визуальные эффекты
	if self is EnemyInstance and DataManager.is_negative_status(status_id):
		SignalManager.enemy_get_debuff.emit(self)
		SignalManager.something_get_debuff.emit(self)
	# Визуальные эффекты
	elif self is PenitentStats and DataManager.is_negative_status(status_id):
		SignalManager.player_get_debuff.emit()
		SignalManager.something_get_debuff.emit(self)
	
	# Проверка на заморозку (для COLD)
	if status_id == DataManager.Status.COLD:
		var total_stacks = get_status_stacks(DataManager.Status.COLD)
		if total_stacks >= RunManager.cold_freeze_threshold:
			_apply_freeze(caster)
			return
	
	# Сигналы
	SignalManager.status_added.emit(self, status_id, stacks, duration)
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
		if status_id == DataManager.Status.SHIELD:
			SignalManager.shield_recieved.emit(self, stacks)
	elif self is PenitentStats:
		SignalManager.player_status_changed.emit(self)
		if status_id == DataManager.Status.SHIELD:
			SignalManager.shield_recieved.emit(self, stacks)
	SignalManager.log_message.emit("Наложен %s: %d стаков на %d ходов" % [status.get_localized_name(), stacks, duration])
	
	# 🆕 Проверяем артефакты с триггером ADD_ACTION_WHEN_APPLY_CONCRETE_STATUS_TO_ENEMY
	# (после того, как статус реально наложен)
	if caster and not caster is EnemyInstance and self is EnemyInstance:
		RunManager.process_artifact_on_status_applied_to_enemy(status_id, caster)


func remove_status(status_id: DataManager.Status):
	if not active_statuses.has(status_id):
		return
	
	var data = active_statuses[status_id]
	var status = data["resource"]
	active_statuses.erase(status_id)
	status_application_order.erase(status_id)
	
	_remove_status_modifiers(status)
	
	SignalManager.status_removed.emit(self, status_id)
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	elif self is PenitentStats:
		SignalManager.player_status_changed.emit(self)

func has_status(status_id: DataManager.Status) -> bool:
	return active_statuses.has(status_id)

func get_status_stacks(status_id: DataManager.Status) -> int:
	var data = active_statuses.get(status_id)
	return data["stacks"] if data else 0

func modify_status_stacks(status_id: DataManager.Status, amount: int):
	if not active_statuses.has(status_id):
		return
	var data = active_statuses[status_id]
	data.stacks = max(0, data.stacks + amount)
	if data.stacks == 0:
		remove_status(status_id)

	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	elif self is PenitentStats:
		SignalManager.player_status_changed.emit(self)


func _apply_status_modifiers(status: StatusResource):
	# 🆕 Проверяем, есть ли уже такой статус (модификаторы уже применены)
	## BUG (статус уже есть в этот момент)
	#if active_statuses.has(status.id):
		#return
	
	for mod in status.modifiers:
		var final_value = mod.value
		
		match status.id:
			DataManager.Status.WEAKNESS:
				if mod.stat == DataManager.ModifierStat.DAMAGE_DEALT_PERCENT:
					final_value = RunManager.weakness_damage_multiplier - 1.0
			DataManager.Status.VULNERABILITY:
				if mod.stat == DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT:
					final_value = RunManager.vulnerability_damage_multiplier - 1.0
			DataManager.Status.POISON:
				if mod.stat == DataManager.ModifierStat.HEALING_RECEIVED_PERCENT:
					final_value = -RunManager.poison_healing_reduction
		
		match mod.change_type:
			DataManager.ModifierChangeType.MULTIPLIER:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) + final_value
			DataManager.ModifierChangeType.PERCENT:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) + final_value
			DataManager.ModifierChangeType.FLAT_BONUS:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) + final_value

func _remove_status_modifiers(status: StatusResource):
	for mod in status.modifiers:
		var final_value = mod.value
		
		match status.id:
			DataManager.Status.WEAKNESS:
				if mod.stat == DataManager.ModifierStat.DAMAGE_DEALT_PERCENT:
					final_value = RunManager.weakness_damage_multiplier - 1.0
			DataManager.Status.VULNERABILITY:
				if mod.stat == DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT:
					final_value = RunManager.vulnerability_damage_multiplier - 1.0
			DataManager.Status.POISON:
				if mod.stat == DataManager.ModifierStat.HEALING_RECEIVED_PERCENT:
					final_value = -RunManager.poison_healing_reduction
		
		match mod.change_type:
			DataManager.ModifierChangeType.MULTIPLIER:
				# 🆕 Вычитание вместо деления
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) - final_value
			DataManager.ModifierChangeType.PERCENT:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) - final_value
			DataManager.ModifierChangeType.FLAT_BONUS:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) - final_value

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
	
	if instance.charge_type == DataManager.PassiveChargeType.TURN_BASED:
		if duration > 0:
			instance.current_charges = duration
		else:
			instance.current_charges = instance.starting_charges
	else:
		instance.current_charges = instance.starting_charges
	
	for existing in active_passives:
		if existing.id == instance.id:
			if instance.charge_type == DataManager.PassiveChargeType.PERMANENT:
				return
			
			var has_growth = false
			for effect in existing.effects:
				if effect.grow_type != DataManager.GrowType.NONE:
					has_growth = true
					break
			
			if has_growth:
				existing.current_charges += instance.starting_charges
				existing.effect_application_counters.clear()
				for effect in existing.effects:
					effect.clear_instance_state()
				SignalManager.player_status_changed.emit(self)
				return
			
			existing.current_charges += instance.current_charges
			SignalManager.player_status_changed.emit(self)
			return
	
	active_passives.append(instance)
	
	# 🆕 Применяем модификаторы (сложение вместо умножения)
	for mod in instance.modifiers:
		var final_value = mod.value
		
		match instance.id:
			DataManager.Passive.SHAME:
				if mod.stat == DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT:
					final_value = RunManager.shame_damage_taken_multiplier - 1.0
				elif mod.stat == DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER:
					final_value = RunManager.shame_atonement_multiplier - 1.0
		
		match mod.change_type:
			DataManager.ModifierChangeType.MULTIPLIER:
				# 🆕 Сложение вместо умножения
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) + final_value
			DataManager.ModifierChangeType.PERCENT:
				modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) + final_value
			DataManager.ModifierChangeType.FLAT_BONUS:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) + final_value
	
	SignalManager.passive_added.emit(self, instance.id)
	SignalManager.player_status_changed.emit(self)


func remove_passive(passive: PassiveResource):
	var idx = active_passives.find(passive)
	if idx != -1:
		active_passives.remove_at(idx)
		
		# 🆕 Снимаем модификаторы (вычитание вместо деления)
		for mod in passive.modifiers:
			var final_value = mod.value
			
			match passive.id:
				DataManager.Passive.SHAME:
					if mod.stat == DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT:
						final_value = RunManager.shame_damage_taken_multiplier - 1.0
					elif mod.stat == DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER:
						final_value = RunManager.shame_atonement_multiplier - 1.0
			
			match mod.change_type:
				DataManager.ModifierChangeType.MULTIPLIER:
					# 🆕 Вычитание вместо деления
					modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) - final_value
				DataManager.ModifierChangeType.PERCENT:
					modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) - final_value
				DataManager.ModifierChangeType.FLAT_BONUS:
					modifiers[mod.stat] = modifiers.get(mod.stat, 0.0) - final_value
		
		SignalManager.passive_removed.emit(self, passive.id)
		SignalManager.passive_removed.emit(self, passive.id)
		print("Passive removed: ", passive.get_localized_name())
		SignalManager.player_status_changed.emit(self)


func _process_passive_triggers(trigger: DataManager.PassiveTrigger, attacker = null):
	for passive in active_passives:
		var enemy : EnemyInstance = self as EnemyInstance
		if enemy and not enemy.is_alive():
			return
		if passive.trigger == trigger and passive.is_active():
			# Анимируем иконку пассивки у врага
			if self is EnemyInstance:
				var enemy_ui = self.enemy_ui
				if enemy_ui:
					var icon = enemy_ui.find_passive_icon(passive.id)
					if icon:
						icon.animate()
			elif self is PenitentStats:
				var portrait = GameTestManager.get_player_portrait()
				if portrait:
					var icon = portrait.find_passive_icon(passive.id)
					if icon:
						icon.animate()
			
			for effect in passive.effects:
				var targets = []
				var is_enemy = self is EnemyInstance
				
				match effect.target:
					DataManager.EffectTarget.SELF:
						targets = [self]
					
					DataManager.EffectTarget.ENEMY:
						if is_enemy:
							# Враг → атакует игрока
							if attacker:
								targets = [attacker]
						else:
							# Игрок → атакует врага
							if attacker:
								targets = [attacker]
					
					DataManager.EffectTarget.ALL_ENEMIES:
						if is_enemy:
							# Враг → атакует игрока
							if attacker:
								targets = [attacker]
						else:
							# Игрок → все враги
							targets = BattleManager.get_enemies()
					
					DataManager.EffectTarget.ALL_ALLIES:
						if is_enemy:
							# Враг → все враги
							targets = BattleManager.get_enemies()
						else:
							# Игрок → сам себя
							targets = [self]
					
					DataManager.EffectTarget.ANY:
						if is_enemy:
							# Враг → все враги + атакующий (игрок)
							targets = BattleManager.get_enemies()
							if attacker and attacker not in targets:
								targets.append(attacker)
						else:
							# Игрок → все враги + сам себя
							targets = BattleManager.get_enemies()
							targets.append(self)
					
					_:
						targets = [self]
				
				EffectExecutor.execute(effect, self, targets, {}, passive)
				
			# 🆕 Уменьшаем заряды для USAGE_BASED пассивок
			if passive.charge_type == DataManager.PassiveChargeType.USAGE_BASED:
				passive.consume_charge()
				if passive.current_charges <= 0:
					remove_passive(passive)
					# Обновляем UI
				if self is PenitentStats:
					SignalManager.player_status_changed.emit(self)
				elif self is EnemyInstance:
					SignalManager.passive_changed.emit(self, passive.id)
			
			await Engine.get_main_loop().create_timer(DataManager.STATUS_TRIGGER_DELAY).timeout
		# BUG Здесь нужно проверить, как уходят чарджи - в некоторых случаях есть баг

## ============================================================
## КОНЕЦ ХОДА
## ============================================================

func process_end_of_turn():
	# Если заморожен — размораживаем и выходим (ничего не уменьшаем)
	if has_status(DataManager.Status.FROZEN):
		# Размораживаем ТОЛЬКО если:
		# 1. Это не игрок (враг) → всегда размораживаем
		# 2. ИЛИ это игрок и заморозка была в начале хода
		# BUG с заморозкой
		if self is EnemyInstance:
			thaw()
			_frozen_at_turn_start = false
			return
		elif self is PenitentStats:
			if _frozen_at_turn_start:
				_frozen_at_turn_start = false
				return
			else:
				thaw()
				_frozen_at_turn_start = false
				return
	# ✅ ШАГ 1: Сначала пассивки ON_TURN_END
	_process_passive_triggers(DataManager.PassiveTrigger.ON_TURN_END)
	
	# 🆕 УМЕНЬШАЕМ ЗАРЯДЫ ВСЕХ TURN_BASED ПАССИВОК В КОНЦЕ ХОДА (КРОМЕ ON_TURN_START)
	var passives_to_remove = []
	for passive in active_passives:
		if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.trigger != DataManager.PassiveTrigger.ON_TURN_START and passive.current_charges > 0:
			passive.current_charges -= 1
			if passive.current_charges <= 0:
				passives_to_remove.append(passive)
	
	for passive in passives_to_remove:
		remove_passive(passive)
	
	# 🆕 Эмитим сигнал для обновления UI
	for passive in active_passives:
		if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.trigger == DataManager.PassiveTrigger.ON_TURN_END:
			SignalManager.passive_changed.emit(self, passive.id)
	
	_update_immunity_timer()
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	elif self is PenitentStats:
		SignalManager.player_status_changed.emit(self)

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
	return get_status_stacks(DataManager.Status.STRENGTH) * RunManager.strength_bonus_per_stack

func get_energy() -> int:
	return get_flat(DataManager.FlatStat.ENERGY)

func get_max_energy() -> int:
	return get_flat(DataManager.FlatStat.MAX_ENERGY)

func set_energy(value: int):
	modify_flat(DataManager.FlatStat.ENERGY, value - get_flat(DataManager.FlatStat.ENERGY))

func restore_energy():
	set_energy(get_max_energy())

func gain_energy(amount: int):
	set_energy(get_flat(DataManager.FlatStat.ENERGY) + amount)

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
	
	if self is PenitentStats:
		# 🆕 Сохраняем игру с флагом is_run_ended = true
		SaveManager.save_game_with_run_ended()
		GameTestManager.clear_ui_after_death()
		var portrait = GameTestManager.get_player_portrait()
		if portrait:
			portrait.die()
		# 🆕 Создаём DeathUI через GameTestManager
		GameTestManager.create_death_ui()
		SignalManager.player_died.emit(self)
	elif self is EnemyInstance:
		SignalManager.enemy_died.emit(self)


func get_applied_statuses() -> Array:
	return active_statuses.keys()


func process_start_of_turn():
	await Engine.get_main_loop().create_timer(0.5).timeout
	# 🆕 Сбрасываем флаг Фатума в начале хода (до активации пассивок)
	is_direct_ignore_shield = false
	# Если заморожен — статусы не тикают
	if not has_status(DataManager.Status.FROZEN):
		# Снимаем STRENGTH в самом конце (после всех тиков)
		if has_status(DataManager.Status.STRENGTH):
			remove_status(DataManager.Status.STRENGTH)
		
		# ✅ ШАГ 1: Сначала пассивки ON_TURN_START
		await _process_passive_triggers(DataManager.PassiveTrigger.ON_TURN_START)
		
		# 🆕 УМЕНЬШАЕМ ЗАРЯДЫ TURN_BASED ПАССИВОК С ТРИГГЕРОМ ON_TURN_START
		var passives_to_remove = []
		for passive in active_passives:
			if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.trigger == DataManager.PassiveTrigger.ON_TURN_START and passive.current_charges > 0:
				passive.current_charges -= 1
				if passive.current_charges <= 0:
					passives_to_remove.append(passive)
		
		for passive in passives_to_remove:
			remove_passive(passive)
		
		# 🆕 Эмитим сигнал для обновления UI
		for passive in active_passives:
			if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.trigger == DataManager.PassiveTrigger.ON_TURN_START:
				SignalManager.passive_changed.emit(self, passive.id)
		
		for passive in passives_to_remove:
			remove_passive(passive)
		
		# ✅ ШАГ 3: Теперь обрабатываем статусы
		var statuses_to_remove = []
		var status_keys = active_statuses.keys()
		
		for status_id in status_keys:
			var enemy : EnemyInstance = self as EnemyInstance
			if enemy and not enemy.is_alive():
				return
			if not active_statuses.has(status_id):
				continue
			
			var data = active_statuses[status_id]
			var status = data["resource"]
			
			if status.is_ticking:
				# 🆕 Проверяем, настал ли момент для тика
				var tick_counter = data.get("tick_counter", 0)
				var tick_interval = status.tick_interval if status.tick_interval > 0 else 1
				# Увеличиваем счётчик
				tick_counter += 1
				data["tick_counter"] = tick_counter
				
				# Проверяем, настал ли момент для тика
				var should_tick = tick_counter >= tick_interval
				if should_tick:
					# Сбрасываем счётчик
					data["tick_counter"] = 0
					if self is EnemyInstance:
						var enemy_ui = self.enemy_ui
						if enemy_ui:
							var icon = enemy_ui.find_status_icon(status_id)
							if icon:
								# BUG возможно нужно await
								icon.animate()
					elif self is PenitentStats:
						var portrait = GameTestManager.get_player_portrait()
						if portrait:
							var icon = portrait.find_status_icon(status_id)
							if icon:
								icon.animate()
				if status.tick_effect and should_tick:
					var tick_effect = status.tick_effect.duplicate_for_instance()
					var caster = data.get("caster", null)
					if not is_instance_valid(caster):
						caster = null
					
					# 🆕 Получаем значение тика
					# Для всех статусов используем get_tick_value()
					var tick_value = status.get_tick_value(data.stacks, caster)
					
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
					#BUG здесь тикает статус (после тика враг может быть мертв)
					var status_icon = DataManager.get_status_icon(status_id)
					EffectExecutor.execute(tick_effect, caster, [self], {}, null, tick_effect.is_direct_damage, status_icon, status.ignore_block)
					if self is EnemyInstance:
						await Engine.get_main_loop().create_timer(DataManager.STATUS_TRIGGER_DELAY).timeout
					elif self is PenitentStats:
						await Engine.get_main_loop().create_timer(DataManager.PLAYER_STATUS_TRIGGER_DELAY).timeout
				if status.id == DataManager.Status.BURN and data.stacks >= RunManager.burn_threshold_stacks:
					_trigger_burn_explosion(data.stacks)
					statuses_to_remove.append(status_id)
				# 🆕 Уменьшаем длительность (но не для SHIELD)
				if status.id != DataManager.Status.SHIELD and status.id != DataManager.Status.STRENGTH:
					data.duration -= 1
				
				if data.duration <= 0:
					statuses_to_remove.append(status_id)
		
		# Удаляем статусы после итерации
		for status_id in statuses_to_remove:
			if active_statuses.has(status_id):
				remove_status(status_id)
		# Снимаем SHIELD в самом конце (после всех тиков)
		if has_status(DataManager.Status.SHIELD):
			remove_status(DataManager.Status.SHIELD)
		
	if self is EnemyInstance:
		SignalManager.enemy_status_changed.emit(self)
	elif self is PenitentStats:
		# 🆕 Обрабатываем артефакты с триггером TURN_COUNT_START
		RunManager.process_artifacts_on_turn_start()
		SignalManager.player_status_changed.emit(self)


func trigger_poison_immediately():
	if has_status(DataManager.Status.POISON):
		var stacks = get_status_stacks(DataManager.Status.POISON)
		var damage = stacks * DataManager.POISON_BASE_DAMAGE_PER_STACK
		take_damage(damage, true, null, false)
		remove_status(DataManager.Status.POISON)
		SignalManager.log_message.emit("Яд сработал мгновенно! %d урона" % damage)


func _apply_freeze(caster: CharacterStats = null):
	remove_status(DataManager.Status.COLD)
	
	var frozen_status = DataManager.get_status_resource(DataManager.Status.FROZEN)
	if frozen_status:
		# 🆕 Определяем, был ли это ход игрока или врага
		if self is PenitentStats:
			var is_player_turn = BattleManager.is_player_turn()
			
			if is_player_turn:
				_frozen_at_turn_start = true
				# 🆕 Сжигаем всю энергию до нуля
				var current_energy = get_energy()
				if current_energy > 0:
					set_energy(0)
					SignalManager.log_message.emit("Заморозка сожгла всю энергию!")
			else:
				_frozen_at_turn_start = false
		
		add_status(frozen_status, 1, DataManager.FROZEN_DURATION, caster)
		
		# Визуальные эффекты
		if self is EnemyInstance:
			var enemy_ui = self.enemy_ui
			if enemy_ui:
				enemy_ui.apply_freeze_effect()
		elif self is PenitentStats:
			var portrait = GameTestManager.get_player_portrait()
			if portrait:
				portrait.apply_freeze_effect()
		
		SignalManager.log_message.emit("%s заморожен! Статусы приостановлены." % get_display_name())
		SignalManager.frozen_applied.emit(self)


func thaw():
	if not has_status(DataManager.Status.FROZEN):
		return
	_frozen_at_turn_start = false
	# Убираем визуальный эффект заморозки
	if self is EnemyInstance:
		var enemy_ui = self.enemy_ui
		if enemy_ui:
			enemy_ui.remove_freeze_effect()
	elif self is PenitentStats:
		var portrait = GameTestManager.get_player_portrait()
		if portrait:
			portrait.remove_freeze_effect()
	
	remove_status(DataManager.Status.FROZEN)
	
	SignalManager.log_message.emit("%s оттаял! Статусы возобновлены." % get_display_name())


#func _get_last_status(exclude_status: DataManager.Status = -1) -> int:
	#var order = status_application_order.duplicate()
	#if exclude_status != -1:
		#order.erase(exclude_status)
	#
	#if order.is_empty():
		#return -1
	#
	#return order[-1]


func _get_last_status(new_status: DataManager.Status) -> int:
	var order = status_application_order.duplicate()
	
	# Идём с конца массива (от последнего наложенного статуса)
	for i in range(order.size() - 1, -1, -1):
		var status_id = order[i]
		
		# Проверяем, может ли этот статус взаимодействовать с новым
		if _can_interact(status_id, new_status):
			return status_id
	
	# Если ни один статус не может взаимодействовать
	return -1

func add_status_by_id(status_id: DataManager.Status, stacks: int, duration: int):
	var status_resource = DataManager.get_status_resource(status_id)
	if status_resource:
		add_status(status_resource, stacks, duration, self)
	else:
		printerr("Status resource not found for id: ", status_id)


func clear_all_statuses():
	# Специальная обработка для FROZEN
	if has_status(DataManager.Status.FROZEN):
		_frozen_at_turn_start = false
	
	var statuses = active_statuses.keys()
	for status_id in statuses:
		remove_status(status_id)
	var passives = active_passives
	for passive in passives:
		remove_passive(passive)
	
	status_application_order.clear()


func _can_interact(status_a: DataManager.Status, status_b: DataManager.Status) -> bool:
	# Список всех возможных пар взаимодействий
	var interaction_pairs = [
		[DataManager.Status.BLEED, DataManager.Status.POISON],
		[DataManager.Status.POISON, DataManager.Status.BLEED],
		[DataManager.Status.POISON, DataManager.Status.BURN],
		[DataManager.Status.BURN, DataManager.Status.POISON],
		[DataManager.Status.BLEED, DataManager.Status.COLD],
		[DataManager.Status.COLD, DataManager.Status.BLEED],
		[DataManager.Status.BURN, DataManager.Status.COLD],
		[DataManager.Status.COLD, DataManager.Status.BURN],
	]
	
	for pair in interaction_pairs:
		if (status_a == pair[0] and status_b == pair[1]) or \
		   (status_a == pair[1] and status_b == pair[0]):
			return true
	
	return false


func _explode_blister():
	var status_data = active_statuses.get(DataManager.Status.BLISTER)
	if not status_data or not status_data.has("blister_data"):
		return
	
	var blister_data = status_data["blister_data"]
	var burn_stacks = blister_data.burn_stacks_on_create
	var poison_duration = blister_data.poison_duration_on_create
	var burn_amount = burn_stacks * poison_duration
	
	# Удаляем пузырь
	remove_status(DataManager.Status.BLISTER)
	
	# Определяем, кому наносить BURN
	var is_player = self is PenitentStats
	var targets: Array = []
	
	if is_player:
		# Если пузырь был на игроке — взрыв наносит BURN игроку
		targets = [self]
	else:
		# Если пузырь был на враге — все враги получают BURN
		targets = BattleManager.get_enemies()
	
	var burn_status = DataManager.get_status_resource(DataManager.Status.BURN)
	for target in targets:
		target.add_status(burn_status, burn_amount, 2, self)
	
	SignalManager.log_message.emit("Чёрный пузырь уничтожен! %d стаков Горения наложено!" % burn_amount)


func get_infection_damage() -> int:
	var status_data = active_statuses.get(DataManager.Status.INFECTION)
	if status_data and status_data.has("damage_per_stack"):
		return status_data["damage_per_stack"]
	return 1


## Проверяет, жив ли персонаж
func is_alive() -> bool:
	return get_health() > 0

# === НОВЫЕ МЕТОДЫ ДЛЯ МОДИФИКАТОРОВ ===

## Применяет модификаторы к прямому урону (исходящий)
func get_direct_damage_dealt_modifier() -> float:
	return modifiers.get(DataManager.ModifierStat.DAMAGE_DEALT_DIRECT_PERCENT, 1.0)

## Применяет модификаторы к урону от статусов (исходящий)
func get_dot_damage_dealt_modifier() -> float:
	return modifiers.get(DataManager.ModifierStat.DAMAGE_DEALT_DOT_PERCENT, 1.0)

## Применяет модификаторы к прямому урону (входящий)
func get_direct_damage_taken_modifier() -> float:
	return modifiers.get(DataManager.ModifierStat.DAMAGE_TAKEN_DIRECT_PERCENT, 1.0)

## Применяет модификаторы к урону от статусов (входящий)
func get_dot_damage_taken_modifier() -> float:
	return modifiers.get(DataManager.ModifierStat.DAMAGE_TAKEN_DOT_PERCENT, 1.0)


func _check_status_denial(status: StatusResource) -> bool:
	var status_id = status.id
	var is_negative = DataManager.is_negative_status(status_id)
	
	for passive in active_passives:
		if passive.deny_status_types.is_empty():
			continue
		
		var should_block = false
		for deny_type in passive.deny_status_types:
			match deny_type:
				DataManager.StatusDenyType.ALL:
					should_block = true
				DataManager.StatusDenyType.NEGATIVE:
					if is_negative:
						should_block = true
				DataManager.StatusDenyType.POSITIVE:
					if not is_negative:
						should_block = true
				_:
					if status_id == deny_type:
						should_block = true
		
		if not should_block:
			continue
		
		# Блокируем статус
		if passive.consume_charge():
			SignalManager.log_message.emit("%s заблокировал статус %s! (%d зарядов осталось)" % [passive.get_localized_name(), status.get_localized_name(), passive.current_charges])
			
			# 🆕 Анимируем иконку пассивки
			if self is EnemyInstance:
				var enemy_ui = self.enemy_ui
				if enemy_ui:
					var icon = enemy_ui.find_passive_icon(passive.id)
					if icon:
						icon.animate()
			elif self is PenitentStats:
				var portrait = GameTestManager.get_player_portrait()
				if portrait:
					var icon = portrait.find_passive_icon(passive.id)
					if icon:
						icon.animate()
			
			# Обрабатываем эффекты пассивки (если есть)
			if not passive.effects.is_empty():
				var is_enemy = self is EnemyInstance
				var attacker = null  # для ON_STATUS_DENIED атакующий не определён
				
				for effect in passive.effects:
					var targets = []
					
					match effect.target:
						DataManager.EffectTarget.SELF:
							targets = [self]
						
						DataManager.EffectTarget.ENEMY:
							if is_enemy:
								var player = BattleManager.get_player()
								if player:
									targets = [player]
							else:
								var enemies = BattleManager.get_enemies()
								if not enemies.is_empty():
									targets = [enemies[0]]
						
						DataManager.EffectTarget.ALL_ENEMIES:
							if is_enemy:
								var player = BattleManager.get_player()
								if player:
									targets = [player]
							else:
								targets = BattleManager.get_enemies()
						
						DataManager.EffectTarget.ALL_ALLIES:
							if is_enemy:
								targets = BattleManager.get_enemies()
							else:
								targets = [self]
						
						DataManager.EffectTarget.ANY:
							if is_enemy:
								targets = BattleManager.get_enemies()
								var player = BattleManager.get_player()
								if player and player not in targets:
									targets.append(player)
							else:
								targets = BattleManager.get_enemies()
								targets.append(self)
						
						_:
							targets = [self]
					
					EffectExecutor.execute(effect, self, targets, {}, passive)
			
			# Выполняем кастомную логику, если есть
			if passive.custom_logic_script:
				var logic_instance = passive.custom_logic_script.new()
				if logic_instance.has_method("on_status_denied"):
					logic_instance.on_status_denied(passive, self, status)
			
			# Если заряды кончились — удаляем пассивку
			if not passive.is_active():
				remove_passive(passive)
			
			# Обновляем UI
			if self is PenitentStats:
				SignalManager.player_status_changed.emit(self)
			elif self is EnemyInstance:
				SignalManager.passive_changed.emit(self, passive.id)
			
			return true
	
	return false


func _get_targets_for_effect(effect: EffectEntry, source, targets: Array = []) -> Array:
	var result: Array = []
	var is_source_enemy = source is EnemyInstance
	
	match effect.target:
		DataManager.EffectTarget.SELF:
			result = [source]
		
		DataManager.EffectTarget.ENEMY:
			if is_source_enemy:
				# Враг атакует игрока
				if not targets.is_empty() and targets[0] is PenitentStats:
					result = [targets[0]]
				else:
					var player = BattleManager.get_player()
					if player:
						result = [player]
			else:
				# Игрок атакует врага
				if not targets.is_empty() and targets[0] is EnemyInstance:
					result = [targets[0]]
				else:
					var enemies = BattleManager.get_enemies()
					if not enemies.is_empty():
						result = [enemies[0]]
		
		DataManager.EffectTarget.ALL_ENEMIES:
			if is_source_enemy:
				# Враг атакует всех врагов (но у игрока один персонаж)
				var player = BattleManager.get_player()
				if player:
					result = [player]
			else:
				# Игрок атакует всех врагов
				result = BattleManager.get_enemies()
		
		DataManager.EffectTarget.ALL_ALLIES:
			if is_source_enemy:
				# Союзники врага — все враги
				result = BattleManager.get_enemies()
			else:
				# Союзники игрока — сам игрок
				result = [source]
		
		DataManager.EffectTarget.ANY:
			var all: Array = []
			var enemies = BattleManager.get_enemies()
			var player = BattleManager.get_player()
			
			if not enemies.is_empty():
				all.append_array(enemies)
			if player:
				all.append(player)
			result = all
		
		_:
			result = [source]
	
	return result


func get_status_index(status_id: DataManager.Status) -> int:
	return status_application_order.find(status_id)

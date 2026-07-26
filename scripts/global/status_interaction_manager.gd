# status_interaction_manager.gd
extends Node

## ============================================================
## ГЛОБАЛЬНЫЙ МЕНЕДЖЕР ВЗАИМОДЕЙСТВИЯ СТАТУСОВ
## ============================================================
## Отвечает за:
## - проверку возможности наложения статусов (исключающие пары)
## - обработку взаимодействий при наложении (яд ↔ кровотечение, огонь ↔ холод)
## - управление иммунитетом
## ============================================================


## ============================================================
## ПРОВЕРКА НАЛОЖЕНИЯ
## ============================================================

func can_apply(target, new_status: DataManager.Status) -> bool:
	if target.has_immunity(new_status):
		return false
	
	var current_statuses = target.get_applied_statuses()
	
	# Огонь (Burn) и Холод (Cold) не могут быть вместе
	if new_status == DataManager.Status.BURN:
		if DataManager.Status.COLD in current_statuses:
			return false
	
	if new_status == DataManager.Status.COLD:
		if DataManager.Status.BURN in current_statuses:
			return false
	
	return true


## ============================================================
## ОБРАБОТКА ВЗАИМОДЕЙСТВИЙ
## ============================================================
## ============================================================
## ОБРАБОТКА СНЯТИЯ СТАТУСОВ
## ============================================================


# StatusInteractionManager.gd

func handle_interaction(target, new_status: DataManager.Status, stacks: int, duration: int, status_resource: StatusResource, caster: CharacterStats = null):
	# 1. Получаем последний статус (уже без Burn/Cold, так как они обработаны до)
	var last_status = target._get_last_status(new_status)
	
	# 2. Если нет последнего статуса — просто накладываем
	if last_status == -1:
		target._add_status_direct(status_resource, stacks, duration, caster)
		return
	
	# 3. Обрабатываем взаимодействие по паре
	# Bleed + Poison → Мука (Bleed уже есть, Poison новый)
	if last_status == DataManager.Status.BLEED and new_status == DataManager.Status.POISON:
		_handle_bleed_poison_flour(target, stacks, duration)
		return
	
	# Poison + Bleed → Агония (Poison уже есть, Bleed новый)
	if last_status == DataManager.Status.POISON and new_status == DataManager.Status.BLEED:
		_handle_poison_bleed_agony(target, stacks, duration)
		return
	
	# Poison + Burn → Химический взрыв
	if (last_status == DataManager.Status.POISON and new_status == DataManager.Status.BURN) or \
	   (last_status == DataManager.Status.BURN and new_status == DataManager.Status.POISON):
		_handle_poison_burn_explosion(target, last_status, new_status, stacks)
		return
	
	# Bleed + Cold → Гангрена
	if (last_status == DataManager.Status.BLEED and new_status == DataManager.Status.COLD) or \
	   (last_status == DataManager.Status.COLD and new_status == DataManager.Status.BLEED):
		_handle_bleed_cold_gangrene(target, new_status, stacks, duration)
		return
	
	# 4. Если ни одно взаимодействие не подошло — просто накладываем
	target._add_status_direct(status_resource, stacks, duration, caster)


func _handle_burn_cold(target, new_status: DataManager.Status, stacks: int, duration: int) -> int:
	var opposite = DataManager.Status.COLD if new_status == DataManager.Status.BURN else DataManager.Status.BURN
	var opposite_stacks = target.get_status_stacks(opposite)
	var remaining = opposite_stacks - stacks
	
	if remaining > 0:
		target.modify_status_stacks(opposite, -stacks)
		SignalManager.log_message.emit("%s уменьшен на %d, осталось %d" % [DataManager.get_status_name(opposite), stacks, remaining])
		return 0  # новый статус полностью погашен
	else:
		target.remove_status(opposite)
		var left = abs(remaining)
		if left > 0:
			SignalManager.log_message.emit("%s полностью снят, наложен %s %d" % [DataManager.get_status_name(opposite), DataManager.get_status_name(new_status), left])
			return left  # возвращаем остаток нового статуса
		return 0


# ===== POISON + BURN (Химический взрыв) =====
func _handle_poison_burn_explosion(target, status_a: DataManager.Status, status_b: DataManager.Status, new_stacks: int):
	# Получаем стаки существующего статуса
	var existing_stacks = target.get_status_stacks(status_a)
	var poison_stacks = existing_stacks if status_a == DataManager.Status.POISON or status_b == DataManager.Status.POISON else target.get_status_stacks(DataManager.Status.POISON)
	var poison_duration = target.active_statuses.get(DataManager.Status.POISON, {}).get("duration", 0)
	
	# Удаляем оба статуса
	target.remove_status(DataManager.Status.POISON)
	target.remove_status(DataManager.Status.BURN)
	
	var damage = poison_stacks * poison_duration
	target.take_damage(damage, true)
	SignalManager.log_message.emit("Химический взрыв! %d урона." % damage)


# ===== BLEED + COLD (Гангрена) =====
func _handle_bleed_cold_gangrene(target, new_status: DataManager.Status, new_stacks: int, new_duration: int):
	# Берём стаки и длительность BLEED
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var bleed_duration = target.active_statuses.get(DataManager.Status.BLEED, {}).get("duration", 0)
	
	# Берём стаки и длительность COLD
	var cold_stacks = target.get_status_stacks(DataManager.Status.COLD)
	var cold_duration = target.active_statuses.get(DataManager.Status.COLD, {}).get("duration", 0)
	
	# Если новый статус — BLEED, используем переданные значения
	if new_status == DataManager.Status.BLEED:
		bleed_stacks = new_stacks
		bleed_duration = new_duration
	
	# Если новый статус — COLD, используем переданные значения
	if new_status == DataManager.Status.COLD:
		cold_stacks = new_stacks
		cold_duration = new_duration
	
	var gangrene_stacks = bleed_stacks * cold_stacks * DataManager.GANGRENE_MULTIPLIER
	var gangrene_duration = floor((bleed_duration + cold_duration) / DataManager.GANGRENE_DURATION_DIVIDER)
	
	target.remove_status(DataManager.Status.BLEED)
	target.remove_status(DataManager.Status.COLD)
	
	var gangrene_status = DataManager.get_status_resource(DataManager.Status.GANGRENE)
	if gangrene_status:
		# 🆕 Настраиваем статус перед наложением
		var tick_effect = EffectEntry.new()
		tick_effect.category = DataManager.EffectCategory.DAMAGE
		tick_effect.base_value = gangrene_stacks  # урон = количество стаков
		tick_effect.target = DataManager.EffectTarget.SELF
		
		# Копируем ресурс и переопределяем параметры
		var status_copy = gangrene_status.duplicate_for_instance()
		status_copy.is_ticking = true
		status_copy.tick_interval = gangrene_duration  # тикнет один раз в конце длительности
		status_copy.tick_effect = tick_effect
		
		# Накладываем настроенный статус
		target._add_status_direct(status_copy, gangrene_stacks, gangrene_duration, target)
		SignalManager.log_message.emit("Гангрена! %d стаков на %d ходов." % [gangrene_stacks, gangrene_duration])

# ===== ВЗАИМОДЕЙСТВИЯ СТАТУСОВ =====

func _handle_bleed_poison_flour(target, stacks: int, duration: int):
	# Bleed + Poison → Мука: Bleed стаки += длительность Poison / 3
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var added_stacks = floor(duration / DataManager.BLEED_POISON_FLOUR_DIVIDER)
	target.modify_status_stacks(DataManager.Status.BLEED, added_stacks)
	
	# Poison НАКЛАДЫВАЕТСЯ
	var poison_status = DataManager.get_status_resource(DataManager.Status.POISON)
	if poison_status:
		target._add_status_direct(poison_status, stacks, duration, target)
	
	SignalManager.log_message.emit("Кровь смешалась с ядом! Кровотечение +%d стаков, наложен Яд." % added_stacks)


func _handle_poison_bleed_agony(target, stacks: int, duration: int):
	# Poison + Bleed → Агония: Poison длительность += Bleed стаки × 3
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var added_duration = bleed_stacks * DataManager.POISON_BLEED_AGONY_MULTIPLIER
	var poison_data = target.active_statuses.get(DataManager.Status.POISON)
	if poison_data:
		poison_data.duration += added_duration
	
	# Bleed НАКЛАДЫВАЕТСЯ
	var bleed_status = DataManager.get_status_resource(DataManager.Status.BLEED)
	if bleed_status:
		target._add_status_direct(bleed_status, stacks, duration, target)
	
	SignalManager.log_message.emit("Яд усилился от крови! Длительность яда +%d ходов, наложено Кровотечение." % added_duration)


func has_interaction(target, new_status: DataManager.Status) -> bool:
	# Получаем последний статус
	var last_status = target._get_last_status(new_status)
	if last_status == -1:
		return false
	
	# Проверяем пары взаимодействий с учётом флагов
	var pairs = [
		[DataManager.Status.BLEED, DataManager.Status.POISON, RunManager.is_bleed_poison_interaction_enabled],
		[DataManager.Status.POISON, DataManager.Status.BLEED, RunManager.is_bleed_poison_interaction_enabled],
		[DataManager.Status.POISON, DataManager.Status.BURN, RunManager.is_poison_burn_interaction_enabled],
		[DataManager.Status.BURN, DataManager.Status.POISON, RunManager.is_poison_burn_interaction_enabled],
		[DataManager.Status.BLEED, DataManager.Status.COLD, RunManager.is_bleed_cold_interaction_enabled],
		[DataManager.Status.COLD, DataManager.Status.BLEED, RunManager.is_bleed_cold_interaction_enabled],
	]
	
	for pair in pairs:
		if last_status == pair[0] and new_status == pair[1] and pair[2]:
			return true
	
	return false

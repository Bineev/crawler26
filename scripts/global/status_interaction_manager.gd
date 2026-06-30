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

func on_status_removed(target, removed_status: DataManager.Status):
	if removed_status == DataManager.Status.COLD:
		if DataManager.Status.POISON in target.get_applied_statuses():
			target.unfreeze_poison()


func on_status_applied(target, new_status: DataManager.Status, stacks: int, duration: int):
	# 1. Контр-статусы (Burn ↔ Cold) — всегда первыми
	if new_status == DataManager.Status.BURN or new_status == DataManager.Status.COLD:
		_handle_burn_cold_interaction(target, new_status, stacks, duration)
		return
	
	# 2. Получаем последний статус в цепочке (кроме нового)
	var last_status = target._get_last_status(new_status)  # ← вызываем у target
	
	if last_status == null:
		target.add_status(new_status, stacks, duration)
		return
	
	# 3. Обрабатываем взаимодействие с последним статусом
	_handle_interaction(target, new_status, last_status, stacks, duration)


func _handle_interaction(target, new_status: DataManager.Status, last_status: DataManager.Status, stacks: int, duration: int):
	# Bleed + Poison → Мука (Bleed уже есть, Poison новый)
	if last_status == DataManager.Status.BLEED and new_status == DataManager.Status.POISON:
		_handle_bleed_poison_flour(target, stacks, duration)
		return
	
	# Poison + Bleed → Агония (Poison уже есть, Bleed новый)
	if last_status == DataManager.Status.POISON and new_status == DataManager.Status.BLEED:
		_handle_poison_bleed_agony(target, stacks, duration)
		return
	
	# Poison + Burn → Химический взрыв (независимо от порядка)
	if (last_status == DataManager.Status.POISON and new_status == DataManager.Status.BURN) or \
	   (last_status == DataManager.Status.BURN and new_status == DataManager.Status.POISON):
		_handle_poison_burn_explosion(target)
		return
	
	# Bleed + Cold → Гангрена (независимо от порядка)
	if (last_status == DataManager.Status.BLEED and new_status == DataManager.Status.COLD) or \
	   (last_status == DataManager.Status.COLD and new_status == DataManager.Status.BLEED):
		_handle_bleed_cold_gangrene(target)
		return
	
	# Если нет взаимодействий — просто накладываем статус
	target.add_status_by_id(new_status, stacks, duration)  # ← исправлено


func _handle_burn_cold_interaction(target, new_status: DataManager.Status, stacks: int, duration: int):
	var counter_status = DataManager.Status.COLD if new_status == DataManager.Status.BURN else DataManager.Status.BURN
	
	if target.has_status(counter_status):
		var counter_stacks = target.get_status_stacks(counter_status)
		var remaining = counter_stacks - stacks
		
		if remaining > 0:
			# Уменьшаем контр-статус
			target.modify_status_stacks(counter_status, -stacks)
			SignalManager.log_message.emit("%s уменьшен на %d, осталось %d" % [DataManager.get_status_name(counter_status), stacks, remaining])
		else:
			# Снимаем контр-статус полностью
			target.remove_status(counter_status)
			# Накладываем остаток нового статуса
			var left = abs(remaining)
			if left > 0:
				target.add_status_by_id(new_status, left, duration)
			SignalManager.log_message.emit("%s полностью снят, наложен %s %d" % [DataManager.get_status_name(counter_status), DataManager.get_status_name(new_status), left])
	else:
		# Нет контр-статуса — просто накладываем
		target.add_status_by_id(new_status, stacks, duration)


# ===== ВЗАИМОДЕЙСТВИЯ СТАТУСОВ =====

func _handle_bleed_poison_flour(target, stacks: int, duration: int):
	# Bleed + Poison → Мука: Bleed стаки += длительность Poison / 3
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var added_stacks = floor(duration / DataManager.BLEED_POISON_FLOUR_DIVIDER)
	target.modify_status_stacks(DataManager.Status.BLEED, added_stacks)
	SignalManager.log_message.emit("Кровь смешалась с ядом! Кровотечение +%d стаков." % added_stacks)


func _handle_poison_bleed_agony(target, stacks: int, duration: int):
	# Poison + Bleed → Агония: Poison длительность += Bleed стаки × 3
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var added_duration = bleed_stacks * DataManager.POISON_BLEED_AGONY_MULTIPLIER
	var current_poison_data = target.active_statuses.get(DataManager.Status.POISON)
	if current_poison_data:
		current_poison_data.duration += added_duration
	SignalManager.log_message.emit("Яд усилился от крови! Длительность яда +%d ходов." % added_duration)


func _handle_poison_burn_explosion(target):
	# Poison + Burn → Химический взрыв: оба исчезают, урон = стаки Poison × длительность Poison
	var poison_stacks = target.get_status_stacks(DataManager.Status.POISON)
	var poison_data = target.active_statuses.get(DataManager.Status.POISON)
	var poison_duration = poison_data.duration if poison_data else 0
	var damage = poison_stacks * poison_duration
	
	target.remove_status(DataManager.Status.POISON)
	target.remove_status(DataManager.Status.BURN)
	
	target.take_damage(damage, true)
	SignalManager.log_message.emit("Химический взрыв! %d урона." % damage)


func _handle_bleed_cold_gangrene(target):
	# Bleed + Cold → Гангрена: оба исчезают, создаётся Gangrene
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var cold_stacks = target.get_status_stacks(DataManager.Status.COLD)
	
	var bleed_data = target.active_statuses.get(DataManager.Status.BLEED)
	var cold_data = target.active_statuses.get(DataManager.Status.COLD)
	var bleed_duration = bleed_data.duration if bleed_data else 0
	var cold_duration = cold_data.duration if cold_data else 0
	
	var gangrene_stacks = bleed_stacks * cold_stacks * DataManager.GANGRENE_MULTIPLIER
	var gangrene_duration = floor((bleed_duration + cold_duration) / DataManager.GANGRENE_DURATION_DIVIDER)
	
	target.remove_status(DataManager.Status.BLEED)
	target.remove_status(DataManager.Status.COLD)
	
	var gangrene_status = DataManager.get_status_resource(DataManager.Status.GANGRENE)
	if gangrene_status:
		target.add_status(gangrene_status, gangrene_stacks, gangrene_duration, target)
		SignalManager.log_message.emit("Гангрена! %d стаков на %d ходов." % [gangrene_stacks, gangrene_duration])

# status_interaction_manager.gd
extends Node

## ============================================================
## ГЛОБАЛЬНЫЙ МЕНЕДЖЕР ВЗАИМОДЕЙСТВИЯ СТАТУСОВ
## ============================================================
## Отвечает за:
## - проверку возможности наложения статусов (исключающие пары)
## - обработку взаимодействий при наложении (яд ↔ кровотечение, огонь ↔ лёд)
## - управление иммунитетом
## ============================================================


## ============================================================
## ПРОВЕРКА НАЛОЖЕНИЯ
## ============================================================

## Проверяет, можно ли наложить статус на цель
## @param target: CharacterStats - цель, на которую пытаются наложить статус
## @param new_status: DataManager.Status - ID нового статуса
## @return bool - можно ли наложить
func can_apply(target, new_status: DataManager.Status) -> bool:
	# Проверка на иммунитет (если цель имеет иммунитет к статусу)
	if target.has_immunity(new_status):
		return false
	
	var current_statuses = target.get_applied_statuses()
	
	# === Исключающие пары ===
	
	# Огонь и лёд не могут быть вместе
	if new_status == DataManager.Status.BURN:
		if DataManager.Status.ICE in current_statuses:
			return false
	
	if new_status == DataManager.Status.ICE:
		if DataManager.Status.BURN in current_statuses:
			return false
	
	return true


## ============================================================
## ОБРАБОТКА ВЗАИМОДЕЙСТВИЙ
## ============================================================

## Обрабатывает взаимодействия после наложения статуса
## @param target: CharacterStats - цель, на которую наложили статус
## @param new_status: DataManager.Status - ID наложенного статуса
## @param stacks: int - количество стаков (для стакающихся статусов)
func on_status_applied(target, new_status: DataManager.Status, stacks: int = 0):
	var current_statuses = target.get_applied_statuses()
	
	# === Горение → Лёд (снимает 3 стака) ===
	if new_status == DataManager.Status.BURN:
		if DataManager.Status.ICE in current_statuses:
			target.reduce_status_stacks(DataManager.Status.ICE, 3)
	
	# === Яд → Кровотечение (снимает 1 стак) ===
	if new_status == DataManager.Status.POISON:
		if DataManager.Status.BLEED in current_statuses:
			target.reduce_status_stacks(DataManager.Status.BLEED, 1)
	
	# === Кровотечение → Яд (активация всего яда + иммунитет) ===
	if new_status == DataManager.Status.BLEED:
		if DataManager.Status.POISON in current_statuses:
			# Активировать весь яд
			target.trigger_poison_immediately()
			# Снять яд
			target.remove_status(DataManager.Status.POISON)
			# Дать иммунитет на 2 хода
			target.apply_immunity(DataManager.Status.POISON, 2)
			target.apply_immunity(DataManager.Status.BLEED, 2)
	
	# === Лёд замораживает действие Яда ===
	if new_status == DataManager.Status.ICE:
		if DataManager.Status.POISON in current_statuses:
			target.freeze_poison()   # Яд не тикает, пока есть лёд


## ============================================================
## ОБРАБОТКА СНЯТИЯ СТАТУСОВ
## ============================================================

## Обрабатывает взаимодействия при снятии статуса
## @param target: CharacterStats - цель, с которой сняли статус
## @param removed_status: DataManager.Status - ID снятого статуса
func on_status_removed(target, removed_status: DataManager.Status):
	# Если сняли лёд, разморозить яд
	if removed_status == DataManager.Status.ICE:
		if DataManager.Status.POISON in target.get_applied_statuses():
			target.unfreeze_poison()


## ============================================================
## ОБРАБОТКА ТИКОВ СТАТУСОВ
## ============================================================

## Обрабатывает тик статуса (вызывается в конце хода)
## @param target: CharacterStats - цель, у которой тикают статусы
## @param status: DataManager.Status - ID тикающего статуса
## @param stacks: int - текущее количество стаков
## @param damage: int - базовый урон за тик
func on_status_tick(target, status: DataManager.Status, stacks: int, damage: int):
	match status:
		DataManager.Status.POISON:
			# Стандартный тик яда
			target.take_damage(damage * stacks, true)  # ignore_block = true
		
		DataManager.Status.BLEED:
			# Стандартный тик кровотечения
			target.take_damage(damage * stacks, false)
		
		DataManager.Status.BURN:
			# Урон владельцу статуса
			target.take_damage(damage * stacks, false)
			
			# Проверка на взрыв
			if stacks >= DataManager.BURN_THRESHOLD_STACKS:
				_trigger_burn_explosion(target, stacks)
	
	# Если статус имеет специальную логику (например, регенерация), она обрабатывается отдельно


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

## Взрыв горения (наносит урон всем врагам)
func _trigger_burn_explosion(target, stacks: int):
	var explosion_damage = stacks * DataManager.BURN_EXPLOSION_DAMAGE_PER_STACK
	target.take_damage(explosion_damage, false)
	# Снимаем все стаки горения после взрыва
	target.remove_status(DataManager.Status.BURN)

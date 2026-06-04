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

func on_status_applied(target, new_status: DataManager.Status, stacks: int = 0):
	var current_statuses = target.get_applied_statuses()
	
	# Горение → Холод (снимает 3 стака)
	if new_status == DataManager.Status.BURN:
		if DataManager.Status.COLD in current_statuses:
			target.reduce_status_stacks(DataManager.Status.COLD, 3)
	
	# Яд → Кровотечение (снимает 1 стак)
	if new_status == DataManager.Status.POISON:
		if DataManager.Status.BLEED in current_statuses:
			target.reduce_status_stacks(DataManager.Status.BLEED, 1)
	
	# Кровотечение → Яд (активация всего яда + иммунитет)
	if new_status == DataManager.Status.BLEED:
		if DataManager.Status.POISON in current_statuses:
			target.trigger_poison_immediately()
			target.remove_status(DataManager.Status.POISON)
			target.apply_immunity(DataManager.Status.POISON, 2)
			target.apply_immunity(DataManager.Status.BLEED, 2)
	
	# Холод замораживает действие Яда
	if new_status == DataManager.Status.COLD:
		if DataManager.Status.POISON in current_statuses:
			target.freeze_poison()


## ============================================================
## ОБРАБОТКА СНЯТИЯ СТАТУСОВ
## ============================================================

func on_status_removed(target, removed_status: DataManager.Status):
	if removed_status == DataManager.Status.COLD:
		if DataManager.Status.POISON in target.get_applied_statuses():
			target.unfreeze_poison()

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
	
	if (last_status == DataManager.Status.BLEED and new_status == DataManager.Status.POISON) or \
	   (last_status == DataManager.Status.POISON and new_status == DataManager.Status.BLEED):
		_handle_bleed_poison_infection(target, last_status, new_status, stacks, duration)
		return
	
	# Poison + Burn → BLISTER
	if (last_status == DataManager.Status.POISON and new_status == DataManager.Status.BURN) or \
	   (last_status == DataManager.Status.BURN and new_status == DataManager.Status.POISON):
		_handle_poison_burn_blister(target, last_status, new_status, stacks, duration)
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

func has_interaction(target, new_status: DataManager.Status) -> bool:
	# Проверяем Bleed + Poison
	if RunManager.is_bleed_poison_interaction_enabled:
		if (new_status == DataManager.Status.BLEED and target.has_status(DataManager.Status.POISON)) or \
		   (new_status == DataManager.Status.POISON and target.has_status(DataManager.Status.BLEED)):
			return true
	
	# Проверяем Poison + Burn
	if RunManager.is_poison_burn_interaction_enabled:
		if (new_status == DataManager.Status.POISON and target.has_status(DataManager.Status.BURN)) or \
		   (new_status == DataManager.Status.BURN and target.has_status(DataManager.Status.POISON)):
			return true
	
	# Проверяем Bleed + Cold
	if RunManager.is_bleed_cold_interaction_enabled:
		if (new_status == DataManager.Status.BLEED and target.has_status(DataManager.Status.COLD)) or \
		   (new_status == DataManager.Status.COLD and target.has_status(DataManager.Status.BLEED)):
			return true
	
	return false


func _handle_poison_burn_blister(target, status_a: DataManager.Status, status_b: DataManager.Status, new_stacks: int, new_duration: int):
	# Получаем стаки и длительность обоих статусов
	var poison_stacks = target.get_status_stacks(DataManager.Status.POISON)
	var poison_duration = target.active_statuses.get(DataManager.Status.POISON, {}).get("duration", 0)
	var burn_stacks = target.get_status_stacks(DataManager.Status.BURN)
	
	# Если новый статус — BURN, используем переданные значения
	if status_b == DataManager.Status.BURN:
		burn_stacks = new_stacks
		poison_duration = new_duration
	elif status_b == DataManager.Status.POISON:
		poison_stacks = new_stacks
		poison_duration = new_duration
	
	# Удаляем оба статуса
	target.remove_status(DataManager.Status.POISON)
	target.remove_status(DataManager.Status.BURN)
	
	# Проверяем, есть ли уже BLISTER
	var existing_data = target.active_statuses.get(DataManager.Status.BLISTER)
	if existing_data and existing_data.has("blister_data"):
		var blister_data = existing_data["blister_data"]
		
		# Увеличиваем прочность
		var additional_health = burn_stacks * DataManager.BLISTER_DENSITY
		blister_data.max_health += additional_health
		blister_data.current_health += additional_health
		
		# Обновляем длительность (максимум)
		existing_data.duration = max(existing_data.duration, poison_duration)
		
		# Обновляем параметры взрыва
		blister_data.burn_stacks_on_create += burn_stacks
		blister_data.poison_duration_on_create = max(blister_data.poison_duration_on_create, poison_duration)
		
		SignalManager.log_message.emit("Чёрный пузырь усилился! Прочность: %d, Длительность: %d ходов." % [blister_data.current_health, existing_data.duration])
		return
	
	# Создаём новый BLISTER
	var blister_status = DataManager.get_status_resource(DataManager.Status.BLISTER)
	if blister_status:
		# Создаём копию статуса
		var status_copy = blister_status.duplicate_for_instance()
		status_copy.is_ticking = true
		status_copy.tick_interval = poison_duration  # тикнет один раз в конце
		
		# Создаём tick_effect для Блистера
		var tick_effect = EffectEntry.new()
		tick_effect.category = DataManager.EffectCategory.CUSTOM
		tick_effect.target = DataManager.EffectTarget.SELF
		tick_effect.custom_script = preload("res://scripts/effects/blister_explosion.gd")
		
		# Сохраняем параметры в эффекте
		tick_effect.value = burn_stacks * DataManager.BLISTER_DENSITY  # current_health
		tick_effect.base_value = burn_stacks * poison_duration  # burn_amount для взрыва
		tick_effect.amount = burn_stacks  # burn_stacks_on_create
		
		status_copy.tick_effect = tick_effect
		
		# Накладываем статус
		target._add_status_direct(status_copy, 1, poison_duration, target)
		
		# Сохраняем данные в активном статусе для поглощения урона
		var blister_data = {
			"max_health": burn_stacks * DataManager.BLISTER_DENSITY,
			"current_health": burn_stacks * DataManager.BLISTER_DENSITY,
			"burn_stacks_on_create": burn_stacks,
			"poison_duration_on_create": poison_duration,
		}
		var status_data = target.active_statuses.get(DataManager.Status.BLISTER)
		if status_data:
			status_data["blister_data"] = blister_data
		
		SignalManager.log_message.emit("Чёрный пузырь! Прочность: %d, Длительность: %d ходов." % [blister_data.max_health, poison_duration])


func _handle_bleed_poison_infection(target, status_a: DataManager.Status, status_b: DataManager.Status, new_stacks: int, new_duration: int):
	# Получаем стаки и длительность обоих статусов
	var bleed_stacks = target.get_status_stacks(DataManager.Status.BLEED)
	var bleed_duration = target.active_statuses.get(DataManager.Status.BLEED, {}).get("duration", 0)
	var poison_stacks = target.get_status_stacks(DataManager.Status.POISON)
	var poison_duration = target.active_statuses.get(DataManager.Status.POISON, {}).get("duration", 0)
	
	# Если новый статус — BLEED, используем переданные значения
	if status_b == DataManager.Status.BLEED:
		bleed_stacks = new_stacks
		bleed_duration = new_duration
	elif status_b == DataManager.Status.POISON:
		poison_stacks = new_stacks
		poison_duration = new_duration
	
	# Удаляем оба статуса
	target.remove_status(DataManager.Status.BLEED)
	target.remove_status(DataManager.Status.POISON)
	
	# Рассчитываем параметры Заражения
	var infection_stacks = 1
	var infection_duration = poison_duration
	var damage_per_stack = bleed_stacks * RunManager.infection_bleed_multiplier
	
	# Проверяем, есть ли уже Заражение
	var existing = target.active_statuses.get(DataManager.Status.INFECTION)
	if existing:
		# Стакаем: урон складывается, длительность — максимум
		var existing_damage = existing.get("damage_per_stack", 0)
		damage_per_stack += existing_damage
		infection_duration = max(infection_duration, existing.duration)
		
		# Обновляем существующий статус
		existing.stacks = infection_stacks
		existing.duration = infection_duration
		existing["damage_per_stack"] = damage_per_stack
		
		SignalManager.log_message.emit("Заражение усилилось! Урон за стак: %d, Длительность: %d ходов." % [damage_per_stack, infection_duration])
		return
	
	# Создаём новый статус
	var infection_status = DataManager.get_status_resource(DataManager.Status.INFECTION)
	if infection_status:
		target._add_status_direct(infection_status, infection_stacks, infection_duration, target)
		
		# Сохраняем дополнительные данные
		var status_data = target.active_statuses.get(DataManager.Status.INFECTION)
		if status_data:
			status_data["damage_per_stack"] = damage_per_stack
		
		SignalManager.log_message.emit("Заражение! Урон за стак: %d, Длительность: %d ходов." % [damage_per_stack, infection_duration])


func _get_last_status(target, new_status: DataManager.Status) -> int:
	# Массив: [статус, индекс_наложения]
	var interacting_statuses: Array = []
	
	# Проверяем все возможные взаимодействия
	if RunManager.is_bleed_poison_interaction_enabled:
		if new_status == DataManager.Status.BLEED and target.has_status(DataManager.Status.POISON):
			var index = _get_status_index(target, DataManager.Status.POISON)
			if index != -1:
				interacting_statuses.append([DataManager.Status.POISON, index])
		elif new_status == DataManager.Status.POISON and target.has_status(DataManager.Status.BLEED):
			var index = _get_status_index(target, DataManager.Status.BLEED)
			if index != -1:
				interacting_statuses.append([DataManager.Status.BLEED, index])
	
	if RunManager.is_poison_burn_interaction_enabled:
		if new_status == DataManager.Status.POISON and target.has_status(DataManager.Status.BURN):
			var index = _get_status_index(target, DataManager.Status.BURN)
			if index != -1:
				interacting_statuses.append([DataManager.Status.BURN, index])
		elif new_status == DataManager.Status.BURN and target.has_status(DataManager.Status.POISON):
			var index = _get_status_index(target, DataManager.Status.POISON)
			if index != -1:
				interacting_statuses.append([DataManager.Status.POISON, index])
	
	if RunManager.is_bleed_cold_interaction_enabled:
		if new_status == DataManager.Status.BLEED and target.has_status(DataManager.Status.COLD):
			var index = _get_status_index(target, DataManager.Status.COLD)
			if index != -1:
				interacting_statuses.append([DataManager.Status.COLD, index])
		elif new_status == DataManager.Status.COLD and target.has_status(DataManager.Status.BLEED):
			var index = _get_status_index(target, DataManager.Status.BLEED)
			if index != -1:
				interacting_statuses.append([DataManager.Status.BLEED, index])
	
	# Если нет взаимодействующих статусов — возвращаем -1
	if interacting_statuses.is_empty():
		return -1
	
	# Сортируем по индексу (от большего к меньшему) — последний наложенный
	interacting_statuses.sort_custom(func(a, b): return a[1] > b[1])
	
	# Возвращаем статус с самым высоким индексом
	return interacting_statuses[0][0]


func _get_status_index(target, status_id: DataManager.Status) -> int:
	if not target.has_method("get_status_index"):
		return -1
	return target.get_status_index(status_id)

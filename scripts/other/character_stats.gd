# scripts/components/character_stats.gd
extends Node
class_name CharacterStats

## ============================================================
## ОСНОВНЫЕ ХАРАКТЕРИСТИКИ
## ============================================================

## Базовые статы (flats)
var flats: Dictionary = {
	DataManager.FlatStat.HEALTH: 0,
	DataManager.FlatStat.MAX_HEALTH: 0,
	DataManager.FlatStat.ENERGY: 0,
	DataManager.FlatStat.MAX_ENERGY: 0,
	DataManager.FlatStat.BLOCK: 0,
	DataManager.FlatStat.HAND_SIZE: 5,
	DataManager.FlatStat.DRAW_PER_TURN: 5,
}

## Модификаторы (процентные и флэт-бонусы)
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

## Активные статусы (status_id -> {stacks, duration})
var active_statuses: Dictionary = {}


## ============================================================
## ПАССИВКИ
## ============================================================

## Активные пассивки (экземпляры PassiveResource)
var active_passives: Array[PassiveResource] = []


## ============================================================
## МЕТОДЫ ДОСТУПА К СТАТАМ
## ============================================================

## Получить значение флэт-стата
func get_flat(stat: DataManager.FlatStat) -> int:
	return flats.get(stat, 0)

## Установить флэт-стат
func set_flat(stat: DataManager.FlatStat, value: int):
	flats[stat] = value
	_emit_flat_signal(stat)

## Изменить флэт-стат
func modify_flat(stat: DataManager.FlatStat, delta: int):
	flats[stat] = flats.get(stat, 0) + delta
	_emit_flat_signal(stat)

## Получить модификатор (множитель)
func get_modifier(stat: DataManager.ModifierStat) -> float:
	return modifiers.get(stat, 1.0)

## Изменить модификатор
func modify_modifier(stat: DataManager.ModifierStat, delta: float, duration: int = 0):
	modifiers[stat] = modifiers.get(stat, 1.0) + delta
	# TODO: временные модификаторы (с таймером)


## ============================================================
## СИГНАЛЫ (через SignalManager)
## ============================================================

func _emit_flat_signal(stat: DataManager.FlatStat):
	match stat:
		DataManager.FlatStat.HEALTH:
			SignalManager.health_changed.emit(get_flat(DataManager.FlatStat.HEALTH), get_flat(DataManager.FlatStat.MAX_HEALTH))
		DataManager.FlatStat.MAX_HEALTH:
			SignalManager.max_health_changed.emit(get_flat(DataManager.FlatStat.MAX_HEALTH))
		DataManager.FlatStat.ENERGY:
			SignalManager.energy_changed.emit(get_flat(DataManager.FlatStat.ENERGY), get_flat(DataManager.FlatStat.MAX_ENERGY))
		DataManager.FlatStat.BLOCK:
			SignalManager.block_changed.emit(get_flat(DataManager.FlatStat.BLOCK))


## ============================================================
## ЗДОРОВЬЕ И БЛОК
## ============================================================

## Получить текущее здоровье
func get_health() -> int:
	return get_flat(DataManager.FlatStat.HEALTH)

## Получить максимальное здоровье
func get_max_health() -> int:
	return get_flat(DataManager.FlatStat.MAX_HEALTH)

## Получить блок
func get_block() -> int:
	return get_flat(DataManager.FlatStat.BLOCK)

## Добавить блок
func add_block(amount: int):
	var final_block = amount * get_modifier(DataManager.ModifierStat.BLOCK_GAINED_PERCENT)
	modify_flat(DataManager.FlatStat.BLOCK, floor(final_block))

## Получить урон
func take_damage(amount: int, ignore_block: bool = false):
	var final_damage = amount * get_modifier(DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT)
	var damage = floor(final_damage)
	
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
		
		# Получение классового ресурса (переопределяется в наследниках)
		var resource_gain = damage * get_modifier(DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER)
		on_take_damage_gain_resource(floor(resource_gain))
		
		# Обработка получения урона для пассивок
		_process_on_take_damage_triggers(damage)

## Лечение
func heal(amount: int):
	var final_heal = amount * get_modifier(DataManager.ModifierStat.HEALING_RECEIVED_PERCENT)
	var new_health = get_health() + floor(final_heal)
	set_flat(DataManager.FlatStat.HEALTH, min(new_health, get_max_health()))


## ============================================================
## КЛАССОВЫЙ РЕСУРС (переопределяется в наследниках)
## ============================================================

## Вызывается при получении урона для генерации классового ресурса
func on_take_damage_gain_resource(amount: int):
	# Базовый класс ничего не делает
	# Переопределяется в PenitentStats, WarriorStats и т.д.
	pass


## ============================================================
## СТАТУСЫ
## ============================================================

## Добавить статус
func add_status(status: StatusResource, value: int, duration: int, passive_context: PassiveResource = null):
	if not status:
		return
	
	# Проверка иммунитета (через пассивку DENIAL)
	if _check_denial(status):
		return
	
	var status_id = status.id
	
	if active_statuses.has(status_id):
		# Обновляем существующий статус
		var current = active_statuses[status_id]
		current.stacks += value
		current.duration = max(current.duration, duration)
		
		# Применяем модификаторы статуса (если есть)
		_apply_status_modifiers(status)
	else:
		# Новый статус
		active_statuses[status_id] = {"stacks": value, "duration": duration, "resource": status}
		
		# Применяем модификаторы статуса
		_apply_status_modifiers(status)
		
		# Обработка взаимодействия статусов
		StatusInteractionManager.on_status_applied(self, status_id, value)
	
	SignalManager.status_added.emit(status_id, value, duration)


## Удалить статус
func remove_status(status_id: DataManager.Status):
	if not active_statuses.has(status_id):
		return
	
	var status = active_statuses[status_id]["resource"]
	active_statuses.erase(status_id)
	
	# Убираем модификаторы статуса
	_remove_status_modifiers(status)
	
	# Обработка снятия статуса
	StatusInteractionManager.on_status_removed(self, status_id)
	
	SignalManager.status_removed.emit(status_id)


## Проверить наличие статуса
func has_status(status_id: DataManager.Status) -> bool:
	return active_statuses.has(status_id)


## Получить стаки статуса
func get_status_stacks(status_id: DataManager.Status) -> int:
	if not active_statuses.has(status_id):
		return 0
	return active_statuses[status_id]["stacks"]


## Применить модификаторы статуса
func _apply_status_modifiers(status: StatusResource):
	for mod in status.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) + mod.flat_bonus


## Убрать модификаторы статуса
func _remove_status_modifiers(status: StatusResource):
	for mod in status.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) - mod.flat_bonus


## Проверка иммунитета через пассивку DENIAL
func _check_denial(status: StatusResource) -> bool:
	for passive in active_passives:
		if passive.id == DataManager.Passive.DENIAL and passive.is_active():
			if DataManager.is_negative_status(status.id):
				passive.consume_charge()
				return passive.is_active()  # если заряды кончились, статус не блокируется
	return false


## ============================================================
## ПАССИВКИ
## ============================================================

## Добавить пассивку
func apply_passive(passive: PassiveResource, duration: int = -1):
	if not passive:
		return
	
	var instance = passive.duplicate_for_instance()
	instance.init_instance()
	
	# Для TURN_BASED устанавливаем заряды
	if instance.charge_type == DataManager.PassiveChargeType.TURN_BASED and duration > 0:
		instance.current_charges = duration
	
	active_passives.append(instance)
	
	# Применяем постоянные модификаторы
	for mod in instance.modifiers:
		modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) * mod.multiplier
		if mod.flat_bonus != 0:
			modifiers[mod.stat] = modifiers.get(mod.stat, 0) + mod.flat_bonus
	
	SignalManager.passive_added.emit(instance.id)


## Удалить пассивку
func remove_passive(passive: PassiveResource):
	var idx = active_passives.find(passive)
	if idx != -1:
		active_passives.remove_at(idx)
		
		# Убираем модификаторы
		for mod in passive.modifiers:
			modifiers[mod.stat] = modifiers.get(mod.stat, 1.0) / mod.multiplier
			if mod.flat_bonus != 0:
				modifiers[mod.stat] = modifiers.get(mod.stat, 0) - mod.flat_bonus
		
		SignalManager.passive_removed.emit(passive.id)


## Обработка триггера ON_TAKE_DAMAGE
func _process_on_take_damage_triggers(damage: int):
	for passive in active_passives:
		if passive.trigger == DataManager.PassiveTrigger.ON_TAKE_DAMAGE and passive.is_active():
			_execute_passive_effects(passive)


## Выполнить эффекты пассивки
func _execute_passive_effects(passive: PassiveResource):
	for effect in passive.effects:
		EffectExecutor.execute(effect, self, [self], {}, passive)


## ============================================================
## ТИК СТАТУСОВ (вызывается в конце хода)
## ============================================================

func process_end_of_turn():
	# Тик статусов
	for status_id in active_statuses.keys():
		var status_data = active_statuses[status_id]
		var status = status_data["resource"]
		
		if status.is_ticking:
			# Уменьшаем длительность
			status_data["duration"] -= 1
			
			# Наносим урон от статуса
			if status.tick_effect:
				# Создаём копию эффекта для тика
				var tick_effect = status.tick_effect.duplicate_for_instance()
				tick_effect.value = status.get_tick_damage(status_data["stacks"])
				EffectExecutor.execute(tick_effect, self, [self])
			
			# Удаляем, если длительность истекла
			if status_data["duration"] <= 0:
				remove_status(status_id)
	
	# Тик пассивок (уменьшение зарядов)
	for passive in active_passives:
		if passive.charge_type == DataManager.PassiveChargeType.TURN_BASED and passive.current_charges > 0:
			passive.current_charges -= 1
			if passive.current_charges <= 0:
				remove_passive(passive)
	
	# Триггер ON_TURN_END
	for passive in active_passives:
		if passive.trigger == DataManager.PassiveTrigger.ON_TURN_END and passive.is_active():
			_execute_passive_effects(passive)

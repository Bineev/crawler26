# scripts/components/penitent_stats.gd
extends CharacterStats
class_name PenitentStats

## ============================================================
## СПЕЦИФИЧЕСКИЕ ПЕРЕМЕННЫЕ
## ============================================================

var max_atonement: int = DataManager.PENITENT_MAX_ATONEMENT


## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

func _init():
	super._init()  # ← вызываем родительский _init
	# Устанавливаем максимальное Искупление
	set_flat(DataManager.FlatStat.MAX_ATONEMENT, max_atonement)
	set_flat(DataManager.FlatStat.ATONEMENT, 0)


func _init_flat_stats():
	flats[DataManager.FlatStat.HEALTH] = DataManager.PENITENT_STARTING_HEALTH
	flats[DataManager.FlatStat.MAX_HEALTH] = DataManager.PENITENT_STARTING_HEALTH
	flats[DataManager.FlatStat.ENERGY] = DataManager.STARTING_ENERGY
	flats[DataManager.FlatStat.MAX_ENERGY] = DataManager.MAX_ENERGY
	#flats[DataManager.FlatStat.BLOCK] = 0
	flats[DataManager.FlatStat.ATONEMENT] = 0
	flats[DataManager.FlatStat.MAX_ATONEMENT] = DataManager.PENITENT_MAX_ATONEMENT

## ============================================================
## МЕТОДЫ ДОСТУПА К ИСКУПЛЕНИЮ
## ============================================================

func get_atonement() -> int:
	return get_flat(DataManager.FlatStat.ATONEMENT)


func get_max_atonement() -> int:
	return get_flat(DataManager.FlatStat.MAX_ATONEMENT)


## ============================================================
## ПОЛУЧЕНИЕ TIER (для SCALED_VALUE эффектов)
## ============================================================

func get_atonement_tier() -> int:
	return get_atonement() / 10


## ============================================================
## ОПЕРАЦИИ С ИСКУПЛЕНИЕМ
## ============================================================

func gain_atonement(amount: int):
	modify_flat(DataManager.FlatStat.ATONEMENT, amount)


func spend_atonement(amount: int) -> bool:
	var current = get_atonement()
	if current >= amount:
		modify_flat(DataManager.FlatStat.ATONEMENT, -amount)
		return true
	return false


## ============================================================
## ПЕРЕОПРЕДЕЛЕНИЕ on_take_damage_gain_resource
## ============================================================

func on_take_damage_gain_resource(amount: int):
	# Получаем базовое количество Искупления за атаку
	var gain = DataManager.PENITENT_ATONEMENT_GAIN_PER_ATTACK
	
	# Учитываем модификатор (Shame и т.д.)
	var multiplier = get_modifier(DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER)
	gain = floor(gain * multiplier)
	
	if gain > 0:
		modify_flat(DataManager.FlatStat.ATONEMENT, gain)
		SignalManager.log_message.emit("Получено %d Искупления" % gain)

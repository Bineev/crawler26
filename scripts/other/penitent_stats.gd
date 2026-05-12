# scripts/components/penitent_stats.gd
extends CharacterStats
class_name PenitentStats

var atonement: int = 0
var max_atonement: int = 30

## Переопределяем метод получения ресурса
func on_take_damage_gain_resource(amount: int):
	gain_atonement(amount)

func gain_atonement(amount: int):
	atonement = min(atonement + amount, max_atonement)
	SignalManager.atonement_changed.emit(atonement, max_atonement)

func spend_atonement(amount: int) -> bool:
	if atonement >= amount:
		atonement -= amount
		SignalManager.atonement_changed.emit(atonement, max_atonement)
		return true
	return false

func get_atonement() -> int:
	return atonement

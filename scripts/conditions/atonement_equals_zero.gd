extends Node
class_name AtonementEqualsZero

## Проверяет, равно ли Искупление источника 0
func check(source: CharacterStats, targets: Array) -> bool:
	if not source:
		return false
	
	# Для игрока
	if source.has_method("get_atonement"):
		return source.get_atonement() == 0
	
	# Для любого персонажа с flat'ом
	if source.has_method("get_flat"):
		return source.get_flat(DataManager.FlatStat.ATONEMENT) == 0
	
	return false

# scripts/conditions/has_cold.gd
extends Resource
class_name HasColdCondition

func check(source, targets) -> bool:
	# Проверяем, есть ли у источника (игрока) статус Холода
	return source.has_status(DataManager.Status.COLD)

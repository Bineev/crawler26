extends Resource
class_name ConditionNoNegativeStatus

## Проверяет, нет ли у цели негативных статусов
## @param source: Node - источник эффекта (игрок)
## @param targets: Array - список целей (обычно один враг)
## @return bool - true, если у цели нет негативных статусов
func check(source: Node, targets: Array) -> bool:
	for target in targets:
		# Проверяем, есть ли у цели активные статусы
		if target.has_method("get_active_statuses"):
			var statuses = target.get_active_statuses()
			for status_id in statuses:
				if DataManager.is_negative_status(status_id):
					return false
	return true

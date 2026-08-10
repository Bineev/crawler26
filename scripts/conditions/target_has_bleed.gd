extends Node
class_name TargetHasBleedCondition

## Проверяет, есть ли у цели статус BLEED
func check(source, targets: Array) -> bool:
	if targets.is_empty():
		return false
	
	# Проверяем первую цель (для пассивок обычно цель одна)
	var target = targets[0]
	if target and target.has_method("has_status"):
		return target.has_status(DataManager.Status.BLEED)
	
	return false

extends Node
class_name TargetHasCombustible

func check(source: CharacterStats, targets: Array) -> bool:
	if targets.is_empty():
		return false
	
	var target = targets[0]
	if not target.has_method("has_status"):
		return false
	
	return target.has_status(DataManager.Status.COMBUSTIBLE)

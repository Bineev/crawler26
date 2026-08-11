extends Node
class_name TargetHasWeaknessCondition

func check(source, targets: Array) -> bool:
	if targets.is_empty():
		return false
	
	var target = targets[0]
	if target and target.has_method("has_status"):
		return target.has_status(DataManager.Status.WEAKNESS)
	
	return false

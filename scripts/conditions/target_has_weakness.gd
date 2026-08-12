extends Resource
class_name HasWeaknessCondition

func check(source, targets) -> bool:
	for target in targets:
		if target.has_status(DataManager.Status.WEAKNESS):
			return true
	return false

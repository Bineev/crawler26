extends Resource
class_name TargetHasNegativeStatusesCondition

func check(source, targets: Array) -> bool:
	if targets.is_empty():
		return false
	
	var target = targets[0]
	if not target or not target.has_method("has_status"):
		return false
	
	var negative_count = 0
	for status_id in DataManager.Status.values():
		if DataManager.is_negative_status(status_id):
			if target.has_status(status_id):
				negative_count += 1
	
	return negative_count > 2

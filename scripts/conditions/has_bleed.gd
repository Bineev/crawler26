# scripts/conditions/has_bleed.gd
extends Resource
class_name HasBleedCondition

func check(source, targets) -> bool:
	for target in targets:
		if target.has_status(DataManager.Status.BLEED):
			return true
	return false

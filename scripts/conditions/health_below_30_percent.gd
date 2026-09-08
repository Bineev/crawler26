extends Node
class_name HealthBelow30Percent

func check(source: CharacterStats, targets: Array) -> bool:
	if not is_instance_valid(source):
		return false
	
	var current_health = source.get_health()
	var max_health = source.get_max_health()
	
	if max_health <= 0:
		return false
	
	var percent = (float(current_health) / float(max_health)) * 100.0
	return percent < 30.0

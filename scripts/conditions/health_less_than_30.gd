# scripts/conditions/health_less_than_30.gd
extends Resource
class_name HealthLessThan30Condition

func check(source, targets) -> bool:
	return source.get_health() < 30

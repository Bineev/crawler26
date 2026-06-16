# scripts/ui/blood_screen.gd
extends ColorRect
class_name BloodScreen

func flash(intensity: float = 0.4, duration: float = 0.3):
	# Устанавливаем прозрачность
	color.a = intensity
	
	var tween = create_tween()
	tween.tween_property(self, "color", Color(0.8, 0.1, 0.05, 0.0), duration)
	await tween.finished

func flash_heavy(duration: float = 0.5):
	# Сильный удар
	color.a = 0.6
	var tween = create_tween()
	tween.tween_property(self, "color", Color(0.6, 0.05, 0.02, 0.0), duration)
	await tween.finished

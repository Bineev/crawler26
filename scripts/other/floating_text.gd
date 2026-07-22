# scripts/ui/floating_text.gd
extends Label
class_name FloatingText

func setup(text: String, color: Color, is_enemy: bool = true):
	self.text = text
	self.add_theme_font_override("font", DataManager.FONT_HEADERS)
	self.add_theme_font_size_override("font_size", 36)
	self.add_theme_color_override("font_color", color)
	if not is_enemy:
		self.add_theme_font_size_override("font_size", 48)
	_animate()


func _animate():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Улетаем строго вверх (дольше и выше)
	tween.tween_property(self, "position", position + Vector2(0, -150), 1.5).set_ease(Tween.EASE_OUT)
	
	# Увеличиваемся и плавно исчезаем (дольше держимся)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_delay(0.15)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5).set_delay(0.8)  # ← задержка перед исчезновением
	
	tween.finished.connect(queue_free)

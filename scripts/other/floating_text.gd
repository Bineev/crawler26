# scripts/ui/floating_text.gd
extends Label
class_name FloatingText

func setup(text: String, color: Color, is_enemy: bool = true, icon: Texture2D = null):
	var font_size = 30 if is_enemy else 30
	
	# 🆕 Очищаем содержимое
	for child in get_children():
		child.queue_free()
	
	if icon:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 5)
		
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon_rect)
		
		var label = Label.new()
		label.text = text
		label.add_theme_font_override("font", DataManager.FONT_HEADERS)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", color)
		hbox.add_child(label)
		
		add_child(hbox)
	else:
		# Если иконки нет — просто устанавливаем текст
		self.text = text
		self.add_theme_font_override("font", DataManager.FONT_HEADERS)
		self.add_theme_font_size_override("font_size", font_size)
		self.add_theme_color_override("font_color", color)
	
	_animate()


func _animate():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ignore_time_scale(true)
	# Улетаем строго вверх (дольше и выше)
	tween.tween_property(self, "position", position + Vector2(0, -150), 1.5).set_ease(Tween.EASE_OUT)
	
	# Увеличиваемся и плавно исчезаем (дольше держимся)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2).set_delay(0.15)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.5).set_delay(0.8)  # ← задержка перед исчезновением
	
	tween.finished.connect(queue_free)

extends ColorRect
class_name StatusIcon

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var stacks_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/StacksLabel
@onready var duration_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/DurationLabel
@onready var filler: Control = $MarginContainer/VBoxContainer/HBoxContainer/Filler


var status_id: int


func _ready():
	_setup_labels()

func _setup_labels():
	# Настройка для стаков
	stacks_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	stacks_label.add_theme_font_size_override("font_size", 10)
	stacks_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	stacks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stacks_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Настройка для длительности
	duration_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	duration_label.add_theme_font_size_override("font_size", 10)
	duration_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	duration_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func setup(data: Dictionary, text_color: Color = DataManager.COLOR_PENITENT_ART_BG_DARK, icon_owner = null) -> void:
	status_id = data["status_id"]
	
	# 🆕 Настройка прозрачности самого ColorRect
	if icon_owner is CardUI:
		color = Color(1, 1, 1, 0)  # полностью прозрачный
	else:
		color = Color(0, 0, 0, 1)  # чёрный фон
	
	icon.texture = data["icon"]
	custom_minimum_size = Vector2(32, 32)
	icon.custom_minimum_size = Vector2(16, 16)
	filler.custom_minimum_size = Vector2(5, 0)
	if icon_owner is CardUI:
		custom_minimum_size = Vector2(32, 32)
		icon.custom_minimum_size = Vector2(24, 24)
		filler.custom_minimum_size = Vector2(2, 0)
	if icon_owner is PlayerPortrait:
		custom_minimum_size = Vector2(48, 48)
		icon.custom_minimum_size = Vector2(32, 32)
		filler.custom_minimum_size = Vector2(10, 0)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Применяем цвет текста
	stacks_label.add_theme_color_override("font_color", text_color)
	duration_label.add_theme_color_override("font_color", text_color)
	
	# Стаки
	if data.get("stacks", 0) > 0:
		stacks_label.text = str(data["stacks"])
		stacks_label.visible = true
	else:
		stacks_label.visible = false
	
	# Длительность
	if data.get("duration", 0) > 0:
		duration_label.text = str(data["duration"])
		duration_label.visible = true
	else:
		duration_label.visible = false
		
	if status_id == DataManager.Status.SHIELD or status_id == DataManager.Status.STRENGTH:
		duration_label.visible = false


func _build_tooltip(data: Dictionary) -> String:
	var tooltip = "%s: %d" % [data["name"], data["stacks"]]
	if data.get("duration", 0) > 0:
		tooltip += " (осталось: %d)" % data["duration"]
	return tooltip

func animate() -> void:
	var original_scale = icon.scale
	var original_position = icon.position
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Увеличиваем и поднимаем
	tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", original_position + Vector2(0, -5), 0.15).set_ease(Tween.EASE_OUT)
	
	# Возвращаем обратно
	tween.tween_property(icon, "scale", original_scale, 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "position", original_position, 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)

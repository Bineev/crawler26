extends ColorRect
class_name PassiveIcon

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var charges_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ChargesLabel
@onready var filler: Control = $MarginContainer/VBoxContainer/HBoxContainer/Filler
@onready var h_box_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer

var passive_id: int


func _ready():
	_setup_labels()

func _setup_labels():
	# Настройка для зарядов
	charges_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	charges_label.add_theme_font_size_override("font_size", 10)
	charges_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	charges_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	charges_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func setup(data: Dictionary, text_color: Color = DataManager.COLOR_PENITENT_ART_BG_DARK, icon_owner = null) -> void:
	passive_id = data["passive_id"]
	
	# BUG для теста
	## 🆕 Настройка прозрачности самого ColorRect
	#if icon_owner is CardUI:
		#color = Color(1, 1, 1, 0)  # полностью прозрачный
	#else:
		#color = Color(0, 0, 0, 1)  # чёрный фон
	
	icon.texture = data["icon"]
	custom_minimum_size  = Vector2(32, 32)
	icon.custom_minimum_size = Vector2(32, 32)
	#icon.custom_minimum_size = Vector2(16, 16)
	filler.custom_minimum_size = Vector2(5, 0)
	if icon_owner is CardUI:
		custom_minimum_size = Vector2(32, 32)
		icon.custom_minimum_size = Vector2(24, 24)
		filler.custom_minimum_size = Vector2(2, 0)
	if icon_owner is PlayerPortrait:
		custom_minimum_size = Vector2(48, 48)
		icon.custom_minimum_size = Vector2(32, 32)
		filler.custom_minimum_size = Vector2(10, 0)
		h_box_container.show()
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# Применяем цвет текста
	charges_label.add_theme_color_override("font_color", text_color)
	
	# Заряды
	if data.get("charges", 0) > 0:
		charges_label.text = str(data["charges"])
		charges_label.visible = true
	else:
		charges_label.visible = false


func animate() -> void:
	var original_scale = icon.scale
	var original_position = icon.position
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", original_position + Vector2(0, -5), 0.15).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(icon, "scale", original_scale, 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "position", original_position, 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)

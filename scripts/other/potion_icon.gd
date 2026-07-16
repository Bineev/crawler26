extends TextureRect
class_name PotionIcon

var potion_data: PotionResource = null
var is_selected: bool = false
var use_button: Button = null

func _ready():
	use_button = Button.new()
	use_button.text = tr("potion_use")
	use_button.modulate = Color(1, 1, 1, 0)  # 🆕 прозрачный
	use_button.disabled = true
	use_button.pressed.connect(_on_use_pressed)
	
	use_button.add_theme_font_override("font", DataManager.FONT_MAIN)
	use_button.add_theme_font_size_override("font_size", 16)
	use_button.custom_minimum_size = Vector2(80, 30)
	
	add_child(use_button)
	
	# Позиционируем кнопку под зельем
	use_button.position = Vector2(
		(size.x - use_button.size.x) / 2,
		size.y + 5
	)

func setup(potion: PotionResource) -> void:
	potion_data = potion
	
	var icon_texture = DataManager.get_potion_icon(potion.potion_type)
	if icon_texture:
		texture = icon_texture
	else:
		pass
		#texture = preload("res://img/potions/default.png")
	
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	
	# Тултип
	var tooltip = potion.get_localized_name()
	var desc = potion.get_localized_description()
	if not desc.is_empty():
		tooltip += "\n" + desc
	tooltip_text = tooltip

func select() -> void:
	is_selected = true
	use_button.modulate = Color(1, 1, 1, 1)  # 🆕 становимся видимой
	use_button.disabled = false
	modulate = Color(1, 0.8, 0.2, 1)  # подсветка

func deselect() -> void:
	is_selected = false
	use_button.modulate = Color(1, 1, 1, 0)  # 🆕 прозрачная
	use_button.disabled = true
	modulate = Color(1, 1, 1, 1)

func _on_use_pressed() -> void:
	SignalManager.potion_used.emit(self)

func _input(event: InputEvent) -> void:
	if is_selected and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		deselect()

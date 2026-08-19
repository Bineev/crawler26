extends HBoxContainer
class_name KeyDisplay

@onready var key_label: Label = $KeyLabel
@onready var key_icon: TextureRect = $KeyIcon

func _ready():
	scale *= DataManager.SCALE_FACTOR
	# TODO: установить иконку ключа
	key_icon.texture = preload("res://img/icons/currency/keys1.png")
	key_icon.custom_minimum_size = Vector2(32, 32)
	key_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	DataManager.apply_shader_to_icon(key_icon, "res://shaders/highlight_item.gdshader", {'hover_intensity' : 1.0})

	key_label.custom_minimum_size = Vector2(10, 0)
	key_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	key_label.add_theme_font_size_override("font_size", 24)
	key_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	_update_keys()
	SignalManager.keys_changed.connect(_on_keys_changed)

func _update_keys() -> void:
	if key_label:
		key_label.text = str(RunManager.get_keys())

func _on_keys_changed(amount: int) -> void:
	_update_keys()

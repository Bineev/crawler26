extends HBoxContainer
class_name GoldDisplay

@onready var coins_label: Label = $CoinsLabel
@onready var coins_icon: TextureRect = $CoinsIcon

func _ready():
	scale *= DataManager.SCALE_FACTOR
	coins_icon.texture = DataManager.get_currency_icon(DataManager.CurrencyType.COIN)
	coins_icon.custom_minimum_size = Vector2(32, 32)
	coins_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	coins_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	DataManager.apply_shader_to_icon(coins_icon, "res://shaders/highlight_item.gdshader", {'hover_intensity' : 1.0})
	
	coins_label.custom_minimum_size = Vector2(20, 0)
	coins_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	coins_label.add_theme_font_size_override("font_size", 24)
	coins_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	_update_coins()
	SignalManager.coins_changed.connect(_on_coins_changed)

func _update_coins() -> void:
	if coins_label:
		coins_label.text = str(RunManager.get_coins())

func _on_coins_changed(amount: int) -> void:
	_update_coins()

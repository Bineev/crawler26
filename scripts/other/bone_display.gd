extends HBoxContainer
class_name BoneDisplay

@onready var bone_label: Label = $BoneLabel
@onready var bone_icon: TextureRect = $BoneIcon

func _ready():
	bone_icon.texture = DataManager.get_currency_icon(DataManager.CurrencyType.BONE)
	bone_icon.custom_minimum_size = Vector2(32, 32)
	bone_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	bone_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	DataManager.apply_shader_to_icon(bone_icon, "res://shaders/highlight_item.gdshader", {'hover_intensity' : 1.0})
	
	bone_label.custom_minimum_size = Vector2(20, 0)
	bone_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	bone_label.add_theme_font_size_override("font_size", 24)
	bone_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	
	_update_bones()
	SignalManager.bones_changed.connect(_on_bones_changed)

func _update_bones() -> void:
	if bone_label:
		bone_label.text = str(RunManager.get_bones())

func _on_bones_changed(amount: int) -> void:
	_update_bones()

extends PanelContainer
class_name Tooltip

@onready var vbox: VBoxContainer = $VBoxContainer
@onready var header: HBoxContainer = $VBoxContainer/Header
@onready var icon: TextureRect = $VBoxContainer/Header/Icon
@onready var title: Label = $VBoxContainer/Header/Title
@onready var description: Label = $VBoxContainer/Description
@onready var additional_info: Label = $VBoxContainer/AdditionalInfo
@onready var footer: Label = $VBoxContainer/Footer

var _is_visible: bool = false

func setup(data: Dictionary) -> void:
	# Скрываем все элементы (они перестают занимать место)
	icon.hide()
	title.hide()
	description.hide()
	additional_info.hide()
	footer.hide()
	
	await get_tree().process_frame
	# Иконка
	if data.has("icon") and data["icon"]:
		icon.texture = data["icon"]
		icon.visible = true
	
	# Заголовок
	if data.has("title") and not data["title"].is_empty():
		title.text = data["title"]
		title.visible = true
	
	# Описание
	if data.has("description") and not data["description"].is_empty():
		description.text = data["description"]
		description.visible = true
	
	# Дополнительная информация
	if data.has("additional_info") and not data["additional_info"].is_empty():
		additional_info.text = data["additional_info"]
		additional_info.visible = true
	
	# Футер
	if data.has("footer") and not data["footer"].is_empty():
		footer.text = data["footer"]
		footer.visible = true
	
	# Стилизация
	_setup_style()

func _setup_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)
	
	# 🆕 Настройка шрифтов
	# Заголовок
	title.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	
	# Описание
	description.add_theme_font_override("font", DataManager.FONT_MAIN)
	description.add_theme_font_size_override("font_size", 16)
	description.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	
	# Дополнительная информация
	additional_info.add_theme_font_override("font", DataManager.FONT_MAIN)
	additional_info.add_theme_font_size_override("font_size", 12)
	additional_info.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	
	# Футер
	footer.add_theme_font_override("font", DataManager.FONT_MAIN)
	footer.add_theme_font_size_override("font_size", 12)
	footer.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)

func show_at(mouse_position: Vector2):
	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_size = size
	
	# Базовое смещение — справа от курсора, нижний край на уровне курсора
	var offset = Vector2(15, 0)
	var target_pos = mouse_position + offset - Vector2(0, tooltip_size.y)
	
	# Проверка на выход за левую границу
	if target_pos.x + tooltip_size.x > viewport_size.x:
		target_pos.x = mouse_position.x - tooltip_size.x - 15  # слева от курсора
	
	# Проверка на выход за верхнюю границу
	if target_pos.y < 0:
		target_pos.y = 0
	
	# Проверка на выход за нижнюю границу
	if target_pos.y + tooltip_size.y > viewport_size.y:
		target_pos.y = viewport_size.y - tooltip_size.y
	
	# Проверка на выход за правую границу (если всё ещё не влезает)
	if target_pos.x + tooltip_size.x > viewport_size.x:
		target_pos.x = viewport_size.x - tooltip_size.x - 5
	
	global_position = target_pos
	_is_visible = true
	visible = true

func hide_tooltip():
	_is_visible = false
	visible = false
	queue_free()

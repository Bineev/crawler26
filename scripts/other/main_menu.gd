extends Control
class_name MainMenu

@onready var center_container: CenterContainer = $CenterContainer
@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var texture_rect: TextureRect = $CenterContainer/VBoxContainer/TextureRect
@onready var buttons_container: VBoxContainer = $CenterContainer/VBoxContainer/ButtonsContainer

func _ready():
	_setup_ui()
	_connect_signals()


func _setup_ui():
	# Настройка заголовка
	title_label.text = tr("main_menu_title")
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Настройка логотипа (заглушка)
	if not texture_rect.texture:
		var placeholder = ColorRect.new()
		placeholder.color = DataManager.COLOR_GRAY_DARK
		placeholder.custom_minimum_size = Vector2(600, 600)
		texture_rect.add_child(placeholder)
	
	# Создаём кнопки
	var start_button = DataManager.create_button(tr("main_menu_start"), DataManager.ButtonType.PRIMARY)
	var settings_button = DataManager.create_button(tr("main_menu_settings"), DataManager.ButtonType.PRIMARY)
	var exit_button = DataManager.create_button(tr("main_menu_exit"), DataManager.ButtonType.PRIMARY)
	
	# Добавляем кнопки в контейнер
	buttons_container.add_child(start_button)
	buttons_container.add_child(settings_button)
	buttons_container.add_child(exit_button)
	
	# Подписываемся на нажатия
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _connect_signals():
	pass


func _on_start_pressed():
	SignalManager.start_game_requested.emit()
	queue_free()

func _on_settings_pressed():
	SignalManager.settings_requested.emit()

func _on_exit_pressed():
	SignalManager.exit_requested.emit()

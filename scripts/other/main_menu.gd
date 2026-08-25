extends Control
class_name MainMenu

@onready var center_container: CenterContainer = $CenterContainer
@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title
@onready var texture_rect: TextureRect = $CenterContainer/VBoxContainer/TextureRect
@onready var buttons_container: VBoxContainer = $CenterContainer/VBoxContainer/ButtonsContainer
@onready var language_container: VBoxContainer = $CenterContainer/VBoxContainer/LanguageContainer
@onready var language_label: Label = $CenterContainer/VBoxContainer/LanguageContainer/LanguageLabel
@onready var language_option: OptionButton = $CenterContainer/VBoxContainer/LanguageContainer/LanguageOption

var is_enter_animation_finished: bool = false

func _ready():
	scale *= DataManager.SCALE_FACTOR
	_setup_ui()
	_connect_signals()
	# 🆕 Запускаем анимацию появления
	_play_enter_animation()


func _setup_ui():
	# Настройка заголовка
	title_label.text = tr("main_menu_title")
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 100)
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
	# Настройка языка
	language_label.text = tr("main_menu_language")
	language_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	language_label.add_theme_font_size_override("font_size", 20)
	language_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	language_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	language_option.add_item("English")
	language_option.add_item("Русский")
	language_option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Устанавливаем текущий язык
	var current_locale = TranslationServer.get_locale()
	match current_locale:
		"en":
			language_option.selected = 0
		"ru":
			language_option.selected = 1
		_:
			language_option.selected = 0
	# Подписываемся на нажатия
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	language_option.item_selected.connect(_on_language_changed)
	# Кнопки изначально отключены (пока анимация)
	for button in buttons_container.get_children():
		if button is Button:
			button.disabled = true
	# 🆕 Также отключаем выбор языка
	language_option.disabled = true


func _play_enter_animation():
	# Арт виден сразу (текстура уже есть)
	# Название и кнопки скрыты
	title_label.modulate = Color(1, 1, 1, 0)
	buttons_container.modulate = Color(1, 1, 1, 0)
	language_container.modulate = Color(1, 1, 1, 0)  # 🆕 скрываем выбор языка
	# Отключаем кнопки пока идёт анимация
	for button in buttons_container.get_children():
		if button is Button:
			button.disabled = true
	
	var tween = create_tween()
	
	# Шаг 1: Постепенное появление арта (оттемнение) — 2 секунды
	var parent = get_parent()
	if parent and parent is ColorRect:
		tween.tween_property(parent, "color:a", 0.0, 2.0)
	else:
		# Если родитель не ColorRect, создаём свой оверлей
		var fade_overlay = ColorRect.new()
		fade_overlay.color = Color(0, 0, 0, 1)
		fade_overlay.anchor_left = 0.0
		fade_overlay.anchor_right = 1.0
		fade_overlay.anchor_top = 0.0
		fade_overlay.anchor_bottom = 1.0
		fade_overlay.z_index = 999
		add_child(fade_overlay)
		tween.tween_property(fade_overlay, "color:a", 0.0, 2.0)
		tween.tween_callback(fade_overlay.queue_free)
	
	# Шаг 2: Появление названия после оттемнения
	tween.tween_interval(0.3)
	tween.tween_property(title_label, "modulate", Color(1, 1, 1, 1), 0.5)
	
	# Шаг 3: Появление кнопок через 1 секунду после названия
	tween.tween_interval(1.0)
	tween.tween_callback(_show_buttons)
	
	await tween.finished
	is_enter_animation_finished = true

func _show_buttons():
	# Кнопки появляются мгновенно
	buttons_container.modulate = Color(1, 1, 1, 1)
	language_container.modulate = Color(1, 1, 1, 1)  # 🆕 показываем выбор языка
	for button in buttons_container.get_children():
		if button is Button:
			button.disabled = false
	# 🆕 Включаем выбор языка
	language_option.disabled = false

func _connect_signals():
	pass
	
	
func _on_language_changed(index: int):
	match index:
		0:
			TranslationServer.set_locale("en")
		1:
			TranslationServer.set_locale("ru")
	
	# Обновляем все тексты в меню
	title_label.text = tr("main_menu_title")
	language_label.text = tr("main_menu_language")
	
	# Обновляем кнопки
	for child in buttons_container.get_children():
		if child is Button:
			match child.text:
				"В путь", "Set forth":
					child.text = tr("main_menu_start")
				"Настройки", "Settings":
					child.text = tr("main_menu_settings")
				"Выход", "Exit":
					child.text = tr("main_menu_exit")


func _on_start_pressed():
	if SaveManager.has_save():
		SignalManager.load_game_requested.emit()
	else:
		SignalManager.start_game_requested.emit()
	#queue_free()

func _on_settings_pressed():
	if not is_enter_animation_finished:
		return
	SignalManager.settings_requested.emit()

func _on_exit_pressed():
	SignalManager.exit_requested.emit()

extends Control
class_name SettingsMenu

enum OpenContext {
	MAIN_MENU,
	BIOME_CHOICE,
	GAMEPLAY,
}

const SETTINGS_FILE := "user://settings.cfg"
const SAVE_FILE := "user://savegame.save"  # 🆕 Добавляем константу

var open_context: OpenContext = OpenContext.MAIN_MENU
var is_open: bool = false
var reset_confirm_mode: bool = false

@onready var center_container: CenterContainer = $CenterContainer
@onready var panel: Panel = $CenterContainer/Panel
@onready var margin_container: MarginContainer = $CenterContainer/Panel/MarginContainer
@onready var vbox: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer
@onready var title_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Title
@onready var back_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/BackButton
@onready var music_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/MusicContainer
@onready var music_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/MusicContainer/MusicLabel
@onready var music_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/SFXContainer
@onready var sfx_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/SFXContainer/SFXLabel
@onready var sfx_slider: HSlider = $CenterContainer/Panel/MarginContainer/VBoxContainer/SFXContainer/SFXSlider
@onready var menu_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/MenuButton
@onready var language_container: VBoxContainer = $CenterContainer/Panel/MarginContainer/VBoxContainer/LanguageContainer
@onready var language_label: Label = $CenterContainer/Panel/MarginContainer/VBoxContainer/LanguageContainer/LanguageLabel
@onready var language_option: OptionButton = $CenterContainer/Panel/MarginContainer/VBoxContainer/LanguageContainer/LanguageOption
# 🆕 Кнопка сброса прогресса
@onready var reset_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResetButton


func _ready():
	scale *= DataManager.SCALE_FACTOR
	_setup_ui()
	_connect_signals()
	_load_volume_settings()
	hide()


func _setup_ui():
	# Заголовок
	title_label.text = tr("settings_title")
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Кнопка "Назад"
	back_button.text = tr("settings_back")
	DataManager.apply_button_style(back_button, DataManager.ButtonType.PRIMARY)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	# Музыка
	music_label.text = tr("settings_music")
	music_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	music_label.add_theme_font_size_override("font_size", 20)
	music_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	music_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Звуки SFX
	sfx_label.text = tr("settings_sfx")
	sfx_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	sfx_label.add_theme_font_size_override("font_size", 20)
	sfx_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	sfx_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01
	sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Кнопка "В меню" (по умолчанию скрыта)
	menu_button.text = tr("settings_menu_button")
	DataManager.apply_button_style(menu_button, DataManager.ButtonType.DANGER)
	menu_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_button.hide()
	
	# Стиль панели
	var style = StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", style)
	
	# Отступы
	margin_container.add_theme_constant_override("margin_left", 40)
	margin_container.add_theme_constant_override("margin_right", 40)
	margin_container.add_theme_constant_override("margin_top", 40)
	margin_container.add_theme_constant_override("margin_bottom", 40)
	
	# 🆕 Кнопка "Сбросить прогресс" (по умолчанию скрыта)
	reset_button.text = tr("settings_reset_progress")
	DataManager.apply_button_style(reset_button, DataManager.ButtonType.DANGER)
	reset_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset_button.hide()
	
	# Язык
	language_label.text = tr("settings_language")
	language_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	language_label.add_theme_font_size_override("font_size", 20)
	language_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	language_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	
	language_option.add_item("English")
	language_option.add_item("Русский")
	language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Устанавливаем текущий язык
	var current_locale = TranslationServer.get_locale()
	match current_locale:
		"en":
			language_option.selected = 0
		"ru":
			language_option.selected = 1
		_:
			language_option.selected = 0
	
	# Отступы между элементами VBox
	vbox.add_theme_constant_override("separation", 20)
	await get_tree().process_frame
	panel.custom_minimum_size = margin_container.size


func _connect_signals():
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	menu_button.pressed.connect(_on_menu_pressed)
	language_option.item_selected.connect(_on_language_changed)
	# 🆕 Подключаем сигнал кнопки сброса
	reset_button.pressed.connect(_on_reset_pressed)


func _load_volume_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_FILE)
	
	var music_volume = 0.8
	var sfx_volume = 0.8
	var language = "en"
	
	if err == OK:
		music_volume = config.get_value("audio", "music_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		language = config.get_value("locale", "language", "en")
	
	music_slider.value = music_volume
	sfx_slider.value = sfx_volume
	
	_set_bus_volume("Music", music_volume)
	_set_bus_volume("SFX", sfx_volume)
	
	match language:
		"en":
			language_option.selected = 0
		"ru":
			language_option.selected = 1
		_:
			language_option.selected = 0
	TranslationServer.set_locale(language)


func _save_settings():
	var config = ConfigFile.new()
	
	config.set_value("audio", "music_volume", music_slider.value)
	config.set_value("audio", "sfx_volume", sfx_slider.value)
	
	var lang = "en"
	match language_option.selected:
		0:
			lang = "en"
		1:
			lang = "ru"
	config.set_value("locale", "language", lang)
	
	config.save(SETTINGS_FILE)


func _set_bus_volume(bus_name: String, value: float):
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var db = linear_to_db(value)
		AudioServer.set_bus_volume_db(bus_index, db)


func _on_music_changed(value: float):
	_set_bus_volume("Music", value)
	_save_settings()


func _on_sfx_changed(value: float):
	_set_bus_volume("SFX", value)
	_save_settings()


func _on_language_changed(index: int):
	match index:
		0:
			TranslationServer.set_locale("en")
		1:
			TranslationServer.set_locale("ru")
	_save_settings()


func open(context: OpenContext = OpenContext.MAIN_MENU):
	open_context = context
	
	reset_confirm_mode = false
	
	match context:
		OpenContext.MAIN_MENU:
			menu_button.hide()
			# Показываем кнопку сброса только если есть файл сохранения
			if FileAccess.file_exists(SAVE_FILE):
				reset_button.show()
				reset_button.text = tr("settings_reset_progress")
				reset_button.modulate = Color(1, 1, 1, 1)
			else:
				reset_button.hide()
		OpenContext.BIOME_CHOICE, OpenContext.GAMEPLAY:
			menu_button.show()
			reset_button.hide()
	
	_load_volume_settings()
	
	modulate = Color(1, 1, 1, 0)
	show()
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)
	is_open = true


func close():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.2)
	await tween.finished
	hide()
	is_open = false
	reset_confirm_mode = false


func _on_back_pressed():
	SignalManager.settings_closed.emit()


func _on_menu_pressed():
	close()
	SignalManager.exit_to_menu_requested.emit()


# 🆕 Обработчик кнопки сброса прогресса
func _on_reset_pressed():
	if not reset_confirm_mode:
		# Первый клик — переключаем в режим подтверждения
		reset_confirm_mode = true
		reset_button.text = tr("settings_reset_confirm")
		reset_button.modulate = Color(1, 0.3, 0.2, 1)  # Красноватый оттенок
	else:
		# Второй клик — подтверждение сброса
		_reset_progress()


func _reset_progress():
	# Удаляем файл сохранения (прогресс)
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
		print("Save file deleted: ", SAVE_FILE)
	
	# 🆕 Скрываем кнопку, но НЕ закрываем настройки
	reset_button.hide()
	
	# Сбрасываем режим подтверждения
	reset_confirm_mode = false
	
	print("Progress reset successfully!")

extends Control
class_name DeathUI

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var death_label: Label = $VBoxContainer/DeathLabel
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var buttons_container: HBoxContainer = $VBoxContainer/ButtonsContainer
@onready var lobby_button: Button = $VBoxContainer/ButtonsContainer/LobbyButton
@onready var retry_button: Button = $VBoxContainer/ButtonsContainer/RetryButton

func _ready():
	# Начальное состояние: всё прозрачно
	modulate = Color(1, 1, 1, 0)
	dark_overlay.color.a = 0.0
	death_label.modulate = Color(1, 1, 1, 0)
	stats_label.modulate = Color(1, 1, 1, 0)
	buttons_container.modulate = Color(1, 1, 1, 0)
	
	# Настройка текста
	death_label.text = tr("death_title")
	death_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	death_label.add_theme_font_size_override("font_size", 48)
	death_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	stats_label.text = _get_stats_text()
	stats_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	stats_label.add_theme_font_size_override("font_size", 20)
	stats_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	lobby_button.text = tr("settings_menu_button")
	retry_button.text = tr("death_retry")
	
	# Настройка кнопок через DataManager
	DataManager.apply_button_style(lobby_button, DataManager.ButtonType.PRIMARY)
	DataManager.apply_button_style(retry_button, DataManager.ButtonType.PRIMARY)
	
	lobby_button.pressed.connect(_on_menu_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	
	# Запускаем анимацию появления
	_animate_in()

func _get_stats_text() -> String:
	var stats = ""
	stats += tr("death_stats_floor") % FloorManager.current_floor
	stats += "\n" + tr("death_stats_biome") % DataManager.Biome.keys()[FloorManager.current_biome]
	# TODO: добавить больше статистики
	return stats

func _animate_in():
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Затемнение
	tween.tween_property(dark_overlay, "color:a", 1, 0.5)
	
	# Появление всей панели
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.5)
	
	await get_tree().create_timer(0.5).timeout
	
	# Появление текста о смерти
	tween = create_tween()
	tween.tween_property(death_label, "modulate", Color(1, 1, 1, 1), 0.5)
	
	await get_tree().create_timer(0.6).timeout
	
	# Появление статистики
	tween = create_tween()
	tween.tween_property(stats_label, "modulate", Color(1, 1, 1, 1), 0.4)
	
	await get_tree().create_timer(0.5).timeout
	
	# Появление кнопок
	tween = create_tween()
	tween.tween_property(buttons_container, "modulate", Color(1, 1, 1, 1), 0.3)

func _on_menu_pressed():
	# Переход в главное меню
	SignalManager.exit_to_menu_requested.emit()
	queue_free()

func _on_retry_pressed():
	SignalManager.restart_run_requested.emit()
	queue_free()

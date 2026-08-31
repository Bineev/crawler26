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
	await _animate_in()

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
	
	# 🆕 Показываем UI прогресса (кнопки появятся в конце анимации)
	show_run_progress_ui()

func _on_menu_pressed():
	# Переход в главное меню
	SignalManager.exit_to_menu_requested.emit()
	queue_free()

func _on_retry_pressed():
	SignalManager.restart_run_requested.emit()
	queue_free()


## ============================================================
## UI ПРОГРЕССА ЗА ЗАБЕГ
## ============================================================

func show_run_progress_ui() -> void:
	# Получаем прогресс за забег
	var progress = ProgressManager.get_run_progress()
	var unlocked = ProgressManager.process_all_level_ups()
	
	var character_class = RunManager.current_character
	var biome = RunManager.current_biome
	
	# Данные персонажа
	var char_start_lvl = progress.character_start_level
	var char_start_xp = progress.character_start_xp
	var char_current_lvl = progress.character_current_level
	var char_current_xp = progress.character_current_xp
	var char_xp_gain = progress.character_xp_gain
	
	# Данные биома
	var biome_start_lvl = progress.biome_start_level
	var biome_start_xp = progress.biome_start_xp
	var biome_current_lvl = progress.biome_current_level
	var biome_current_xp = progress.biome_current_xp
	var biome_xp_gain = progress.biome_xp_gain
	
	# Создаём контейнер для прогресса
	var progress_container = VBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 20)
	progress_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# Создаём UI для персонажа
	var char_vbox = _create_progress_section(
		tr("death_progress_character"),
		tr(DataManager.get_character_class_name_key(character_class)),
		char_start_lvl,
		char_start_xp,
		char_current_lvl,
		char_current_xp,
		true  # 🆕 is_character
	)
	progress_container.add_child(char_vbox)

	# Создаём UI для биома
	var biome_vbox = _create_progress_section(
		tr("death_progress_biome"),
		DataManager.get_biome_name(biome),
		biome_start_lvl,
		biome_start_xp,
		biome_current_lvl,
		biome_current_xp,
		false  # 🆕 is_character
	)
	progress_container.add_child(biome_vbox)
	
	# Контейнер для наград
	var rewards_hbox = HBoxContainer.new()
	rewards_hbox.add_theme_constant_override("separation", 10)
	rewards_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_container.add_child(rewards_hbox)
	
	# Добавляем контейнер в интерфейс (после stats_label, перед buttons_container)
	var vbox = $VBoxContainer
	var stats_index = vbox.get_children().find(stats_label)
	vbox.add_child(progress_container)
	vbox.move_child(progress_container, stats_index + 1)
	
	# Запускаем анимацию заполнения баров
	_animate_bars(progress_container, char_vbox, biome_vbox, rewards_hbox, unlocked)


func _create_progress_section(title: String, name: String, start_lvl: int, start_xp: int, current_lvl: int, current_xp: int, is_character: bool) -> VBoxContainer:
	var section = VBoxContainer.new()
	section.add_theme_constant_override("separation", 5)
	
	# Заголовок: название + уровень
	var header = HBoxContainer.new()
	var title_label = Label.new()
	title_label.text = "%s: %s" % [title, name]
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	header.add_child(title_label)
	
	var level_label = Label.new()
	level_label.text = tr("death_progress_level") % current_lvl
	level_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(level_label)
	
	section.add_child(header)
	
	# Бар прогресса
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(400, 30)
	bar.show_percentage = false  # 🆕 отключаем проценты
	
	# Рассчитываем XP для барьера
	var start_required = ProgressManager.get_required_xp_for_character_level(start_lvl) if is_character else ProgressManager.get_required_xp_for_biome_level(start_lvl)
	var current_required = ProgressManager.get_required_xp_for_character_level(current_lvl) if is_character else ProgressManager.get_required_xp_for_biome_level(current_lvl)
	
	# Сохраняем данные в метаданные для анимации
	bar.set_meta("start_xp", start_xp)
	bar.set_meta("current_xp", current_xp)
	bar.set_meta("start_required", start_required)
	bar.set_meta("current_required", current_required)
	bar.set_meta("start_lvl", start_lvl)
	bar.set_meta("current_lvl", current_lvl)
	bar.set_meta("is_character", is_character)
	
	# Стиль бара
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	bar.add_theme_stylebox_override("background", style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = DataManager.COLOR_ATONEMENT_DARK if is_character else DataManager.COLOR_ROTTEN_MARSHES_ART_BG_LIGHT
	bar.add_theme_stylebox_override("fill", fill_style)
	
	section.add_child(bar)
	
	# Текст прогресса
	var xp_label = Label.new()
	xp_label.text = "%d / %d XP" % [start_xp, start_required]
	xp_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	xp_label.add_theme_font_size_override("font_size", 14)
	xp_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section.add_child(xp_label)
	
	# Сохраняем ссылку на xp_label для обновления
	bar.set_meta("xp_label", xp_label)
	
	return section


## ============================================================
## АНИМАЦИЯ БАРОВ
## ============================================================

func _animate_bars(container: Control, char_vbox: VBoxContainer, biome_vbox: VBoxContainer, rewards_hbox: HBoxContainer, unlocked: Dictionary) -> void:
	var tween = create_tween()
	tween.set_parallel(false)
	
	# Анимируем бар персонажа
	var char_bar = char_vbox.get_child(1)  # ProgressBar
	_animate_single_bar(tween, char_bar, 0.8)
	
	# Анимируем бар биома
	var biome_bar = biome_vbox.get_child(1)  # ProgressBar
	_animate_single_bar(tween, biome_bar, 0.8)
	
	await tween.finished
	
	# После заполнения баров показываем награды
	_show_rewards(rewards_hbox, unlocked)
	
	# 🆕 После всех анимаций показываем кнопки
	_show_buttons()


func _show_buttons() -> void:
	var tween = create_tween()
	tween.tween_property(buttons_container, "modulate", Color(1, 1, 1, 1), 0.3)


func _animate_single_bar(tween: Tween, bar: ProgressBar, duration: float) -> void:
	var start_xp = bar.get_meta("start_xp", 0)
	var current_xp = bar.get_meta("current_xp", 0)
	var start_required = bar.get_meta("start_required", 1)
	var current_required = bar.get_meta("current_required", 1)
	var start_lvl = bar.get_meta("start_lvl", 0)
	var current_lvl = bar.get_meta("current_lvl", 0)
	var xp_label = bar.get_meta("xp_label", null)
	
	# Начальное состояние
	bar.value = 0
	bar.max_value = start_required
	
	# Если был левел-ап
	if current_lvl > start_lvl:
		# Сначала заполняем до конца первого уровня
		var first_fill = start_xp
		tween.tween_property(bar, "value", first_fill, duration * 0.5)
		if xp_label:
			tween.tween_callback(func(): xp_label.text = "%d / %d XP" % [first_fill, start_required])
		
		# Меняем max_value на новый уровень
		tween.tween_callback(func(): 
			bar.max_value = current_required
			# Визуальный эффект перехода уровня
			bar.modulate = Color(1, 1, 0.5, 1)
			bar.modulate = Color(1, 1, 1, 1)
		)
		
		# Заполняем до текущего значения
		var remaining_xp = current_xp - start_xp
		tween.tween_property(bar, "value", current_xp, duration * 0.5)
		if xp_label:
			tween.tween_callback(func(): xp_label.text = "%d / %d XP" % [current_xp, current_required])
	else:
		# Если левел-апа не было
		var xp_gain = current_xp - start_xp
		tween.tween_property(bar, "value", current_xp, duration)
		if xp_label:
			tween.tween_callback(func(): xp_label.text = "%d / %d XP" % [current_xp, start_required])


## ============================================================
## ПОКАЗ НАГРАД
## ============================================================

func _show_rewards(rewards_hbox: HBoxContainer, unlocked: Dictionary) -> void:
	var all_cards: Array[DataManager.CardId] = []
	all_cards.append_array(unlocked.get("character_unlocked", []))
	all_cards.append_array(unlocked.get("biome_unlocked", []))
	
	if all_cards.is_empty():
		rewards_hbox.hide()
		return
	
	rewards_hbox.modulate = Color(1, 1, 1, 0)
	rewards_hbox.show()
	
	var card_scene = preload("res://scenes/card.tscn")
	
	for i in range(all_cards.size()):
		var card_data = DataManager.get_card(all_cards[i])
		if not card_data:
			continue
		
		var card_ui = card_scene.instantiate() as CardUI
		card_ui.card_data = card_data
		card_ui.display()
		card_ui.set_reward_state()
		card_ui.scale = Vector2(0.7, 0.7)
		rewards_hbox.add_child(card_ui)
		
		card_ui.modulate = Color(1, 1, 1, 0)
		var delay = i * 0.15
		var tween = create_tween()
		tween.tween_property(card_ui, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(delay)
	
	var tween = create_tween()
	tween.tween_property(rewards_hbox, "modulate", Color(1, 1, 1, 1), 0.3)

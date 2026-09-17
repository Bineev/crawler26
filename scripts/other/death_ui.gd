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
	scale *= DataManager.SCALE_FACTOR
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
	var progress = ProgressManager.get_run_progress()
	var unlocked = ProgressManager.process_all_level_ups()
	
	SaveManager.save_game_with_run_ended()
	
	var character_class = RunManager.current_character
	
	# === Данные персонажа ===
	var char_start_lvl = progress.character_start_level
	var char_start_xp = progress.character_start_xp
	var char_start_xp_on_level = progress.character_start_xp_on_level
	var char_current_lvl = progress.character_current_level
	var char_current_xp = progress.character_current_xp
	var char_current_xp_on_level = progress.character_current_xp_on_level
	
	# === Контейнер для прогресса ===
	var progress_container = VBoxContainer.new()
	progress_container.add_theme_constant_override("separation", 20)
	progress_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	# === Секция персонажа ===
	var char_vbox = _create_progress_section(
		tr("death_progress_character"),
		tr(DataManager.get_character_class_name_key(character_class)),
		char_start_lvl,
		char_start_xp,
		char_start_xp_on_level,
		char_current_lvl,
		char_current_xp,
		char_current_xp_on_level,
		true
	)
	progress_container.add_child(char_vbox)
	
	# === Секции биомов (только те, где был прогресс) ===
	var biome_vboxes: Array[VBoxContainer] = []
	var biomes = progress.get("biomes", {})
	
	for biome_id in biomes.keys():
		var data = biomes[biome_id]
		var biome_vbox = _create_progress_section(
			tr("death_progress_biome"),
			DataManager.get_biome_name(biome_id),
			data.start_level,
			data.start_xp,
			data.start_xp_on_level,
			data.current_level,
			data.current_xp,
			data.current_xp_on_level,
			false
		)
		progress_container.add_child(biome_vbox)
		biome_vboxes.append(biome_vbox)
	
	# === Контейнер для наград ===
	var rewards_hbox = HBoxContainer.new()
	rewards_hbox.add_theme_constant_override("separation", 10)
	rewards_hbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	progress_container.add_child(rewards_hbox)
	
	# === Вставляем после stats_label ===
	var vbox = $VBoxContainer
	var stats_index = vbox.get_children().find(stats_label)
	vbox.add_child(progress_container)
	vbox.move_child(progress_container, stats_index + 1)
	
	# === Запускаем анимацию ===
	_animate_bars(progress_container, char_vbox, biome_vboxes, rewards_hbox, unlocked)


func _create_progress_section(
	title: String,
	name: String,
	start_lvl: int,
	start_xp: int,
	start_xp_on_level: int,
	current_lvl: int,
	current_xp: int,
	current_xp_on_level: int,
	is_character: bool
) -> VBoxContainer:
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
	bar.show_percentage = false
	
	# Рассчитываем XP для барьера
	var start_required = ProgressManager.get_required_xp_for_character_level(start_lvl) if is_character else ProgressManager.get_required_xp_for_biome_level(start_lvl)
	var current_required = ProgressManager.get_required_xp_for_character_level(current_lvl) if is_character else ProgressManager.get_required_xp_for_biome_level(current_lvl)
	
	# 🆕 Сохраняем данные в метаданные для анимации
	bar.set_meta("start_xp", start_xp_on_level)
	bar.set_meta("current_xp", current_xp_on_level)
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
	xp_label.text = "%d / %d XP" % [start_xp_on_level, start_required]
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

func _animate_bars(
	container: Control,
	char_vbox: VBoxContainer,
	biome_vboxes: Array[VBoxContainer],
	rewards_hbox: HBoxContainer,
	unlocked: Dictionary
) -> void:
	var tween = create_tween()
	tween.set_parallel(false)
	
	# === Бар персонажа ===
	var char_bar = char_vbox.get_child(1)  # ProgressBar
	_animate_single_bar(tween, char_bar, 0.8)
	
	# === Бары биомов (последовательно) ===
	for biome_vbox in biome_vboxes:
		var biome_bar = biome_vbox.get_child(1)
		_animate_single_bar(tween, biome_bar, 0.8)
	
	await tween.finished
	
	# === После заполнения баров показываем награды и кнопки ===
	_show_rewards(rewards_hbox, unlocked)
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
	bar.value = start_xp
	bar.max_value = start_required
	
	# Если был левел-ап
	if current_lvl > start_lvl:
		# 🆕 Фаза 1: заполняем до конца старого уровня
		var first_fill = start_required
		tween.tween_property(bar, "value", first_fill, duration * 0.5)
		if xp_label:
			tween.tween_callback(func(): xp_label.text = "%d / %d XP" % [first_fill, start_required])
		
		# Смена уровня: max_value на новый, value сбрасывается в 0
		tween.tween_callback(func(): 
			bar.max_value = current_required
			bar.value = 0
		)
		
		# 🆕 Фаза 2: заполняем до текущего значения на новом уровне
		tween.tween_property(bar, "value", current_xp, duration * 0.5)
		if xp_label:
			tween.tween_callback(func(): xp_label.text = "%d / %d XP" % [current_xp, current_required])
	else:
		# Левел-апа не было — просто анимируем от start_xp до current_xp
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
	var card_scale = 0.7
	var card_size = Vector2(
		DataManager.CARD_BASE_WIDTH * card_scale * 1.5,
		DataManager.CARD_BASE_HEIGHT * card_scale * 1.5
	)
	
	for i in range(all_cards.size()):
		var card_data = DataManager.get_card(all_cards[i])
		if not card_data:
			continue
		
		# 🆕 Обёртка Control, чтобы HBoxContainer правильно позиционировал карту
		var card_wrapper = Control.new()
		card_wrapper.custom_minimum_size = card_size
		
		var card_ui = card_scene.instantiate() as CardUI
		card_ui.card_data = card_data
		card_wrapper.add_child(card_ui)
		rewards_hbox.add_child(card_wrapper)
		
		# 🆕 Теперь, когда карта в дереве, _ready() сработал и display() безопасен
		card_ui.display()
		card_ui.set_reward_state()
		card_ui.card_control.scale = Vector2(card_scale, card_scale)
		
		card_wrapper.modulate = Color(1, 1, 1, 0)
		var delay = i * 0.15
		var tween = create_tween()
		tween.tween_property(card_wrapper, "modulate", Color(1, 1, 1, 1), 0.3).set_delay(delay)
	
	var tween = create_tween()
	tween.tween_property(rewards_hbox, "modulate", Color(1, 1, 1, 1), 0.3)

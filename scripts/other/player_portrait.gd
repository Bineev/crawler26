# scripts/ui/player_portrait.gd
extends Control
class_name PlayerPortrait

var vbox: VBoxContainer = null
var portrait_texture: TextureRect = null
var status_container: HBoxContainer = null
var health_bar: ProgressBar = null
var health_label: Label = null
var atonement_bar: ProgressBar = null
var atonement_label: Label = null

var player_stats: CharacterStats = null

var floating_text_positions: Array[Vector2] = []
var current_position_index: int = 0
var floating_counter: int = 0
var left_index: int = 0
var right_index: int = 0

func _ready() -> void:
	vbox = $VBoxContainer
	portrait_texture = $VBoxContainer/TextureRect
	status_container = $VBoxContainer/StatusContainer
	health_bar = $VBoxContainer/HealthBar
	health_label = $VBoxContainer/HealthBar/HealthLabel
	atonement_bar = $VBoxContainer/AtonementBar
	atonement_label = $VBoxContainer/AtonementBar/AtonementLabel
	# Инициализируем позиции для всплывающих цифр
	_init_floating_positions()

func setup(stats: CharacterStats):
	player_stats = stats
	
	_setup_bars()
	
	SignalManager.health_changed.connect(_on_health_changed)
	SignalManager.atonement_changed.connect(_on_atonement_changed)
	SignalManager.status_added.connect(_on_icons_changed)
	SignalManager.status_removed.connect(_on_icons_changed)
	SignalManager.passive_added.connect(_on_icons_changed)
	SignalManager.passive_removed.connect(_on_icons_changed)
	SignalManager.player_damage_dealt.connect(_on_player_damage_dealt)
	SignalManager.player_heal_received.connect(_on_player_heal_received)
	
	_update_health()
	_update_atonement()
	_update_icons()


func _update_health():
	if not player_stats:
		return
	
	var current = player_stats.get_health()
	var max_health = player_stats.get_max_health()
	
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = "%d/%d" % [current, max_health]
	
	# Цвет при низком здоровье
	if current < max_health * 0.25:
		health_bar.modulate = Color(1, 0.2, 0.2)
	elif current < max_health * 0.5:
		health_bar.modulate = Color(1, 0.7, 0.2)
	else:
		health_bar.modulate = Color(1, 1, 1)


func _update_atonement():
	if not player_stats:
		return
	
	var current = player_stats.get_flat(DataManager.FlatStat.ATONEMENT)
	var max_atonement = player_stats.get_flat(DataManager.FlatStat.MAX_ATONEMENT)
	
	atonement_bar.max_value = max_atonement
	atonement_bar.value = current
	atonement_label.text = "%d/%d" % [current, max_atonement]


func _update_statuses():
	for child in status_container.get_children():
		child.queue_free()
	
	if not player_stats:
		return
	
	for status_id in player_stats.active_statuses.keys():
		var status_data = player_stats.active_statuses[status_id]
		var icon = DataManager.get_status_icon(status_id)
		if icon:
			var icon_rect = TextureRect.new()
			icon_rect.texture = icon
			icon_rect.custom_minimum_size = Vector2(24, 24)
			icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.tooltip_text = "%s: %d" % [DataManager.get_status_name(status_id), status_data.stacks]
			status_container.add_child(icon_rect)


func _on_health_changed(current: int, max_health: int):
	_update_health()


func _on_atonement_changed(current: int, max_atonement: int):
	_update_atonement()


func _on_status_changed(target: Node, status_id: int, stacks: int, duration: int):
	if target == player_stats:
		_update_statuses()


func _setup_bars():
	# ===== ЗДОРОВЬЕ =====
	# Фон
	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color.BLACK
	health_bg.border_width_bottom = 2
	health_bg.border_width_top = 2
	health_bg.border_width_left = 2
	health_bg.border_width_right = 2
	health_bg.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	health_bar.add_theme_stylebox_override("background", health_bg)
	
	# Заливка (красный)
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	health_fill.border_width_bottom = 1
	health_fill.border_width_top = 1
	health_fill.border_width_left = 1
	health_fill.border_width_right = 1
	health_fill.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	health_bar.add_theme_stylebox_override("fill", health_fill)
	
	# Текст
	health_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	health_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# ===== ИСКУПЛЕНИЕ =====
	# Фон
	var atonement_bg = StyleBoxFlat.new()
	atonement_bg.bg_color = Color.BLACK
	atonement_bg.border_width_bottom = 2
	atonement_bg.border_width_top = 2
	atonement_bg.border_width_left = 2
	atonement_bg.border_width_right = 2
	atonement_bg.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	atonement_bar.add_theme_stylebox_override("background", atonement_bg)
	
	# Заливка (бежевый)
	var atonement_fill = StyleBoxFlat.new()
	atonement_fill.bg_color = DataManager.COLOR_ATONEMENT_DARK
	atonement_fill.border_width_bottom = 1
	atonement_fill.border_width_top = 1
	atonement_fill.border_width_left = 1
	atonement_fill.border_width_right = 1
	atonement_fill.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	atonement_bar.add_theme_stylebox_override("fill", atonement_fill)
	
	# Текст
	atonement_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	atonement_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	atonement_label.add_theme_font_size_override("font_size", 14)
	atonement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	atonement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Высота баров
	health_bar.custom_minimum_size = Vector2(0, 40)
	atonement_bar.custom_minimum_size = Vector2(0, 40)
	
	# Обновляем значения
	_update_health()
	_update_atonement()


func _on_player_damage_dealt(damage: int):
	show_floating_text(str(damage), DataManager.COLOR_FLESH_CAVES_ART_BG_DARK)


func _on_player_heal_received(heal: int):
	show_floating_text("+" + str(heal), DataManager.COLOR_ROGUE_ART_BG_LIGHT)


func show_floating_text(text: String, color: Color):
	if floating_text_positions.is_empty():
		_init_floating_positions()
	
	if floating_text_positions.is_empty():
		return
	
	var pos: Vector2
	
	if floating_counter % 2 == 0:
		# Чётные → левая сторона
		pos = floating_text_positions[left_index]
		left_index = (left_index + 1) % 5
	else:
		# Нечётные → правая сторона
		pos = floating_text_positions[5 + right_index]
		right_index = (right_index + 1) % 5
	
	floating_counter += 1
	
	var floating_text = preload("res://scenes/floating_text.tscn").instantiate() as FloatingText
	add_child(floating_text)
	floating_text.global_position = pos
	floating_text.setup(text, color)


func _exit_tree():
	SignalManager.health_changed.disconnect(_on_health_changed)
	SignalManager.atonement_changed.disconnect(_on_atonement_changed)
	SignalManager.status_added.disconnect(_on_status_changed)
	SignalManager.status_removed.disconnect(_on_status_changed)
	SignalManager.player_damage_dealt.disconnect(_on_player_damage_dealt)
	SignalManager.player_heal_received.disconnect(_on_player_heal_received)


func _init_floating_positions():
	if not portrait_texture:
		return
	
	var portrait_pos = portrait_texture.global_position
	var portrait_size = portrait_texture.size
	
	# Коэффициенты для позиций
	var left_margin = 0.05   # от левого края
	var right_margin = 0.05  # от правого края
	var top_margin = 0.25    # от верхнего края (ниже глаз)
	var bottom_margin = 0.75 # до нижнего края
	
	# Левые позиции
	for i in range(5):
		var t = float(i) / 4.0
		var x = portrait_pos.x + portrait_size.x * left_margin + portrait_size.x * 0.05
		var y = portrait_pos.y + portrait_size.y * (top_margin + t * (bottom_margin - top_margin))
		floating_text_positions.append(Vector2(x, y))
	
	# Правые позиции
	for i in range(5):
		var t = float(i) / 4.0
		var x = portrait_pos.x + portrait_size.x * (1 - right_margin) - portrait_size.x * 0.05
		var y = portrait_pos.y + portrait_size.y * (top_margin + t * (bottom_margin - top_margin))
		floating_text_positions.append(Vector2(x, y))

func _update_icons():
	if not status_container:
		return
	
	# Очищаем контейнер
	for child in status_container.get_children():
		child.queue_free()
	
	if not player_stats:
		return
	
	# Добавляем статусы
	for status_id in player_stats.active_statuses.keys():
		var status_data = player_stats.active_statuses[status_id]
		var icon = DataManager.get_status_icon(status_id)
		if icon:
			var icon_rect = _create_icon(icon, "%s: %d" % [DataManager.get_status_name(status_id), status_data.stacks])
			status_container.add_child(icon_rect)
	
	# Добавляем пассивки
	for passive in player_stats.active_passives:
		var icon = DataManager.get_passive_icon(passive.id)
		if icon:
			var icon_rect = _create_icon(icon, passive.get_localized_name())
			status_container.add_child(icon_rect)


func _create_icon(texture: Texture2D, tooltip: String) -> TextureRect:
	var icon_rect = TextureRect.new()
	icon_rect.texture = texture
	icon_rect.custom_minimum_size = Vector2(24, 24)
	icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.tooltip_text = tooltip
	# добавить шейдер на обводку
	DataManager.apply_shader_to_icon(icon_rect, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})
	DataManager.apply_shader_overlay(icon_rect, "res://shaders/horror_shader.gdshader", {})
	return icon_rect


func _on_icons_changed(target: Node, arg1 = null, arg2 = null, arg3 = null):
	if target == player_stats:
		_update_icons()

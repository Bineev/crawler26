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


func _ready() -> void:
	vbox = $VBoxContainer
	portrait_texture = $VBoxContainer/TextureRect
	status_container = $VBoxContainer/StatusContainer
	health_bar = $VBoxContainer/HealthBar
	health_label = $VBoxContainer/HealthBar/HealthLabel
	atonement_bar = $VBoxContainer/AtonementBar
	atonement_label = $VBoxContainer/AtonementBar/AtonementLabel

func setup(stats: CharacterStats):
	player_stats = stats
	_setup_bars()
	
	SignalManager.health_changed.connect(_on_health_changed)
	SignalManager.atonement_changed.connect(_on_atonement_changed)
	SignalManager.status_added.connect(_on_status_changed)
	SignalManager.status_removed.connect(_on_status_changed)
	
	_update_health()
	_update_atonement()
	#_update_statuses()


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


func _exit_tree():
	SignalManager.health_changed.disconnect(_on_health_changed)
	SignalManager.atonement_changed.disconnect(_on_atonement_changed)
	SignalManager.status_added.disconnect(_on_status_changed)
	SignalManager.status_removed.disconnect(_on_status_changed)


func _setup_bars():
	# ===== ЗДОРОВЬЕ =====
	# Фон
	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color(0.15, 0.05, 0.05, 0.8)
	health_bg.border_width_bottom = 2
	health_bg.border_width_top = 2
	health_bg.border_width_left = 2
	health_bg.border_width_right = 2
	health_bg.border_color = Color(0.3, 0.1, 0.1)
	health_bar.add_theme_stylebox_override("background", health_bg)
	
	# Заливка (красный)
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	health_fill.border_width_bottom = 1
	health_fill.border_width_top = 1
	health_fill.border_width_left = 1
	health_fill.border_width_right = 1
	health_fill.border_color = Color(0.5, 0.15, 0.15)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	
	# Текст
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# ===== ИСКУПЛЕНИЕ =====
	# Фон
	var atonement_bg = StyleBoxFlat.new()
	atonement_bg.bg_color = Color(0.1, 0.08, 0.05, 0.8)
	atonement_bg.border_width_bottom = 2
	atonement_bg.border_width_top = 2
	atonement_bg.border_width_left = 2
	atonement_bg.border_width_right = 2
	atonement_bg.border_color = Color(0.2, 0.15, 0.1)
	atonement_bar.add_theme_stylebox_override("background", atonement_bg)
	
	# Заливка (бежевый)
	var atonement_fill = StyleBoxFlat.new()
	atonement_fill.bg_color = DataManager.COLOR_PENITENT_ART_BG_LIGHT
	atonement_fill.border_width_bottom = 1
	atonement_fill.border_width_top = 1
	atonement_fill.border_width_left = 1
	atonement_fill.border_width_right = 1
	atonement_fill.border_color = Color(0.4, 0.3, 0.2)
	atonement_bar.add_theme_stylebox_override("fill", atonement_fill)
	
	# Текст
	atonement_label.add_theme_color_override("font_color", Color.WHITE)
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

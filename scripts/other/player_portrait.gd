# scripts/ui/player_portrait.gd
extends Control
class_name PlayerPortrait

const STATUS_ICON_SCENE = preload("res://scenes/status_icon.tscn")
const PASSIVE_ICON_SCENE = preload("res://scenes/passive_icon.tscn")

var vbox: VBoxContainer = null
var portrait_texture: TextureRect = null
var status_container: GridContainer = null
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

const FREEZE_SHADER = preload("res://shaders/frozen.gdshader")
const HIT_SHADER = preload("res://shaders/get_hit_shader.gdshader")  # если есть отдельный шейдер

var ice_noise: NoiseTexture2D = null
var freeze_tween: Tween = null
var hit_tween: Tween = null

var _base_portrait_material: Material = null

# Приоритеты шейдеров (как у врага)
var current_shader_priority: DataManager.EnemyShaderPriority = DataManager.EnemyShaderPriority.NONE
var pending_death: bool = false
var pending_freeze: bool = false


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
	
	for child in status_container.get_children():
		child.queue_free()
	
	if not player_stats:
		return
	
	# Добавляем статусы
	for status_id in player_stats.active_statuses.keys():
		var status_data = player_stats.active_statuses[status_id]
		var status_resource = status_data["resource"]
		
		var icon_data = {
			"status_id": status_id,
			"icon": DataManager.get_status_icon(status_id),
			"stacks": status_data.stacks,
			"duration": status_data.duration,
			"name": DataManager.get_status_name(status_id)
		}
		
		var icon = STATUS_ICON_SCENE.instantiate() as StatusIcon
		status_container.add_child(icon)
		icon.setup(icon_data, DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT, self)  # светлый для игрока
		#DataManager.apply_shader_to_icon(icon.icon, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})
		DataManager.apply_shader_overlay(icon.icon, "res://shaders/horror_shader.gdshader", {})
	
	# Добавляем пассивки
	for passive in player_stats.active_passives:
		var icon_data = {
			"passive_id": passive.id,
			"icon": DataManager.get_passive_icon(passive.id),
			"name": passive.get_localized_name(),
			"description": passive.get_localized_description(),
			"charges": passive.current_charges if passive.has_charges() else 0
		}
		
		var icon = PASSIVE_ICON_SCENE.instantiate() as PassiveIcon
		status_container.add_child(icon)
		icon.setup(icon_data, DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT, self)  # светлый для игрока
		#DataManager.apply_shader_to_icon(icon.icon, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})
		DataManager.apply_shader_overlay(icon.icon, "res://shaders/horror_shader.gdshader", {})


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


func _init_ice_texture():
	ice_noise = NoiseTexture2D.new()
	ice_noise.seamless = true
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	
	ice_noise.noise = noise


# ===== УДАР (HIT) =====

func apply_hit_effect():
	# Если заморожен или умираем — игнорируем
	if current_shader_priority >= DataManager.EnemyShaderPriority.FREEZE:
		return
	
	if not portrait_texture:
		return
	
	# Сохраняем базовый материал
	if not _base_portrait_material:
		_base_portrait_material = portrait_texture.material
	
	# Применяем шейдер удара (можно использовать тот же hit шейдер, что и у врага)
	var shader = preload("res://shaders/get_hit_shader.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("hit_progress", 1.0)
	
	portrait_texture.material = shader_material
	current_shader_priority = DataManager.EnemyShaderPriority.HIT
	
	if hit_tween:
		hit_tween.kill()
	
	hit_tween = create_tween()
	hit_tween.tween_property(shader_material, "shader_parameter/hit_progress", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
	
	await hit_tween.finished
	hit_tween = null
	
	_on_hit_finished()


func _on_hit_finished():
	# Проверяем, не нужно ли заморозить
	if pending_freeze:
		pending_freeze = false
		_apply_freeze_effect_immediate()
		return
	
	# Возвращаем базовый материал
	if portrait_texture:
		portrait_texture.material = _base_portrait_material
	
	current_shader_priority = DataManager.EnemyShaderPriority.NONE


# ===== ЗАМОРОЗКА (FREEZE) =====

func apply_freeze_effect():
	# Если умираем — откладываем заморозку
	if current_shader_priority == DataManager.EnemyShaderPriority.DEATH:
		pending_freeze = true
		return
	
	# Если уже есть заморозка — не применяем повторно
	if current_shader_priority == DataManager.EnemyShaderPriority.FREEZE:
		return
	
	# Если есть hit — дожидаемся его окончания
	if current_shader_priority == DataManager.EnemyShaderPriority.HIT:
		pending_freeze = true
		return
	
	_apply_freeze_effect_immediate()


func _apply_freeze_effect_immediate():
	current_shader_priority = DataManager.EnemyShaderPriority.FREEZE
	pending_freeze = false
	
	if not portrait_texture:
		return
	
	if not ice_noise:
		_init_ice_texture()
	
	if not _base_portrait_material:
		_base_portrait_material = portrait_texture.material
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = FREEZE_SHADER
	shader_material.set_shader_parameter("ice_cracks_tex", ice_noise)
	shader_material.set_shader_parameter("ice_color", Color("4cb0f2"))
	shader_material.set_shader_parameter("glow_color", Color("99daff"))
	shader_material.set_shader_parameter("freeze_amount", 0.0)
	
	portrait_texture.material = shader_material
	
	if freeze_tween:
		freeze_tween.kill()
	
	freeze_tween = create_tween()
	freeze_tween.tween_property(shader_material, "shader_parameter/freeze_amount", 1.0, 0.6)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)


func remove_freeze_effect():
	pending_freeze = false
	
	if current_shader_priority != DataManager.EnemyShaderPriority.FREEZE:
		return
	
	if not portrait_texture or not portrait_texture.material:
		current_shader_priority = DataManager.EnemyShaderPriority.NONE
		return
	
	if portrait_texture.material is ShaderMaterial:
		var shader_material = portrait_texture.material as ShaderMaterial
		
		if freeze_tween:
			freeze_tween.kill()
		
		freeze_tween = create_tween()
		freeze_tween.tween_property(shader_material, "shader_parameter/freeze_amount", 0.0, 0.4)
		freeze_tween.finished.connect(func(): 
			if portrait_texture:
				portrait_texture.material = _base_portrait_material
			current_shader_priority = DataManager.EnemyShaderPriority.NONE
			freeze_tween = null
		)


# ===== СМЕРТЬ (пока заглушка) =====

func die():
	# Если есть hit — дожидаемся его окончания
	if current_shader_priority == DataManager.EnemyShaderPriority.HIT:
		pending_death = true
		return
	
	# Если есть freeze — сначала убираем его
	if current_shader_priority == DataManager.EnemyShaderPriority.FREEZE:
		remove_freeze_effect()
		if freeze_tween:
			await freeze_tween.finished
	
	_apply_death_effect()


func _apply_death_effect():
	current_shader_priority = DataManager.EnemyShaderPriority.DEATH
	pending_death = false
	
	if not portrait_texture:
		return
	
	# Сохраняем оригинальный материал
	var original_material = portrait_texture.material
	
	# Применяем шейдер смерти
	var shader = preload("res://shaders/death_dissolve.gdshader")
	var death_material = ShaderMaterial.new()
	death_material.shader = shader
	
	# Устанавливаем текстуру шума
	if not ice_noise:
		_init_ice_texture()
	if ice_noise:
		death_material.set_shader_parameter("grunge_noise_tex", ice_noise)
	
	portrait_texture.material = death_material
	
	var tween = create_tween()
	tween.tween_method(_set_death_progress, 0.0, 1.0, 1.0)
	tween.finished.connect(_on_death_animation_finished.bind(death_material, original_material))


func _set_death_progress(value: float):
	if portrait_texture and portrait_texture.material:
		portrait_texture.material.set_shader_parameter("death_progress", value)


func _on_death_animation_finished(death_material: ShaderMaterial, original_material: Material):
	if portrait_texture:
		portrait_texture.material = original_material
	
	current_shader_priority = DataManager.EnemyShaderPriority.NONE
	
	# Сигнал о смерти игрока
	SignalManager.player_death_animation_finished.emit()


func find_status_icon(status_id: int) -> StatusIcon:
	for child in status_container.get_children():
		if child is StatusIcon and child.status_id == status_id:
			return child
	return null


func find_passive_icon(passive_id: int) -> PassiveIcon:
	for child in status_container.get_children():
		if child is PassiveIcon and child.passive_id == passive_id:
			return child
	return null

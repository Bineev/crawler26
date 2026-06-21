# scripts/ui/choice_panel.gd
extends Control
class_name ChoicePanel

var options: Array[Array] = []

func setup(paths: Array[Array]):
	options = paths
	var buttons_container = $VBoxContainer/ButtonsContainer
	buttons_container.add_theme_constant_override("separation", 40)
	
	for i in range(paths.size()):
		var path_container = VBoxContainer.new()
		path_container.alignment = 1
		path_container.add_theme_constant_override("separation", 10)
		
		# Сначала показываем комнаты сверху вниз (начиная с последней)
		var room_count = paths[i].size()
		for j in range(room_count - 1, -1, -1):
			var room = paths[i][j]
			var icon = TextureRect.new()
			# добавить шейдер на обводку
			apply_shader_to_icon(icon, "res://shaders/highlight_enemy.gdshader")
			icon.custom_minimum_size = Vector2(64, 64)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Первая комната (снизу) — видимая
			if j == 0:
				icon.texture = DataManager.get_room_icon(room.room_type, room.combat_type)
				icon.tooltip_text = _get_room_description(room)
				# Добавляем подсветку или рамку для видимой комнаты
				var frame = ColorRect.new()
				frame.color = Color(1, 0.8, 0.2, 0.3)
				frame.size = Vector2(70, 70)
				frame.position = Vector2(-3, -3)
				path_container.add_child(frame)
			elif room.is_revealed:
				icon.texture = DataManager.get_room_icon(room.room_type, room.combat_type)
				icon.tooltip_text = _get_room_description(room)
			else:
				icon.texture = preload("res://img/icons/intents/unknown.png")
				icon.tooltip_text = "???"
			
			path_container.add_child(icon)
			
			# Добавляем стрелку между комнатами (вверх)
			if j > 0:
				var arrow = Label.new()
				arrow.text = "↑"
				arrow.horizontal_alignment = 1
				path_container.add_child(arrow)
		
		# Кнопка выбора пути
		var select_button = Button.new()
		select_button.text = "ВПЕРЕД"
		select_button.pressed.connect(_on_path_selected.bind(i))
		
		# Применяем стиль как у кнопки "Конец хода"
		select_button.add_theme_font_override("font", DataManager.FONT_HEADERS)
		select_button.add_theme_font_size_override("font_size", 20)
		#select_button.add_theme_color_override("font_color", Color(DataManager.COLOR_PENITENT_ART_BG_DARK))
		#select_button.add_theme_color_override("font_hover_color", Color(DataManager.COLOR_PENITENT_ART_BG_DARK))
		select_button.custom_minimum_size = Vector2(200, 60)
		path_container.add_child(select_button)
		
		buttons_container.add_child(path_container)


func _get_room_description(room_node: RoomNode) -> String:
	if not room_node.is_revealed:
		return "???"
	
	match room_node.room_type:
		DataManager.RoomType.COMBAT:
			match room_node.combat_type:
				DataManager.CombatType.NORMAL:
					return "Бой"
				DataManager.CombatType.ELITE:
					return "Сложный бой"
				DataManager.CombatType.BOSS:
					return "Босс"
		DataManager.RoomType.EVENT:
			return "Событие"
		DataManager.RoomType.OBJECT:
			return "Объект"
	
	return "???"


func _on_path_selected(path_index: int):
	SignalManager.choice_panel_selected.emit(path_index)
	queue_free()


# Добавление шейдера на TextureRect
func apply_shader_to_icon(icon: TextureRect, shader_path: String):
	var shader = load(shader_path)
	if not shader:
		print("Shader not found: ", shader_path)
		return
	
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	shader_material.set_shader_parameter("hover_intensity", 1.0)
	shader_material.set_shader_parameter("pulse_speed", 0)
	icon.material = shader_material


func _create_button_style(bg_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.3, 0.2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

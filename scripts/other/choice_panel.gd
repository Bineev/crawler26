# scripts/ui/choice_panel.gd
extends Control
class_name ChoicePanel

var options: Array[Array] = []

func setup(paths: Array):
	scale *= DataManager.SCALE_FACTOR
	options = paths
	var buttons_container = $VBoxContainer/ButtonsContainer
	var title = $VBoxContainer/Title
	title.text = tr("choice_panel_title")
	title.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 40)

	
	for i in range(paths.size()):
		var path_container = VBoxContainer.new()
		path_container.alignment = 1
		path_container.add_theme_constant_override("separation", 20)
		path_container.custom_minimum_size = Vector2(200, 0)
		
		# Показываем комнаты сверху вниз (начиная с последней)
		var room_count = paths[i].size()
		for j in range(room_count - 1, -1, -1):
			var room = paths[i][j]
			
			# 🆕 Создаём Label вместо иконки
			var label = Label.new()
			var label_text = DataManager.get_room_label(room)
			label.text = label_text
			label.add_theme_font_override("font", DataManager.FONT_HEADERS)
			label.add_theme_font_size_override("font_size", 30)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			
			# Цвет в зависимости от типа и видимости
			if not room.is_revealed:
				label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))  # тёмно-серый
				label.text = "???"
			else:
				match room.room_type:
					DataManager.RoomType.COMBAT:
						match room.combat_type:
							DataManager.CombatType.NORMAL:
								label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
							DataManager.CombatType.ELITE:
								label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
							_:
								label.add_theme_color_override("font_color", Color.WHITE)
					DataManager.RoomType.OBJECT:
						label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
					_:
						label.add_theme_color_override("font_color", Color.WHITE)
			
			path_container.add_child(label)
			
			# Добавляем стрелку между комнатами (вверх)
			if j > 0:
				var arrow = Label.new()
				arrow.text = "↑"
				arrow.horizontal_alignment = 1
				arrow.add_theme_font_size_override("font_size", 30)
				arrow.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
				path_container.add_child(arrow)
		
		# Кнопка выбора пути
		var select_button = DataManager.create_button(tr("button_path_go"), DataManager.ButtonType.PRIMARY)
		select_button.text = tr("button_path_go")
		select_button.pressed.connect(_on_path_selected.bind(i))
		path_container.add_child(select_button)
		
		buttons_container.add_child(path_container)


func _on_path_selected(path_index: int):
	SignalManager.choice_panel_selected.emit(path_index)
	queue_free()

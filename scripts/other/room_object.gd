extends TextureRect
class_name RoomObject

var object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST
var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var _tween: Tween = null
var event_data: EventResource = null
# 🆕 Подсветка
var highlight_material: ShaderMaterial = null
var base_material: Material = null
var narrative_label: Label = null
var event_texture_rect : TextureRect
var _is_hovered: bool = false
var _is_interacting: bool = false  # 🆕 флаг, что объект уже взаимодействует
var is_shop: bool = false
@onready var shadow_sprite: TextureRect = $EnemySpriteCopy


func _ready() -> void:
	# Подключаем сигналы мыши
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	SignalManager.hide_object.connect(_on_hide_object)


func setup(type: DataManager.ObjectType, biome: DataManager.Biome, event_res: EventResource = null) -> void:
	object_type = type
	self.biome = biome

	# 🆕 Получаем размер из DataManager
	var obj_size = DataManager.get_object_size(object_type)
	custom_minimum_size = obj_size
	is_shop = (type == DataManager.ObjectType.SHOP)
	# 🆕 Получаем текстуру из DataManager
	var texture = DataManager.get_object_texture(object_type, biome)
	if is_shop:
		# Магазин — отдельная логика позиционирования и текстуры
		if texture:
			self.texture = texture
			#BUG
			expand_mode = TextureRect.EXPAND_FIT_WIDTH
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			set_anchors_preset(Control.PRESET_TOP_LEFT)
			position = Vector2.ZERO
		
		# Отключаем клики и подсветку
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		await get_tree().create_timer(4).timeout
		interact()
		return
	# 🆕 Логика для EVENT
	if object_type == DataManager.ObjectType.EVENT:
		#self.texture = DataManager.get_object_texture(DataManager.ObjectType.SHOP, DataManager.Biome.MOLE_TUNNELS)
		event_data = event_res
		expand_mode = TextureRect.EXPAND_FIT_WIDTH
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		set_anchors_preset(Control.PRESET_TOP_LEFT)
		position = Vector2.ZERO
		if event_data:
			# 🆕 Вместо текстуры — добавляем черный ColorRect на всю комнату
			var black_overlay = ColorRect.new()
			black_overlay.color = Color(0, 0, 0, 1)
			black_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
			black_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(black_overlay)
			# 🆕 Добавляем MarginContainer
			var margin_container = MarginContainer.new()
			margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)
			margin_container.add_theme_constant_override("margin_left", 50)
			margin_container.add_theme_constant_override("margin_top", 50)
			margin_container.add_theme_constant_override("margin_right", 50)
			margin_container.add_theme_constant_override("margin_bottom", 50)
			black_overlay.add_child(margin_container)
			
			# 🆕 Добавляем VBoxContainer
			var vbox = VBoxContainer.new()
			vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
			vbox.add_theme_constant_override("separation", 20)
			margin_container.add_child(vbox)
			
			# 🆕 Добавляем TextureRect с картинкой события
			event_texture_rect = TextureRect.new()
			event_texture_rect.custom_minimum_size = DataManager.EVENT_TEXTURE_SIZE
			event_texture_rect.size = DataManager.EVENT_TEXTURE_SIZE
			event_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			event_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			event_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			event_texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			
			var event_texture = DataManager.get_event_texture(event_data.event_type, biome)
			if event_texture:
				event_texture_rect.texture = event_texture
			
			vbox.add_child(event_texture_rect)
			await get_tree().create_timer(1.5).timeout
			# 🆕 Создаём и сохраняем Label для нарратива
			narrative_label = Label.new()
			narrative_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
			narrative_label.add_theme_font_size_override("font_size", 22)
			narrative_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
			narrative_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			narrative_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			narrative_label.custom_minimum_size = DataManager.EVENT_LABEL_SIZE
			narrative_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			vbox.add_child(narrative_label)

		# Отключаем клики
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Запускаем печать нарратива
		await print_narrative(event_data.get_localized_narrative())
		await get_tree().create_timer(3).timeout
		# После печати вызываем interact()
		interact()
		return
	if texture:
		self.texture = texture
		shadow_sprite.texture = texture
		shadow_sprite.custom_minimum_size = obj_size

		# 🆕 Создаём копию материала для этого объекта
		if shadow_sprite.material:
			shadow_sprite.material = shadow_sprite.material.duplicate()
		
		# 🆕 Настраиваем параметры тени
		_setup_shadow_parameters(object_type)
	else:
		# Текстура-заглушка, если не найдена
		printerr("Object texture not found for type: ", object_type, " biome: ", biome)
	# 🆕 Запускаем призывную анимацию
	# 🆕 Настраиваем подсветку
	_setup_highlight()
	_start_idle_animation()
	# 🆕 Подключаем сигнал клика
	gui_input.connect(_on_gui_input)

func interact() -> void:
	if _is_interacting:
		return
	
	_is_interacting = true
	
	SignalManager.hide_room_object_title.emit()
	
	# 🆕 Отключаем интерактивность
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_highlight(false)
	
	# Останавливаем анимацию
	if _tween:
		_tween.kill()
		_tween = null
	
	SignalManager.log_message.emit('Start interracting')
	match object_type:
		DataManager.ObjectType.CHEST:
			_interact_chest()
		DataManager.ObjectType.IDOL:
			_interact_idol()
		DataManager.ObjectType.TRAP:
			_interact_trap()
		DataManager.ObjectType.CAULDRON:
			_interact_cauldron()
		DataManager.ObjectType.TORTURE_RACK:
			_interact_torture_rack()
		DataManager.ObjectType.BONFIRE:
			_interact_bonfire()
		DataManager.ObjectType.SHOP:
			_interact_shop()
		DataManager.ObjectType.EVENT:  # 🆕
			_interact_event()


func _start_idle_animation() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_loops()
	
	# Поднимаемся на 8 пикселей вверх
	_tween.tween_property(self, "scale", Vector2(1.01, 1.01), 2).set_ease(Tween.EASE_IN_OUT)
	# Опускаемся обратно на 8 пикселей вниз
	_tween.tween_property(self, "scale", Vector2(0.99, 0.99), 2).set_ease(Tween.EASE_IN_OUT)


func _setup_highlight() -> void:
	# Сохраняем базовый материал
	base_material = material
	
	# Загружаем шейдер подсветки
	var shader = preload("res://shaders/highlight_enemy.gdshader")
	highlight_material = ShaderMaterial.new()
	highlight_material.shader = shader
	highlight_material.set_shader_parameter("hover_intensity", 0.0)


func _exit_tree() -> void:
	if _tween:
		_tween.kill()
		_tween = null


func _on_mouse_entered() -> void:
	if _is_interacting:
		return
	_is_hovered = true
	_apply_highlight(true)

func _on_mouse_exited() -> void:
	if _is_interacting:
		return
	_is_hovered = false
	_apply_highlight(false)

func _apply_highlight(enabled: bool) -> void:
	if not highlight_material:
		return
	
	if enabled:
		# Сохраняем текущий материал, если ещё не сохранили
		if not base_material:
			base_material = material
		
		highlight_material.set_shader_parameter("hover_intensity", 1.0)
		material = highlight_material
	else:
		material = base_material
		highlight_material.set_shader_parameter("hover_intensity", 0.0)


func _on_gui_input(event: InputEvent) -> void:
	if _is_interacting:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		interact()


func _interact_trap() -> void:
	var actions: Array[DataManager.ActionType] = [
		DataManager.ActionType.DISARM_TRAP,
		DataManager.ActionType.SEARCH_TRAP
	]
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("trap_title"), actions)


func _interact_chest() -> void:
	var has_key = RunManager.get_keys() > 0
	var actions: Array[DataManager.ActionType] = []
	
	if has_key:
		actions.append(DataManager.ActionType.USE_KEY)
	actions.append(DataManager.ActionType.BREAK)
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	# 🆕 Не вызываем setup здесь, только передаём данные
	SignalManager.add_action_choice.emit(action_choice, "Выберите действие", actions)


func _interact_bonfire() -> void:
	var actions: Array[DataManager.ActionType] = [
		DataManager.ActionType.REST,
		DataManager.ActionType.PRAY,
		DataManager.ActionType.SHARP_WEAPON
	]
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("bonfire_title"), actions)


func _interact_idol() -> void:
	var actions: Array[DataManager.ActionType] = []
	
	# Проверяем, есть ли достаточно костей для подношения
	if RunManager.get_bones() >= DataManager.MIN_BONES_FOR_IDOL:
		actions.append(DataManager.ActionType.MAKE_OFFERING)
	
	actions.append(DataManager.ActionType.GIVE_BLOOD)
	actions.append(DataManager.ActionType.LOOT_SHRINE)
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("idol_title"), actions)


func _on_hide_object() -> void:
	# Отключаем интерактивность
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_highlight(false)
	
	if _tween:
		_tween.kill()
		_tween = null
	
	# 🆕 Исчезаем с анимацией
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.3)
	await tween.finished
	queue_free()


func _interact_cauldron() -> void:
	var actions: Array[DataManager.ActionType] = [
		DataManager.ActionType.TRANSFORM_CARD,
		DataManager.ActionType.BREW_POTION
	]
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("cauldron_title"), actions)


func _interact_torture_rack() -> void:
	var actions: Array[DataManager.ActionType] = [
		DataManager.ActionType.LOSE_FLESH,
		DataManager.ActionType.CRAFT
	]
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("torture_rack_title"), actions)


func _interact_shop() -> void:
	var actions: Array[DataManager.ActionType] = [
		DataManager.ActionType.TRADE,
		DataManager.ActionType.ROB
	]
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	SignalManager.add_action_choice.emit(action_choice, tr("shop_title"), actions)


func _interact_event() -> void:
	var actions: Array[DataManager.ActionType] = event_data.get_actions()
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	action_choice.event_data = event_data  # 🆕 передаём данные события
	action_choice.room_object = self  # 🆕 передаём ссылку на RoomObject
	SignalManager.add_action_choice.emit(action_choice, event_data.get_localized_name(), actions)


func print_narrative(text: String):
	if not narrative_label:
		return
	
	if text.is_empty():
		return
	
	# Очищаем label и делаем его прозрачным
	narrative_label.text = ""
	narrative_label.modulate = Color(1, 1, 1, 0)
	
	# Разбиваем текст на слова
	var words = text.split(" ", false)
	var word_delay: float = 0.12
	
	# Сразу запускаем анимацию появления лейбла
	var fade_tween = create_tween()
	fade_tween.tween_property(narrative_label, "modulate", Color(1, 1, 1, 1), words.size() * word_delay + 0.2)
	
	for word in words:
		narrative_label.text += word + " "
		await get_tree().create_timer(word_delay).timeout
	
	# 🆕 Возвращаем label, чтобы на него можно было повесить обработчик клика
	return narrative_label


func _setup_shadow_parameters(object_type: DataManager.ObjectType) -> void:
	if not shadow_sprite or not shadow_sprite.material:
		return
	
	var mat = shadow_sprite.material
	if not mat is ShaderMaterial:
		return
	
	match object_type:
		DataManager.ObjectType.CAULDRON:
			mat.set_shader_parameter("shadow_height", 0.620)
			mat.set_shader_parameter("shadow_width", 1.0)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.07)
		
		DataManager.ObjectType.TRAP:
			mat.set_shader_parameter("shadow_height", 0.8)
			mat.set_shader_parameter("shadow_width", 0.9)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.09)
		
		DataManager.ObjectType.TORTURE_RACK:
			mat.set_shader_parameter("shadow_height", 0.55)
			mat.set_shader_parameter("shadow_width", 0.93)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.145)
		
		DataManager.ObjectType.IDOL:
			mat.set_shader_parameter("shadow_height", 0.255)
			mat.set_shader_parameter("shadow_width", 1.09)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.1)
		
		DataManager.ObjectType.CHEST:
			# Можно оставить дефолтные или настроить отдельно
			mat.set_shader_parameter("shadow_height", 0.7)
			mat.set_shader_parameter("shadow_width", 1.0)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.03)
		
		DataManager.ObjectType.BONFIRE:
			mat.set_shader_parameter("shadow_height", 0.63)
			mat.set_shader_parameter("shadow_width", 0.95)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.095)
		
		DataManager.ObjectType.SHOP, DataManager.ObjectType.EVENT:
			# Для этих объектов тень не нужна или другая логика
			shadow_sprite.visible = false
		
		_:
			# Дефолтные значения
			mat.set_shader_parameter("shadow_height", 0.35)
			mat.set_shader_parameter("shadow_width", 0.8)
			mat.set_shader_parameter("shadow_skew", 0.0)
			mat.set_shader_parameter("vertical_offset", 0.05)

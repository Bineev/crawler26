extends TextureRect
class_name RoomObject

var object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST
var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var _tween: Tween = null
# 🆕 Подсветка
var highlight_material: ShaderMaterial = null
var base_material: Material = null
var _is_hovered: bool = false
var _is_interacting: bool = false  # 🆕 флаг, что объект уже взаимодействует
@onready var shadow_sprite: TextureRect = $EnemySpriteCopy


func _ready() -> void:
	# Подключаем сигналы мыши
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	SignalManager.hide_object.connect(_on_hide_object)


func setup(type: DataManager.ObjectType, biome: DataManager.Biome) -> void:
	object_type = type
	self.biome = biome

	# 🆕 Получаем размер из DataManager
	var obj_size = DataManager.get_object_size(object_type)
	custom_minimum_size = obj_size
	
	# 🆕 Получаем текстуру из DataManager
	var texture = DataManager.get_object_texture(object_type, biome)
	if texture:
		self.texture = texture
		shadow_sprite.texture = texture
		shadow_sprite.custom_minimum_size = obj_size
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
			pass
		DataManager.ObjectType.IDOL:
			# TODO: взаимодействие с идолом
			pass
		DataManager.ObjectType.TRAP:
			# TODO: ловушка
			pass
		DataManager.ObjectType.CAULDRON:
			# TODO: котёл
			pass
		DataManager.ObjectType.TORTURE_RACK:
			# TODO: пыточный стол
			pass
		DataManager.ObjectType.BONFIRE:
			# TODO: костёр
			pass


func _start_idle_animation() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_loops()
	
	# Поднимаемся на 8 пикселей вверх
	_tween.tween_property(self, "position", Vector2(0, -2), 3).as_relative().set_ease(Tween.EASE_IN_OUT)
	# Опускаемся обратно на 8 пикселей вниз
	_tween.tween_property(self, "position", Vector2(0, 2), 3).as_relative().set_ease(Tween.EASE_IN_OUT)


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


func _interact_chest() -> void:
	var has_key = RunManager.get_keys() > 0
	var actions: Array[DataManager.ActionType] = []
	
	if has_key:
		actions.append(DataManager.ActionType.USE_KEY)
	actions.append(DataManager.ActionType.BREAK)
	
	var action_choice = preload("res://scenes/action_choice.tscn").instantiate() as ActionChoice
	# 🆕 Не вызываем setup здесь, только передаём данные
	SignalManager.add_action_choice.emit(action_choice, "Выберите действие", actions)


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

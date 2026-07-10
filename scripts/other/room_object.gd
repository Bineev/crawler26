extends TextureRect
class_name RoomObject

var object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST
var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var _tween: Tween = null
# 🆕 Подсветка
var highlight_material: ShaderMaterial = null
var base_material: Material = null
var _is_hovered: bool = false


func _ready() -> void:
	# Подключаем сигналы мыши
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(type: DataManager.ObjectType, biome: DataManager.Biome) -> void:
	object_type = type
	self.biome = biome
	
	# 🆕 Получаем текстуру из DataManager
	var texture = DataManager.get_object_texture(object_type, biome)
	if texture:
		self.texture = texture
	else:
		# Текстура-заглушка, если не найдена
		printerr("Object texture not found for type: ", object_type, " biome: ", biome)
	custom_minimum_size = Vector2(196, 196)
	# 🆕 Запускаем призывную анимацию
	# 🆕 Настраиваем подсветку
	_setup_highlight()
	_start_idle_animation()

func interact() -> void:
	match object_type:
		DataManager.ObjectType.CHEST:
			# TODO: открыть сундук → награда
			pass
		DataManager.ObjectType.SHOP:
			# TODO: открыть магазин
			pass
		# ... остальные типы


func _start_idle_animation() -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.set_loops()
	
	# Поднимаемся на 8 пикселей вверх
	_tween.tween_property(self, "position", Vector2(0, -8), 1.2).as_relative().set_ease(Tween.EASE_IN_OUT)
	# Опускаемся обратно на 8 пикселей вниз
	_tween.tween_property(self, "position", Vector2(0, 8), 1.2).as_relative().set_ease(Tween.EASE_IN_OUT)


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
	_is_hovered = true
	_apply_highlight(true)

func _on_mouse_exited() -> void:
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

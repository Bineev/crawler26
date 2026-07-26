# scripts/room/room.gd
extends Control
class_name Room

var background: TextureRect = null
var content: Node2D = null
var dark_overlay: ColorRect = null
var horror_overlay: ColorRect = null

var room_type: DataManager.RoomType = DataManager.RoomType.COMBAT
var _pending_background_texture: Texture2D = null
var _pending_room_data: Dictionary = {}

var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

func _ready():
	background = $Background
	content = $Content
	dark_overlay = $DarkOverlay
	horror_overlay = $HorrorOverlay
	SignalManager.getting_all_rewards.connect(_on_getting_all_rewards)
	
	# Применяем отложенные данные
	if _pending_background_texture and background:
		background.texture = _pending_background_texture
	
	if not _pending_room_data.is_empty():
		await _init_content(_pending_room_data)
		_pending_room_data.clear()
	_setup_dark_overlay()
	_setup_horror_overlay()
		# Анимация входа
	_enter_room_animation()


func _setup_dark_overlay():
	if not dark_overlay:
		return
	
	dark_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	dark_overlay.anchor_left = 0.0
	dark_overlay.anchor_top = 0.0
	dark_overlay.anchor_right = 1.0
	dark_overlay.anchor_bottom = 1.0
	dark_overlay.size = Vector2.ZERO

func setup(room_data: Dictionary):
	room_type = room_data.get("type", DataManager.RoomType.COMBAT)
	
	var biome = room_data.get("biome", DataManager.Biome.MOLE_TUNNELS)
	var background_texture = room_data.get("background", null)
	if not background_texture:
		background_texture = DataManager.get_random_background(biome)
	
	_pending_background_texture = background_texture
	_pending_room_data = room_data

func _setup_horror_overlay():
	if not horror_overlay:
		return
	
	horror_overlay.color = Color.WHITE
	horror_overlay.anchor_left = 0.0
	horror_overlay.anchor_top = 0.0
	horror_overlay.anchor_right = 1.0
	horror_overlay.anchor_bottom = 1.0
	horror_overlay.size = Vector2.ZERO
	
	var shader_material = ShaderMaterial.new()
	var shader = preload("res://shaders/horror_shader.gdshader")
	shader_material.shader = shader
	
	shader_material.set_shader_parameter("grain_amount", 0.1)
	shader_material.set_shader_parameter("scanline_intensity", 0.1)
	shader_material.set_shader_parameter("vignette_intensity", 2)
	shader_material.set_shader_parameter("glitch_amount", 0)
	shader_material.set_shader_parameter("pulse_intensity", 0.05)
	shader_material.set_shader_parameter("chromatic_amount", 0)
	
	horror_overlay.material = shader_material


func _init_content(room_data: Dictionary):
	pass


func clear_content():
	if content:
		for child in content.get_children():
			child.queue_free()


func get_content_container() -> Node2D:
	return content


func get_room_type() -> DataManager.RoomType:
	return room_type


func _close_room_animation() -> void:
	# Затемнение
	var dark_overlay = ColorRect.new()
	dark_overlay.color = Color(0, 0, 0, 0)
	dark_overlay.size = get_viewport().get_visible_rect().size
	dark_overlay.position = Vector2.ZERO
	dark_overlay.z_index = 100
	add_child(dark_overlay)
	
	# Включаем обрезку для комнаты, чтобы контент не выходил за границы
	clip_contents = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Затемнение
	tween.tween_property(dark_overlay, "color", Color(0, 0, 0, 1), 0.5)
	
	# Масштабируем только background, а не всю комнату
	var room_size = background.size
	var target_scale = 1.5
	var center = background.global_position + room_size / 2
	var new_size = room_size * target_scale
	var new_pos = center - new_size / 2
	
	if background:
		tween.tween_property(background, "scale", Vector2(target_scale, target_scale), 0.5)
		tween.tween_property(background, "global_position", new_pos, 0.5)
	
	# Также масштабируем контент (врагов, объекты)
	if content:
		tween.tween_property(content, "scale", Vector2(target_scale, target_scale), 0.5)
		tween.tween_property(content, "global_position", new_pos, 0.5)
	
	await tween.finished
	await get_tree().create_timer(0.1).timeout


#func _enter_room_animation() -> void:
	## Затемнение
	#var dark_overlay = ColorRect.new()
	#dark_overlay.color = Color(0, 0, 0, 1)
	#dark_overlay.size = get_viewport().get_visible_rect().size
	#dark_overlay.position = Vector2.ZERO
	#dark_overlay.z_index = 100
	#add_child(dark_overlay)
	#
	## Получаем размер и позицию background
	#var bg_global_pos = background.global_position
	#var bg_size = background.size
	#var center_x = bg_global_pos.x + bg_size.x / 2
	#var door_width = bg_size.x / 2
	#
	## Левая створка
	#var left_door = ColorRect.new()
	#left_door.color = Color(0, 0, 0)
	#left_door.size = Vector2(door_width, bg_size.y)
	#left_door.position = Vector2(center_x - door_width, bg_global_pos.y)
	#left_door.z_index = 101
	#add_child(left_door)
	#
	## Правая створка
	#var right_door = ColorRect.new()
	#right_door.color = Color(0, 0, 0)
	#right_door.size = Vector2(door_width, bg_size.y)
	#right_door.position = Vector2(center_x, bg_global_pos.y)
	#right_door.z_index = 101
	#add_child(right_door)
	#
	#var tween = create_tween()
	#tween.set_parallel(true)
	#
	## Левая створка уезжает влево
	#tween.tween_property(left_door, "position", Vector2(center_x - door_width - door_width, bg_global_pos.y), 0.7).set_ease(Tween.EASE_OUT)
	#
	## Правая створка уезжает вправо
	#tween.tween_property(right_door, "position", Vector2(center_x + door_width, bg_global_pos.y), 0.7).set_ease(Tween.EASE_OUT)
	#
	## Затемнение исчезает
	#tween.tween_property(dark_overlay, "color", Color(0, 0, 0, 0), 1)
	#
	#await tween.finished
	#
	#left_door.queue_free()
	#right_door.queue_free()
	#dark_overlay.queue_free()

func _enter_room_animation() -> void:
	# Включаем обрезку для комнаты, чтобы контент не выходил за границы
	clip_contents = true
	# Затемнение
	var dark_overlay = ColorRect.new()
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dark_overlay.color = Color(0, 0, 0, 1)
	dark_overlay.size = get_viewport().get_visible_rect().size
	dark_overlay.position = Vector2.ZERO
	dark_overlay.z_index = 100
	add_child(dark_overlay)
	
	# Получаем размер и позицию background
	var bg_global_pos = background.global_position
	var bg_size = background.size
	var center_x = bg_global_pos.x + bg_size.x / 2
	var door_width = bg_size.x / 2
	
	# Левая створка
	var left_door = ColorRect.new()
	left_door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_door.color = Color(0, 0, 0)
	left_door.size = Vector2(door_width, bg_size.y)
	left_door.position = Vector2(center_x - door_width, bg_global_pos.y)
	left_door.z_index = 101
	add_child(left_door)
	
	# Правая створка
	var right_door = ColorRect.new()
	right_door.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_door.color = Color(0, 0, 0)
	right_door.size = Vector2(door_width, bg_size.y)
	right_door.position = Vector2(center_x, bg_global_pos.y)
	right_door.z_index = 101
	add_child(right_door)
	
	var tween = create_tween()
	
	# Этап 1: Открываем на четверть (с задержкой 0.1)
	tween.set_parallel(true)
	
	# Левая створка на четверть влево
	var quarter_open = door_width * 0.25
	tween.tween_property(left_door, "position", Vector2(center_x - door_width - quarter_open, bg_global_pos.y), 0.15).set_ease(Tween.EASE_OUT)
	
	# Правая створка на четверть вправо
	tween.tween_property(right_door, "position", Vector2(center_x + quarter_open, bg_global_pos.y), 0.15).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	
	# Этап 2: Застывание (пауза 0.3 сек)
	await get_tree().create_timer(0.3).timeout
	
	# Этап 3: Отскок назад на немного (на 10% обратно)
	var bounce_back = door_width * 0.1
	tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(left_door, "position", Vector2(center_x - door_width - quarter_open + bounce_back, bg_global_pos.y), 0.08).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(right_door, "position", Vector2(center_x + quarter_open - bounce_back, bg_global_pos.y), 0.08).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished
	
	# Этап 4: Пауза 0.1 сек
	await get_tree().create_timer(0.1).timeout
	
	# Этап 5: Полное открытие
	tween = create_tween()
	tween.set_parallel(true)
	
	# Левая створка полностью влево
	tween.tween_property(left_door, "position", Vector2(center_x - door_width - door_width, bg_global_pos.y), 0.4).set_ease(Tween.EASE_OUT)
	
	# Правая створка полностью вправо
	tween.tween_property(right_door, "position", Vector2(center_x + door_width, bg_global_pos.y), 0.4).set_ease(Tween.EASE_OUT)
	
	# Затемнение исчезает
	tween.tween_property(dark_overlay, "color", Color(0, 0, 0, 0), 1.5)
	
	await tween.finished
	
	left_door.queue_free()
	right_door.queue_free()
	dark_overlay.queue_free()


## Показывает панель наград
## По умолчанию — ничего не делает, переопределяется в наследниках
func show_rewards() -> void:
	pass


## Завершает работу комнаты и переходит к следующей
func exit_room() -> void:
	await _close_room_animation()
	GameTestManager.clear_ui()
	FloorManager.process_next()
	queue_free()


func _on_getting_all_rewards():
	exit_room()

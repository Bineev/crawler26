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


func _ready():
	background = $Background
	content = $Content
	dark_overlay = $DarkOverlay
	horror_overlay = $HorrorOverlay
	
	# Настраиваем оверлеи
	_setup_dark_overlay()
	_setup_horror_overlay()
	
	# Применяем отложенные данные
	if _pending_background_texture and background:
		background.texture = _pending_background_texture
	
	if not _pending_room_data.is_empty():
		_init_content(_pending_room_data)
		_pending_room_data.clear()


# В Room.gd _setup_overlay() добавить:

func _setup_dark_overlay():
	if not dark_overlay:
		return
	
	dark_overlay.color = Color(0.05, 0.02, 0.03, 0.6)
	dark_overlay.anchor_left = 0.0
	dark_overlay.anchor_top = 0.0
	dark_overlay.anchor_right = 1.0
	dark_overlay.anchor_bottom = 1.0
	dark_overlay.size = Vector2.ZERO
	
	# Применяем шейдер к dark_overlay
	var shader_material = ShaderMaterial.new()
	var shader = preload("res://shaders/mood_shader.gdshader")
	shader_material.shader = shader
	
	# Настраиваем параметры шейдера
	shader_material.set_shader_parameter("darkness", 0.3)
	shader_material.set_shader_parameter("vignette_strength", 0.4)
	shader_material.set_shader_parameter("tint_color", Color(0.15, 0.05, 0.08))
	
	dark_overlay.material = shader_material


func _setup_horror_overlay():
	if not horror_overlay:
		return
	
	# Важно: белый цвет с низкой прозрачностью
	horror_overlay.color = Color.WHITE
	horror_overlay.modulate = Color(1, 1, 1, 0.4)  # 40% прозрачности
	
	horror_overlay.anchor_left = 0.0
	horror_overlay.anchor_top = 0.0
	horror_overlay.anchor_right = 1.0
	horror_overlay.anchor_bottom = 1.0
	horror_overlay.size = Vector2.ZERO
	
	var shader_material = ShaderMaterial.new()
	var shader = preload("res://shaders/horror_shader.gdshader")
	shader_material.shader = shader
	
	# Важно: darkness должен быть 0, чтобы не затемнять дополнительно
	shader_material.set_shader_parameter("darkness", 0.0)
	shader_material.set_shader_parameter("noise_amount", 0.05)
	shader_material.set_shader_parameter("flicker_speed", 2.0)
	
	horror_overlay.material = shader_material


func setup(room_data: Dictionary):
	room_type = room_data.get("type", DataManager.RoomType.COMBAT)
	
	var biome = room_data.get("biome", DataManager.Biome.MOLE_TUNNELS)
	var background_texture = room_data.get("background", null)
	if not background_texture:
		background_texture = DataManager.get_random_background(biome)
	
	_pending_background_texture = background_texture
	_pending_room_data = room_data


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

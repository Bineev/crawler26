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
	
	
	# Применяем отложенные данные
	if _pending_background_texture and background:
		background.texture = _pending_background_texture
	
	if not _pending_room_data.is_empty():
		_init_content(_pending_room_data)
		_pending_room_data.clear()
	_setup_dark_overlay()
	_setup_horror_overlay()


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

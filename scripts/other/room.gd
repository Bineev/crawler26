# scripts/room/room.gd
extends Control
class_name Room

var background: TextureRect = null
var content: Node2D = null

var room_type: DataManager.RoomType = DataManager.RoomType.COMBAT

# Данные для отложенной инициализации
var _pending_background_texture: Texture2D = null
var _pending_room_data: Dictionary = {}


func _ready():
	# Ищем ноды вручную после добавления в дерево
	background = $Background
	content = $Content
	
	# Применяем отложенные данные
	if _pending_background_texture and background:
		background.texture = _pending_background_texture
	
	if not _pending_room_data.is_empty():
		_init_content(_pending_room_data)
		_pending_room_data.clear()


## Параметризация (вызывается ДО добавления в дерево)
func setup(room_data: Dictionary):
	room_type = room_data.get("type", DataManager.RoomType.COMBAT)
	
	var biome = room_data.get("biome", DataManager.Biome.MOLE_TUNNELS)
	var background_texture = room_data.get("background", null)
	if not background_texture:
		background_texture = DataManager.get_random_background(biome)
	
	# Сохраняем для отложенной инициализации
	_pending_background_texture = background_texture
	_pending_room_data = room_data


## Инициализация контента (переопределяется в дочерних классах)
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

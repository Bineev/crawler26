# scripts/room/object_room.gd
extends Room
class_name ObjectRoom

var object_type: DataManager.ObjectType
var room_object: RoomObject = null


func _ready():
	super._ready()


func setup(room_data: Dictionary) -> void:
	object_type = room_data.get("object_type", DataManager.ObjectType.CHEST)
	super.setup(room_data)

func _init_content(room_data: Dictionary) -> void:
	# Создаём объект комнаты
	var object_scene = preload("res://scenes/room_object.tscn")
	room_object = object_scene.instantiate() as RoomObject
	content.add_child(room_object)
	if object_type == DataManager.ObjectType.SHOP or object_type == DataManager.ObjectType.EVENT:
		# Магазин занимает всю комнату
		room_object.position = Vector2.ZERO
		room_object.custom_minimum_size = Vector2(DataManager.ROOM_WIDTH, DataManager.ROOM_HEIGHT)
	else:
		# 🆕 Устанавливаем позицию
		var room_center_x = DataManager.ROOM_CENTER_X
		var room_height = DataManager.ROOM_HEIGHT
		var y_offset_from_bottom = DataManager.ENEMY_Y_OFFSET_FROM_BOTTOM
		
		room_object.position = Vector2(
			room_center_x - room_object.size.x / 2,
			DataManager.ROOM_HEIGHT - y_offset_from_bottom
		)
	room_object.setup(object_type, current_biome)
	SignalManager.log_message.emit("Object room initialized")
	print("Object room initialized")

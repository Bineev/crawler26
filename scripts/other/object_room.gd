# scripts/room/object_room.gd
extends Room
class_name ObjectRoom

var object_type: DataManager.ObjectType
var room_object: RoomObject = null

func setup(room_data: Dictionary) -> void:
	object_type = room_data.get("object_type", DataManager.ObjectType.CHEST)
	super.setup(room_data)

func _init_content(room_data: Dictionary) -> void:
	# Создаём объект комнаты
	var object_scene = preload("res://scenes/room_object.tscn")
	room_object = object_scene.instantiate() as RoomObject
	content.add_child(room_object)
	room_object.setup(object_type)
	SignalManager.log_message.emit("Object room initialized")
	print("Object room initialized")

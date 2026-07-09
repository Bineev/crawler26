# scripts/room/room_object.gd
extends TextureRect
class_name RoomObject

var object_type: DataManager.ObjectType = DataManager.ObjectType.CHEST

func setup(type: DataManager.ObjectType) -> void:
	object_type = type
	# TODO: установить текстуру в зависимости от типа
	match type:
		DataManager.ObjectType.CHEST:
			# texture = preload("res://img/objects/chest.png")
			pass
		DataManager.ObjectType.SHOP:
			# texture = preload("res://img/objects/shop.png")
			pass
		# ... остальные типы
	
	# TODO: настроить интерактивность (клик, подсветка и т.д.)

func interact() -> void:
	match object_type:
		DataManager.ObjectType.CHEST:
			# TODO: открыть сундук → награда
			pass
		DataManager.ObjectType.SHOP:
			# TODO: открыть магазин
			pass
		# ... остальные типы

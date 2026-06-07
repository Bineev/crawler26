# scripts/floor/room_node.gd
extends Node2D
class_name RoomNode

var room_type: DataManager.RoomType = DataManager.RoomType.COMBAT
var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
var is_revealed: bool = true  # виден ли тип комнаты игроку
var is_visited: bool = false
var position_index: int = 0
var next_nodes: Array[RoomNode] = []  # следующие комнаты (обычно 2 для развилки)
var parent_node: RoomNode = null

func setup(room_data: Dictionary):
	room_type = room_data.get("type", DataManager.RoomType.COMBAT)
	combat_type = room_data.get("combat_type", DataManager.CombatType.NORMAL)
	is_revealed = room_data.get("is_revealed", true)

func get_display_icon() -> Texture2D:
	if is_visited:
		return load("res://img/floor/room_visited.png")
	
	if not is_revealed:
		return load("res://img/floor/room_hidden.png")
	
	match room_type:
		DataManager.RoomType.COMBAT:
			match combat_type:
				DataManager.CombatType.NORMAL:
					return load("res://img/floor/combat_normal.png")
				DataManager.CombatType.ELITE:
					return load("res://img/floor/combat_elite.png")
				DataManager.CombatType.BOSS:
					return load("res://img/floor/combat_boss.png")
				_:
					return load("res://img/floor/combat_normal.png")
		DataManager.RoomType.EVENT:
			return load("res://img/floor/event.png")
		DataManager.RoomType.OBJECT:
			return load("res://img/floor/object.png")
	
	return load("res://img/floor/room_hidden.png")

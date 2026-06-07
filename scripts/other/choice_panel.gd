# scripts/ui/choice_panel.gd
extends Control
class_name ChoicePanel

signal option_selected(room_node: RoomNode)

var options: Array[RoomNode] = []

func setup(rooms: Array[RoomNode]):
	options = rooms
	# Создаём кнопки для каждой комнаты
	for i in range(rooms.size()):
		var button = Button.new()
		button.text = _get_room_description(rooms[i])
		button.icon = rooms[i].get_display_icon()
		button.pressed.connect(_on_option_selected.bind(rooms[i]))
		add_child(button)

func _get_room_description(room_node: RoomNode) -> String:
	if not room_node.is_revealed:
		return "???"
	
	match room_node.room_type:
		DataManager.RoomType.COMBAT:
			match room_node.combat_type:
				DataManager.CombatType.NORMAL:
					return "Бой"
				DataManager.CombatType.ELITE:
					return "Сложный бой"
				DataManager.CombatType.BOSS:
					return "Босс"
		DataManager.RoomType.EVENT:
			return "Событие"
		DataManager.RoomType.OBJECT:
			return "Объект"
	
	return "???"

func _on_option_selected(room_node: RoomNode):
	option_selected.emit(room_node)
	queue_free()

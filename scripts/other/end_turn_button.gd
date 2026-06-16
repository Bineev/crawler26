# scripts/ui/end_turn_button.gd
extends Button
class_name EndTurnButton

func _ready():
	text = "КОНЕЦ ХОДА"
	add_theme_font_override("font", DataManager.FONT_HEADERS)
	add_theme_font_size_override("font_size", 20)
	
	pressed.connect(_on_pressed)


func _on_pressed():
	# Проверяем, что это ход игрока
	if BattleManager.is_player_turn():
		BattleManager.end_player_turn()
	else:
		SignalManager.log_message.emit("Сейчас не ваш ход!")

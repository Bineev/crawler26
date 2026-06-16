# scripts/ui/end_turn_button.gd
extends Button
class_name EndTurnButton

var is_ending_turn: bool = false

func _ready():
	text = "КОНЕЦ ХОДА"
	add_theme_font_override("font", DataManager.FONT_HEADERS)
	add_theme_font_size_override("font_size", 20)
	
	pressed.connect(_on_pressed)


func _on_pressed():
	if is_ending_turn:
		return
	# Проверяем, что это ход игрока
	if BattleManager.is_player_turn():
		is_ending_turn = true
		BattleManager.end_player_turn()
	else:
		SignalManager.log_message.emit("Сейчас не ваш ход!")

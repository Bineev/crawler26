# scripts/ui/end_turn_button.gd
extends Button
class_name EndTurnButton

var is_ending_turn: bool = false

func _ready():
	text = tr("end_turn_button_label")
	DataManager.apply_button_style(self, DataManager.ButtonType.PRIMARY)
	
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

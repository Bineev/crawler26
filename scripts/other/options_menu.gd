extends PanelContainer

class_name OptionsMenu


var is_opened : bool

@onready var to_lobby_button: Button = %to_lobby_button
@onready var confirmed_container: VBoxContainer = %confirmed_container
@onready var yes_button: Button = %yes_button
@onready var no_button: Button = %no_button
@onready var shake_check: CheckBox = %shake_check


func initialize():
	# BUG
	await get_tree().process_frame
	GameManager.correct_options()
	is_opened = true
	global_position = get_viewport_rect().get_center()
	global_position -= Vector2(size.x / 2, size.y / 2)


func _on_close_button_pressed() -> void:
	#SoundManager.play_ui(self, DataManager.sound_dict[DataManager.SoundType.UI])
	GameManager.hide_options()


func _on_to_lobby_button_pressed() -> void:
	show_confirmed()


func show_to_lobby_button():
	if to_lobby_button:
		to_lobby_button.visible = true


func show_confirmed():
	hide_to_lobby_button()
	confirmed_container.show()


func hide_to_lobby_button():
	if to_lobby_button:
		to_lobby_button.visible = false


func _on_yes_button_pressed() -> void:
	get_tree().paused = true
	GameManager.level.queue_free()
	GameManager.show_menu()


func _on_no_button_pressed() -> void:
	confirmed_container.hide()
	to_lobby_button.show()
#
#
#func _on_shake_check_pressed() -> void:
	#SignalManager.on_toggle_shake.emit()

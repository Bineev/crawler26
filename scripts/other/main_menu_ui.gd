extends PanelContainer

class_name MainMenuUI


@onready var confirmed_container: VBoxContainer = %confirmed_container
@onready var yes_button: Button = %yes_button
@onready var no_button: Button = %no_button
@onready var play_button: Button = %play_button
@onready var options_button: Button = %options_button
@onready var exit_button: Button = %exit_button


func _ready() -> void:
	GameManager.set_main_menu(self)
	initialize()


func initialize():
	await get_tree().process_frame
	pass


func _on_play_button_pressed() -> void:
	await get_tree().process_frame
	GameManager.start_level()


func _on_options_button_pressed() -> void:
	#SoundManager.play_ui(self, DataManager.sound_dict[DataManager.SoundType.UI])
	GameManager.show_options()


func _on_exit_button_pressed() -> void:
	#SoundManager.play_ui(self, DataManager.sound_dict[DataManager.SoundType.UI])
	GameManager.exit()


func _on_rus_locale_btn_pressed() -> void:
	TranslationServer.set_locale('ru_RU')


func _on_eng_locale_btn_pressed() -> void:
	TranslationServer.set_locale('en_US')

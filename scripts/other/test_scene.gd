# В сцене создать узел Node2D с именем "GameWorld"
# Добавить скрипт:

extends Node2D

func _ready():
	GameTestManager.start_test($GameWorld)

func _process(delta):
	# Для теста: нажатие пробела - пропуск комнаты
	if Input.is_action_just_pressed("ui_accept"):
		# После победы в бою вызываем
		GameTestManager.after_combat_victory()

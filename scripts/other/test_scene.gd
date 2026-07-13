# В сцене создать узел Node2D с именем "GameWorld"
# Добавить скрипт:

extends Node2D

func _ready():
	GameTestManager.start_test($SubViewportContainer/SubViewport/GameWorld)
	SignalManager.player_took_damage.connect(play_slash_effect)
	SignalManager.enemy_get_attack.connect(play_enemy_get_hit_effect)

func _process(delta):
	# Для теста: нажатие пробела - пропуск комнаты
	if Input.is_action_just_pressed("ui_accept"):
		# После победы в бою вызываем
		GameTestManager.after_combat_victory()


func play_slash_effect(amount : int):
	$SubViewportContainer.play_slash_effect()
	$SubViewportContainer.shake_screen(3, 0.05)
	$SubViewportContainer.trigger_hit_stop(0.15)


func play_enemy_get_hit_effect():
	$SubViewportContainer.shake_screen(3, 0.05)
	$SubViewportContainer.trigger_hit_stop(0.1)

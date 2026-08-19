# В сцене создать узел Node2D с именем "GameWorld"
# Добавить скрипт:

extends Control

var is_other_effect_played: bool = false

func _ready():
	# Получаем реальный размер экрана пользователя
	# 1. Принудительно подключаемся к событию изменения размера окна ОС
	get_tree().root.size_changed.connect(_force_recalculate_scale)
	
	# 2. Вызываем пересчет один раз при старте
	_force_recalculate_scale()
	
	GameTestManager.start_test($SubViewportContainer/SubViewport/GameWorld)
	SignalManager.player_took_damage.connect(play_slash_effect)
	SignalManager.enemy_get_attack.connect(play_enemy_get_hit_effect)
	SignalManager.something_get_debuff.connect(play_get_debuff_effect)
	

func _process(delta):
	# Для теста: нажатие пробела - пропуск комнаты
	if Input.is_action_just_pressed("ui_accept"):
		# После победы в бою вызываем
		GameTestManager.after_combat_victory()


func play_slash_effect(amount : int):
	if is_other_effect_played:
		return
	$SubViewportContainer.play_player_slash_effect()
	$SubViewportContainer.shake_screen(3, 0.05)
	$SubViewportContainer.trigger_hit_stop(0.15)


func play_enemy_get_hit_effect():
	if is_other_effect_played:
		return
	$SubViewportContainer.play_enemy_slash_effect()
	$SubViewportContainer.shake_screen(2, 0.1)
	$SubViewportContainer.trigger_hit_stop(0.07)


func play_get_debuff_effect(target: CharacterStats):
	if is_other_effect_played:
		return
	if target is EnemyInstance:
		$SubViewportContainer.play_enemy_slash_effect()
	$SubViewportContainer.shake_screen(3, 0.05)
	$SubViewportContainer.trigger_hit_stop(0.05)


func _force_recalculate_scale() -> void:
	# Получаем реальный физический размер окна (например, 1600х900)
	var actual_window_size = get_window().size
	
	# Сбрасываем размер нашей корневой сцены под размер root-окна
	# Это заставит full_rect контейнеры обновиться
	if is_16_9():
		custom_minimum_size = actual_window_size
		size = actual_window_size


func is_16_9() -> bool:
	var screen_size = DisplayServer.screen_get_size()
	var aspect = float(screen_size.x) / float(screen_size.y)
	# 16:9 = 1.777...
	return abs(aspect - 16.0 / 9.0) < 0.01

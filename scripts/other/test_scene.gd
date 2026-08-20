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

	# Подписываемся на сигнал старта биома
	SignalManager.start_biome.connect(_on_start_biome)
	SignalManager.player_took_damage.connect(play_slash_effect)
	SignalManager.enemy_get_attack.connect(play_enemy_get_hit_effect)
	SignalManager.something_get_debuff.connect(play_get_debuff_effect)
	
	# Инициализируем игру
	GameTestManager.prepare_game_initialization($SubViewportContainer/SubViewport/GameWorld)
	
	# Создаём персонажа
	GameTestManager.create_character(DataManager.CharacterClass.PENITENT)
	# Инициализируем новый забег
	GameTestManager.initialize_new_run()
	# Загружаем сцену выбора биома
	_load_biomes_choice()


func _on_start_biome():
	# Удаляем сцену выбора биома из GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		if child is BiomeChoice:
			child.queue_free()
	
	# Запускаем новый биом
	GameTestManager.start_new_biome()



func _load_biomes_choice():
	var biome_scene = load("res://scenes/biome_choice.tscn")
	var biome_instance = biome_scene.instantiate()
	
	# Добавляем в GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	game_world.add_child(biome_instance)


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

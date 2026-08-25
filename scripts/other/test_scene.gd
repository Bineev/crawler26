# В сцене создать узел Node2D с именем "GameWorld"
# Добавить скрипт:

extends Control

var menu_instance: MainMenu
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
	# 🆕 Подписываемся на сигнал перезапуска
	SignalManager.restart_run_requested.connect(_on_restart_run_requested)
	# 🆕 Подписываемся на сигнал завершения биома
	SignalManager.show_next_biome_choice.connect(_on_show_next_biome_choice)
	# 🆕 Подписываемся на сигнал запуска игры из главного меню
	SignalManager.start_game_requested.connect(_on_start_game_requested)
	SignalManager.exit_requested.connect(_on_exit_requested)
	SignalManager.settings_requested.connect(_on_settings_requested)
	SignalManager.exit_to_menu_requested.connect(_on_exit_to_menu_requested)
	SignalManager.settings_closed.connect(_on_settings_closed)
	
	# Инициализируем игру
	GameTestManager.prepare_game_initialization($SubViewportContainer/SubViewport/GameWorld)
	show_main_menu()


func _on_settings_closed():
	close_options()


func _input(event: InputEvent):
	if event.is_action_pressed("options"):
		# Проверяем, не в процессе ли анимации меню
		if _is_main_menu_animating():
			return
		
		if settings_menu_is_open():
			close_options()
		else:
			_on_settings_requested()


func _is_main_menu_animating() -> bool:
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		if child is MainMenu:
			return not child.is_enter_animation_finished
	return false


func settings_menu_is_open() -> bool:
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		if child is SettingsMenu and child.is_open:
			return true
	return false



func _on_settings_requested():
	var context = SettingsMenu.OpenContext.MAIN_MENU
	
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	var has_main_menu = false
	var has_biome_choice = false
	
	for child in game_world.get_children():
		if child is MainMenu:
			has_main_menu = true
			child.hide()
		elif child is BiomeChoice:
			has_biome_choice = true
			child.hide()
	
	if has_main_menu:
		context = SettingsMenu.OpenContext.MAIN_MENU
	elif has_biome_choice:
		context = SettingsMenu.OpenContext.BIOME_CHOICE
	else:
		context = SettingsMenu.OpenContext.GAMEPLAY
	
	show_options(context)


func _on_exit_to_menu_requested():
	close_options()
	
	# Очищаем GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		child.queue_free()
	
	# Очищаем UI
	GameTestManager.clear_ui()
	
	# Показываем главное меню
	show_main_menu()


func _on_start_game_requested():
	_fade_out_and_start()


func show_main_menu():
	# Очищаем GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		child.queue_free()
	
	# Очищаем UI
	GameTestManager.clear_ui()
	
	# Загружаем сцену главного меню
	var menu_scene = load("res://scenes/main_menu.tscn")
	menu_instance = menu_scene.instantiate()
	game_world.add_child(menu_instance)




func start_new_run():
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


func _on_restart_run_requested():
	
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.anchor_top = 0.0
	fade.anchor_bottom = 1.0
	fade.z_index = 1000
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5)
	await tween.finished
	# 🆕 Сбрасываем доступные биомы
	ProgressManager.reset_available_biomes()
	# Очищаем GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		child.queue_free()
	BattleManager.reset_battle()
	RunManager.reset_run()
	
	# Очищаем UI в GameTestManager
	GameTestManager.clear_ui()
	
	# Создаём персонажа заново
	GameTestManager.create_character(DataManager.CharacterClass.PENITENT)
	
	# Инициализируем новый забег
	GameTestManager.initialize_new_run()
	
	# Показываем выбор биома
	_load_biomes_choice()
	var tween2 = create_tween()
	tween2.tween_property(fade, "color:a", 0.0, 0.5)
	await tween2.finished
	fade.queue_free()


func _on_show_next_biome_choice():
	# Очищаем GameWorld
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		child.queue_free()
	BattleManager.reset_battle()
	# Очищаем UI
	GameTestManager.clear_ui()
	
	# Показываем выбор следующего биома
	_load_biomes_choice()


func _on_exit_requested():
	get_tree().quit()


func _fade_out_and_start():
	# Создаём оверлей затемнения
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.anchor_left = 0.0
	fade.anchor_right = 1.0
	fade.anchor_top = 0.0
	fade.anchor_bottom = 1.0
	fade.z_index = 1000
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1)
	await tween.finished
	menu_instance.queue_free()
	menu_instance = null
	# Удаляем главное меню
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		child.queue_free()
	
	# Запускаем новый забег (создаёт персонажа и показывает выбор биома)
	start_new_run()
	
	# Оттемняем
	var tween2 = create_tween()
	tween2.tween_property(fade, "color:a", 0.0, 1)
	await tween2.finished
	fade.queue_free()


func show_options(context: int):
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	var settings_menu = null
	
	for child in game_world.get_children():
		if child is SettingsMenu:
			settings_menu = child
			break
	
	if not settings_menu:
		var menu_scene = load("res://scenes/settings_menu.tscn")
		settings_menu = menu_scene.instantiate()
		game_world.add_child(settings_menu)
	
	settings_menu.open(context)


func close_options():
	var game_world = $SubViewportContainer/SubViewport/GameWorld
	for child in game_world.get_children():
		if child is SettingsMenu:
			child.close()
		elif child is MainMenu:
			child.show()
		elif child is BiomeChoice:
			child.show()

extends SubViewportContainer

@export var player_hit_duration: float = 0.3
@export var enemy_hit_duration: float = 0.7
@export var duration: float = 0.3
@export var player_hit_material: ShaderMaterial = preload("res://shaders/slash_mat.tres")
@export var enemy_hit_material: ShaderMaterial = preload("res://shaders/slash_enemy_mat.tres")
@onready var sub_viewport: SubViewport = $SubViewport

func play_player_slash_effect() -> void:
	if player_hit_material:
		material = player_hit_material.duplicate()
		duration = player_hit_duration
		_play_slash_effect()

func play_enemy_slash_effect() -> void:
	if enemy_hit_material:
		material = enemy_hit_material.duplicate()
		duration = enemy_hit_duration
		_play_slash_effect()

func _play_slash_effect() -> void:
	if not material:
		return
	
	get_parent().is_other_effect_played = true
	material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(material, "shader_parameter/progress", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): 
		if material:
			material.set_shader_parameter("progress", 0.0)
	)
	await tween.finished
	
	get_parent().is_other_effect_played = false
	
	material = null


func trigger_hit_stop(duration: float = 0.08) -> void:
	Engine.time_scale = 0.03 # Резко замедляем время (почти стоп-кадр)
	
	# ТРЕТИЙ аргумент (true) в Godot 4 отвечает за process_always. 
	# Он заставляет таймер работать по реальному времени, игнорируя Engine.time_scale.
	await get_tree().create_timer(duration, true, true, true).timeout 
	
	Engine.time_scale = 1.0 # Мгновенно возвращаем нормальную скорость

	
# Функция симулирует резкий удар и затухающую тряску
func shake_screen(intensity: float, time: float) -> void:
	var shake_tween: Tween = create_tween()
	shake_tween.set_ignore_time_scale(true)
	var start_position: Vector2 = position # Запоминаем исходную позицию экрана
	
	var steps: int = 6 # Количество прыжков экрана
	var step_time: float = time / float(steps)
	
	for i in range(steps):
		# С каждым шагом сила тряски затухает
		var current_intensity: float = intensity * (1.0 - float(i) / float(steps))
		
		# Генерируем случайное смещение в случайную сторону
		var rand_direction := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		# Проверяем, чтобы вектор не был нулевым, иначе normalized() вернет (0,0)
		if rand_direction.length_squared() > 0.0:
			rand_direction = rand_direction.normalized()
			
		var offset: Vector2 = rand_direction * current_intensity
		
		# Записываем шаг анимации в Твин
		shake_tween.tween_property(self, "position", start_position + offset, step_time)
	
	# В самом конце возвращаем экран ровно на исходное место
	shake_tween.tween_property(self, "position", start_position, step_time)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		# Создаем копию события мыши
		var local_event = event.duplicate()
		# Корректно пересчитываем координаты экрана в координаты вьюпорта
		local_event.position = get_global_transform().affine_inverse() * event.global_position
		
		# Отправляем клик в UI вьюпорта (если он там есть)
		sub_viewport.push_input(local_event)
		# Принудительно проталкиваем клик в физику и Area2D карт
		sub_viewport.push_unhandled_input(local_event)

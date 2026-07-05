# scripts/ui/enemy_ui.gd
extends Control
class_name EnemyUI

## ============================================================
## НОДЫ
## ============================================================
@onready var enemy_sprite: TextureRect = $VBoxContainer/SpriteContainer/EnemySprite
@onready var intents_container: HBoxContainer = $VBoxContainer/IntentsContainer
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthBar/HealthLabel
@onready var status_container: GridContainer = $VBoxContainer/BottomPanel/StatusContainer
@onready var passive_container: GridContainer = $VBoxContainer/BottomPanel/PassiveContainer
@onready var living_container: Control = $VBoxContainer/SpriteContainer/LivingContainer
@onready var click_area: Area2D = $ClickArea
@onready var collision_shape: CollisionShape2D = $ClickArea/CollisionShape2D
@onready var enemy_sprite_copy: TextureRect = $VBoxContainer/SpriteContainer/EnemySpriteCopy
@onready var sprite_container: CenterContainer = $VBoxContainer/SpriteContainer
@onready var highlight_sprite: TextureRect = $VBoxContainer/SpriteContainer/HighlightSprite


const STATUS_ICON_SCENE = preload("res://scenes/status_icon.tscn")
const PASSIVE_ICON_SCENE = preload("res://scenes/passive_icon.tscn")

var enemy_instance: EnemyInstance = null
var breath_tween: Tween = null
var wobble_tween: Tween = null
var aura_particles: GPUParticles2D = null

var highlight_material: ShaderMaterial = null
var is_highlighted: bool = false
var base_material: Material = null

var current_shader_priority: DataManager.EnemyShaderPriority = DataManager.EnemyShaderPriority.NONE
var pending_death: bool = false
var pending_freeze: bool = false
var _is_pushing: bool = false

var _saved_modulate: Color = Color(1, 1, 1, 1)

const FREEZE_SHADER = preload("res://shaders/frozen.gdshader")
var ice_noise: NoiseTexture2D = null
var hit_tween: Tween = null
var freeze_tween: Tween = null
## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func setup(enemy: EnemyInstance):
	enemy_instance = enemy
	update_display()
	_setup_click_area()
	_setup_health_bar()  # ← добавить
	living_container.custom_minimum_size = enemy_instance.resource.get_size_pixels()
	
	# Поднимаем врага выше дыма
	living_container.z_index = 10
	living_container.z_as_relative = false
	
	_add_aura_effect()
	_start_living_animation()
	_start_random_jitter()
	if enemy_sprite:
		base_material = enemy_sprite.material.duplicate() as ShaderMaterial
		base_material.set_shader_parameter('jitter_speed', randf_range(1.5, 2.5))
		base_material.set_shader_parameter('jitter_amount', randf_range(0.003, 0.006))
		enemy_sprite.material = base_material
	# Подключаем сигнал получения урона
	# Подписываемся на сигнал подсветки
	SignalManager.damage_dealt.connect(_on_damage_dealt)
	SignalManager.heal_received.connect(_on_heal_received)
	SignalManager.enemy_highlight_requested.connect(_on_highlight_requested)
	SignalManager.get_hit.connect(_on_get_hit)
	SignalManager.enemy_health_changed.connect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.connect(_on_enemy_status_changed)
	SignalManager.enemy_intent_changed.connect(_on_enemy_intent_changed)
	SignalManager.passive_removed.connect(_on_passive_changed)  # ← проверь, что есть
	SignalManager.passive_changed.connect(_on_passive_changed)  # 🆕
	SignalManager.passive_added.connect(_on_passive_changed)  # 🆕
	

func _add_aura_effect():
	if not living_container:
		return
	
	var container_size = living_container.custom_minimum_size
	var enemy_width = container_size.x
	var enemy_bottom = container_size.y
	
	aura_particles = GPUParticles2D.new()
	aura_particles.name = "AuraParticles"
	aura_particles.amount = 60
	aura_particles.lifetime = 5
	aura_particles.speed_scale = 0.7
	aura_particles.explosiveness = 0.3
	aura_particles.one_shot = false
	aura_particles.emitting = true
	aura_particles.z_as_relative = false
	
	# Увеличиваем область видимости частиц
	aura_particles.visibility_rect = Rect2(-enemy_width, -100, enemy_width * 2, 200)
	
	var particle_texture = preload("res://img/smoke.png")
	if particle_texture:
		aura_particles.texture = particle_texture
	
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, -1, 0)
	process_material.spread = 60                    # очень широко
	process_material.gravity = Vector3(0, -3, 0)       # поднимаются выше
	process_material.initial_velocity_min = 10.0
	process_material.initial_velocity_max = 30.0
	process_material.angular_velocity_min = 5.0
	process_material.angular_velocity_max = 20.0
	process_material.scale_min = 0.3
	process_material.scale_max = 0.6            # крупные частицы
	process_material.color = Color(0, 0, 0, 0.4)
	#process_material.color = Color(0, 0, 0, 0.4)
	process_material.hue_variation_max = 0.1  # максимальное изменение оттенка
	process_material.hue_variation_min = 0.0  # минимальное изменение оттенка
	
	aura_particles.process_material = process_material
	
	# Позиция: от центра врага, ниже
	aura_particles.position = Vector2(enemy_width / 2, enemy_bottom - 100)
	
	living_container.add_child(aura_particles)
	
	# второй слой
	var aura_particles2 = GPUParticles2D.new()
	aura_particles2.amount = 20
	aura_particles2.lifetime = 4.0
	aura_particles2.speed_scale = 0.5
	aura_particles2.texture = particle_texture

	var pm2 = ParticleProcessMaterial.new()
	pm2.direction = Vector3(0, -1, 0)
	pm2.spread = 150
	pm2.gravity = Vector3(0, -4, 0)
	pm2.initial_velocity_min = 5.0
	pm2.initial_velocity_max = 20.0
	pm2.scale_min = 0.4
	pm2.scale_max = 0.9
	pm2.color = Color(0, 0, 0, 0.25)

	aura_particles2.process_material = pm2
	aura_particles.position = Vector2(enemy_width / 2, enemy_bottom - 100)
	living_container.add_child(aura_particles2)


func _remove_aura_effect():
	if aura_particles:
		aura_particles.queue_free()
		aura_particles = null


func _start_living_animation():
	if not living_container:
		return
	
	breath_tween = create_tween()
	breath_tween.set_loops()
	breath_tween.tween_property(living_container, "scale", Vector2(1.008, 1.008), 5.0).set_ease(Tween.EASE_IN_OUT)
	breath_tween.tween_property(living_container, "scale", Vector2(0.992, 0.992), 5.0).set_ease(Tween.EASE_IN_OUT)
	
	wobble_tween = create_tween()
	wobble_tween.set_loops()
	wobble_tween.tween_property(living_container, "position", Vector2(2, 0), 3.5).set_ease(Tween.EASE_IN_OUT).as_relative()
	wobble_tween.tween_property(living_container, "position", Vector2(-2, 0), 3.5).set_ease(Tween.EASE_IN_OUT).as_relative()


func _stop_living_animation():
	if breath_tween:
		breath_tween.kill()
		breath_tween = null
	if wobble_tween:
		wobble_tween.kill()
		wobble_tween = null
	scale = Vector2.ONE
	position = Vector2.ZERO


func _apply_horror_shader():
	if not enemy_sprite:
		return
	
	var shader_material = ShaderMaterial.new()
	var shader = preload("res://shaders/enemy_horror.gdshader")
	shader_material.shader = shader
	
	shader_material.set_shader_parameter("breath_speed", 0)
	shader_material.set_shader_parameter("breath_amount", 0)
	shader_material.set_shader_parameter("wobble_speed", 0.001)
	shader_material.set_shader_parameter("wobble_amount", 0.001)
	shader_material.set_shader_parameter("jitter_strength", 0)
	
	enemy_sprite.material = shader_material


func update_display():
	if not enemy_instance:
		return
	
	# Спрайт
	if enemy_sprite:
		enemy_sprite.texture = enemy_instance.get_sprite()
		# Копия спрайта
	if enemy_sprite_copy:
		enemy_sprite_copy.texture = enemy_instance.get_sprite()
	
	if highlight_sprite:
		highlight_sprite.texture = enemy_instance.get_sprite()
	# Здоровье
	var current_health = enemy_instance.get_health()
	var max_health = enemy_instance.get_max_health()
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health
	if health_label:
		health_label.text = "%d/%d" % [current_health, max_health]
	
	# Намерения
	update_intents()
	
	# Статусы и пассивки
	update_statuses()
	update_passives()


func update_intents():
	if not intents_container:
		return
	
	# Очищаем старые намерения
	for child in intents_container.get_children():
		child.queue_free()
	
	if not enemy_instance or not enemy_instance.current_intent:
		return
	
	# Создаём иконку и лейбл для каждого эффекта
	for effect in enemy_instance.current_intent.effects:
		var intent_item = _create_intent_item(effect)
		if intent_item:
			intents_container.add_child(intent_item)


func _create_intent_item(effect: EffectEntry) -> Control:
	var container = HBoxContainer.new()
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# добавить шейдер на обводку
	DataManager.apply_shader_to_icon(icon, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})
	DataManager.apply_shader_overlay(icon, "res://shaders/card3_shader.gdshader")
	
	var value_label = Label.new()
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Формируем текст и иконку
	var tooltip_text = ""
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.ATTACK)
			# Вычисляем финальный урон с учётом силы
			var base_damage = effect.base_value
			var strength_bonus = enemy_instance.get_strength_bonus() if enemy_instance else 0
			var final_damage = base_damage + strength_bonus
			value_label.text = str(final_damage)
			tooltip_text = "Враг собирается атаковать"
		DataManager.EffectCategory.BLOCK:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEFEND)
			value_label.text = str(effect.base_value)
			tooltip_text = "Враг собирается защищаться"
		DataManager.EffectCategory.HEAL:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.HEAL)
			value_label.text = str(effect.base_value)
			tooltip_text = "Враг собирается лечиться"
		DataManager.EffectCategory.APPLY_STATUS:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEBUFF)
			if effect.status:
				value_label.text = "%d %s" % [effect.value, effect.status.get_localized_name()]
			tooltip_text = "Враг собирается наложить дебафф"
		DataManager.EffectCategory.APPLY_PASSIVE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.BUFF)
			if effect.passive:
				value_label.text = effect.passive.get_localized_name()
			tooltip_text = "Враг собирается усилить себя"
		_:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
			value_label.text = "?"
			tooltip_text = "Неизвестное намерение"
	
	container.tooltip_text = tooltip_text
	
	container.add_child(icon)
	container.add_child(value_label)
	
	return container


func update_statuses():
	if not status_container:
		return
	
	for child in status_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for status_data in enemy_instance.get_active_statuses_for_ui():
		var icon = STATUS_ICON_SCENE.instantiate() as StatusIcon
		status_container.add_child(icon)
		icon.setup(status_data)
		icon.setup(status_data, DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)  # тёмный для врагов
		#DataManager.apply_shader_to_icon(icon.icon, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})

func update_passives():
	if not passive_container:
		return
	
	for child in passive_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for passive_data in enemy_instance.get_active_passives_for_ui():
		var icon = PASSIVE_ICON_SCENE.instantiate() as PassiveIcon
		passive_container.add_child(icon)
		icon.setup(passive_data, DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)  # тёмный для врагов)
		#DataManager.apply_shader_to_icon(icon.icon, "res://shaders/highlight_enemy.gdshader", {'hover_intensity' : 1.0})


func _create_icon(texture: Texture2D, size: int, tooltip: String) -> TextureRect:
	var icon = TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tr(tooltip)  # ← если tooltip — это ключ
	icon.mouse_filter = Control.MOUSE_FILTER_PASS
	return icon


## ============================================================
## СИГНАЛЫ
## ============================================================

func _on_enemy_health_changed(enemy: EnemyInstance, new_health: int, max_health: int):
	if enemy != enemy_instance:
		return
	if health_bar:
		health_bar.value = new_health
	if health_label:
		health_label.text = "%d/%d" % [new_health, max_health]


func _on_enemy_status_changed(enemy: EnemyInstance):
	if enemy != enemy_instance:
		return
	update_statuses()


func _exit_tree():
	_stop_living_animation()
	_remove_aura_effect()
	SignalManager.damage_dealt.disconnect(_on_damage_dealt)
	SignalManager.heal_received.disconnect(_on_heal_received)
	SignalManager.enemy_highlight_requested.disconnect(_on_highlight_requested)
	SignalManager.get_hit.disconnect(_on_get_hit)
	SignalManager.enemy_health_changed.disconnect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.disconnect(_on_enemy_status_changed)
	SignalManager.passive_changed.disconnect(_on_passive_changed)  # 🆕


func set_enemy_size():
	if not enemy_instance:
		return
	
	var rect_size = DataManager.get_enemy_size_pixels(enemy_instance.resource.size)
	self.size = rect_size


func _start_random_jitter():
	var jitter_tween = create_tween()
	var random_x = randf_range(-3, 3)
	var random_y = randf_range(-2, 2)
	jitter_tween.tween_property(living_container, "position", Vector2(random_x, random_y), 0.05)
	jitter_tween.tween_property(living_container, "position", Vector2.ZERO, 0.1)
	await get_tree().create_timer(randf_range(4, 10)).timeout
	if is_inside_tree():
		_start_random_jitter()


func _setup_click_area():
	if not click_area or not collision_shape:
		print("ERROR: ClickArea or CollisionShape not found!")
		return
	
	# Получаем размер врага
	var enemy_size = DataManager.get_enemy_size_pixels(enemy_instance.resource.size)
	
	# Создаём прямоугольную форму
	var rect_shape = RectangleShape2D.new()
	rect_shape.size = enemy_size
	
	collision_shape.shape = rect_shape
	collision_shape.position = enemy_size / 2  # центрируем
	
	# Подключаем сигнал клика
	if not click_area.input_event.is_connected(_on_click_area_input):
		click_area.input_event.connect(_on_click_area_input)
	
	# Настройка области клика
	click_area.input_pickable = true
	click_area.z_index = 10


func _on_click_area_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Enemy clicked: ", enemy_instance.resource.enemy_id)
		SignalManager.enemy_clicked.emit(enemy_instance)


func _on_get_hit(target: Node):
	# Проверяем, что удар пришёлся по этому врагу
	if target != enemy_instance:
		return
	
	# Применяем эффект удара
	_hit_effect()


func _hit_effect():
	# Если враг заморожен или умирает — игнорируем урон
	if current_shader_priority >= DataManager.EnemyShaderPriority.FREEZE:
		return
	
	if not enemy_sprite:
		return
	
	# Сохраняем текущий материал
	var current_material = enemy_sprite.material
	
	# Применяем шейдер удара
	var shader = preload("res://shaders/get_hit_shader.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	enemy_sprite.material = shader_material
	shader_material.set_shader_parameter("hit_progress", 1.0)
	
	current_shader_priority = DataManager.EnemyShaderPriority.HIT
	
	if hit_tween:
		hit_tween.kill()
	
	hit_tween = create_tween()
	hit_tween.tween_property(shader_material, "shader_parameter/hit_progress", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
	
	await hit_tween.finished
	hit_tween = null
	
	_on_hit_finished(current_material)


func _on_hit_finished(current_material: Material = null):
	# Проверяем, не умер ли враг
	if pending_death:
		pending_death = false
		_apply_death_effect()
		return
	
	# Проверяем, не нужно ли заморозить
	if pending_freeze:
		pending_freeze = false
		_apply_freeze_effect_immediate()
		return
	
	# Возвращаем базовый материал
	if enemy_sprite:
		if current_material:
			enemy_sprite.material = current_material
		elif base_material:
			enemy_sprite.material = base_material
		else:
			enemy_sprite.material = null
	
	current_shader_priority = DataManager.EnemyShaderPriority.NONE

func _on_highlight_requested(enemy: EnemyInstance, enabled: bool):
	if enemy != enemy_instance:
		return
	
	if enabled == is_highlighted:
		return
	
	is_highlighted = enabled
	_apply_highlight(enabled)


func _apply_highlight(enabled: bool):
	if not highlight_sprite:
		return
		
	if enabled:
		# Загружаем шейдер
		if not highlight_material:
			var shader = preload("res://shaders/highlight_enemy.gdshader")
			highlight_material = ShaderMaterial.new()
			highlight_material.shader = shader
		
		# Сохраняем оригинальный материал, если нужно
		if not highlight_sprite.material or highlight_sprite.material == highlight_material:
			pass
		
		highlight_material.set_shader_parameter("hover_intensity", 1.0)
		highlight_sprite.material = highlight_material
		highlight_sprite.visible = true
	else:
		# Убираем шейдер
		if highlight_sprite.material == highlight_material:
			highlight_sprite.material = null
				# Возвращаем базовый материал
		highlight_sprite.material = base_material
		highlight_material = null
		highlight_sprite.visible = false


func show_floating_text(text: String, color: Color):
	var floating_text = preload("res://scenes/floating_text.tscn").instantiate() as FloatingText
	floating_text.setup(text, color)  # ← сначала настраиваем
	add_child(floating_text)          # ← потом добавляем
	
	await get_tree().process_frame
	# Стартуем выше — от верхней части спрайта, а не от центра
	var sprite_top = enemy_sprite.global_position + Vector2(enemy_sprite.size.x / 2, -enemy_sprite.size.y / 4)
	floating_text.global_position = sprite_top


func _on_damage_dealt(target: Node, amount: int):
	if target != enemy_instance:
		return
	var color = DataManager.COLOR_DAMAGE_LOG  # тёмно-красный
	show_floating_text(str(amount), color)


func _on_heal_received(target: Node, amount: int):
	if target != enemy_instance:
		return
	var color = DataManager.COLOR_ROGUE_ART_BG_LIGHT  # светло-зелёный
	show_floating_text("+" + str(amount), color)

func die():
	# Если есть hit — дожидаемся его окончания
	if current_shader_priority == DataManager.EnemyShaderPriority.HIT:
		pending_death = true
		return
	
	# Если есть freeze — сначала убираем его
	if current_shader_priority == DataManager.EnemyShaderPriority.FREEZE:
		# Убираем freeze и ждём окончания анимации
		remove_freeze_effect()
		if freeze_tween:
			await freeze_tween.finished
	
	_apply_death_effect()


func _apply_death_effect():
	current_shader_priority = DataManager.EnemyShaderPriority.DEATH
	pending_death = false
	
	if not enemy_sprite:
		return
	
	# Скрываем все UI элементы
	_hide_ui_elements()
	
	# Применяем шейдер смерти
	var shader = preload("res://shaders/death_dissolve.gdshader")
	var death_material = ShaderMaterial.new()
	death_material.shader = shader
	
	# Устанавливаем текстуру шума
	if ice_noise:
		death_material.set_shader_parameter("grunge_noise_tex", ice_noise)
	
	var original_material = enemy_sprite.material
	enemy_sprite.material = death_material
	
	var tween = create_tween()
	tween.tween_method(_set_death_progress, 0.0, 1.0, 1.0)
	tween.finished.connect(_on_death_animation_finished.bind(death_material, original_material))


func _hide_ui_elements():
	# Скрываем всё, кроме спрайта
	if intents_container:
		intents_container.modulate = Color(1, 1, 1, 0)
	
	if health_bar:
		health_bar.modulate = Color(1, 1, 1, 0)
	
	if health_label:
		health_label.modulate = Color(1, 1, 1, 0)
	
	if status_container:
		status_container.modulate = Color(1, 1, 1, 0)
	
	if passive_container:
		passive_container.modulate = Color(1, 1, 1, 0)
	
	if enemy_sprite_copy:
		enemy_sprite_copy.modulate = Color(1, 1, 1, 0)


func _set_death_progress(value: float):
	if enemy_sprite and enemy_sprite.material:
		enemy_sprite.material.set_shader_parameter("death_progress", value)


func _on_death_animation_finished(death_material: ShaderMaterial, original_material: Material):
	if enemy_sprite:
		enemy_sprite.material = original_material
	
	current_shader_priority = DataManager.EnemyShaderPriority.NONE
	
	if enemy_instance:
		enemy_instance.queue_free()


func _on_enemy_intent_changed(enemy: EnemyInstance, intent: IntentEntry):
	print("_on_enemy_intent_changed: enemy=", enemy.get_display_name())
	if enemy != enemy_instance:
		return
	
	# Сохраняем намерение в enemy_instance
	enemy_instance.current_intent = intent
	update_intents()


func _get_intent_text(intent: IntentEntry) -> String:
	return intent.get_localized_description()


func play_attack_animation():
	if not enemy_instance:
		return
	
	var original_position = position
	var attack_offset = Vector2(0, -30)  # приближение к игроку
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Приближаемся к игроку
	tween.tween_property(self, "position", original_position + attack_offset, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.1).set_ease(Tween.EASE_OUT)
	
	# Возвращаемся
	tween.tween_property(self, "position", original_position, 0.1).set_delay(0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.1).set_ease(Tween.EASE_IN)
	
	# Пауза после анимации
	await get_tree().create_timer(0.3).timeout
	

func play_debuff_animation():
	if not enemy_instance:
		return
	
	var original_position = position
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Небольшая пульсация
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.2).set_ease(Tween.EASE_IN)
	
	# Лёгкое смещение в сторону
	tween.tween_property(self, "position", original_position + Vector2(10, 0), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_position, 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(0.4).timeout


func play_delay(duration: float = 0.3):
	await get_tree().create_timer(duration).timeout


func _on_passive_changed(target: Node, passive_id: int = 999):
	print("_on_passive_changed: target=", target, " passive_id=", passive_id, " enemy_instance=", enemy_instance)
	if target == enemy_instance:
		print("  Updating passives for enemy")
		update_passives()


func _setup_health_bar():
	if not health_bar:
		return
	
	# Фон
	var health_bg = StyleBoxFlat.new()
	health_bg.bg_color = Color.BLACK
	health_bg.border_width_bottom = 2
	health_bg.border_width_top = 2
	health_bg.border_width_left = 2
	health_bg.border_width_right = 2
	health_bg.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	health_bar.add_theme_stylebox_override("background", health_bg)
	
	# Заливка (красный)
	var health_fill = StyleBoxFlat.new()
	health_fill.bg_color = DataManager.COLOR_FLESH_CAVES_ART_BG_DARK
	health_fill.border_width_bottom = 1
	health_fill.border_width_top = 1
	health_fill.border_width_left = 1
	health_fill.border_width_right = 1
	health_fill.border_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	health_bar.add_theme_stylebox_override("fill", health_fill)
	
	# Текст
	if health_label:
		health_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
		health_label.add_theme_font_override("font", DataManager.FONT_MAIN)
		health_label.add_theme_font_size_override("font_size", 14)
		health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Высота бара
	health_bar.custom_minimum_size = Vector2(0, 24)


func play_appear_animation() -> void:
	# Начальное состояние: враг скрыт и уменьшен
	modulate = Color(1, 1, 1, 0)
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Появляется и увеличивается
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 2)
	tween.tween_property(self, "scale", Vector2(1, 1), 1).set_ease(Tween.EASE_OUT)
	
	# Небольшой перелёт (overshoot)
	tween.tween_property(self, "position", position + Vector2(0, -10), 0.15).set_delay(1)
	tween.tween_property(self, "position", position, 1).set_delay(1)
	
	await tween.finished


func _init_ice_texture():
	ice_noise = NoiseTexture2D.new()
	ice_noise.seamless = true
	
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = 0.05
	
	ice_noise.noise = noise


func apply_freeze_effect():
	# Если враг умирает — откладываем заморозку
	if current_shader_priority == DataManager.EnemyShaderPriority.DEATH:
		pending_freeze = true
		return
	
	# Если уже есть заморозка — не применяем повторно
	if current_shader_priority == DataManager.EnemyShaderPriority.FREEZE:
		return
	
	# Если есть hit — дожидаемся его окончания
	if current_shader_priority == DataManager.EnemyShaderPriority.HIT:
		pending_freeze = true
		return
	
	_apply_freeze_effect_immediate()


func _apply_freeze_effect_immediate():
	current_shader_priority = DataManager.EnemyShaderPriority.FREEZE
	pending_freeze = false
	
	if not enemy_sprite:
		return
	
	# Инициализируем текстуру если ещё не сделали
	if not ice_noise:
		_init_ice_texture()
	
	# Сохраняем базовый материал
	if not base_material:
		base_material = enemy_sprite.material
	
	# Создаём уникальный материал
	var shader = preload("res://shaders/frozen.gdshader")
	var shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Передаём параметры
	shader_material.set_shader_parameter("ice_cracks_tex", ice_noise)
	shader_material.set_shader_parameter("ice_color", Color("4cb0f2"))
	shader_material.set_shader_parameter("glow_color", Color("99daff"))
	shader_material.set_shader_parameter("freeze_amount", 0.0)
	
	enemy_sprite.material = shader_material
	
	if freeze_tween:
		freeze_tween.kill()
	
	freeze_tween = create_tween()
	freeze_tween.tween_property(shader_material, "shader_parameter/freeze_amount", 1.0, 0.6)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)


func remove_freeze_effect():
	pending_freeze = false
	
	if current_shader_priority != DataManager.EnemyShaderPriority.FREEZE:
		return
	
	if not enemy_sprite or not enemy_sprite.material:
		current_shader_priority = DataManager.EnemyShaderPriority.NONE
		return
	
	if enemy_sprite.material is ShaderMaterial:
		var shader_material = enemy_sprite.material as ShaderMaterial
		
		if freeze_tween:
			freeze_tween.kill()
		
		freeze_tween = create_tween()
		freeze_tween.tween_property(shader_material, "shader_parameter/freeze_amount", 0.0, 0.4)
		freeze_tween.finished.connect(func(): 
			if enemy_sprite:
				enemy_sprite.material = base_material
			current_shader_priority = DataManager.EnemyShaderPriority.NONE
			freeze_tween = null
		)


func push_back():
	if _is_pushing or not enemy_sprite:
		return
	
	_is_pushing = true
	
	var original_scale = scale
	var target_scale = Vector2(0.7, 0.7)
	
	# Вычисляем смещение для центрирования
	var size = enemy_sprite.size
	var offset = (size * original_scale - size * target_scale) / 2
	var target_pos = position + offset
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "scale", target_scale, 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_pos, 0.1).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(self, "scale", original_scale, 0.1).set_delay(0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position", position, 0.1).set_delay(0.1).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	_is_pushing = false


func find_status_icon(status_id: int) -> StatusIcon:
	for child in status_container.get_children():
		if child is StatusIcon and child.status_id == status_id:
			return child
	return null

func find_passive_icon(passive_id: int) -> PassiveIcon:
	for child in passive_container.get_children():
		if child is PassiveIcon and child.passive_id == passive_id:
			return child
	return null

# scripts/ui/enemy_ui.gd
extends Control
class_name EnemyUI

## ============================================================
## НОДЫ
## ============================================================
@onready var enemy_sprite: TextureRect = $VBoxContainer/LivingContainer/SpriteContainer/EnemySprite
@onready var intents_container: HBoxContainer = $VBoxContainer/IntentsContainer
@onready var health_bar: ProgressBar = $VBoxContainer/HealthBar
@onready var health_label: Label = $VBoxContainer/HealthBar/HealthLabel
@onready var status_container: HBoxContainer = $VBoxContainer/BottomPanel/StatusContainer
@onready var passive_container: HBoxContainer = $VBoxContainer/BottomPanel/PassiveContainer
@onready var living_container: Control = $VBoxContainer/LivingContainer  # новая нода

var enemy_instance: EnemyInstance = null
var breath_tween: Tween = null
var wobble_tween: Tween = null
var aura_particles: GPUParticles2D = null
## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func setup(enemy: EnemyInstance):
	enemy_instance = enemy
	update_display()
	living_container.custom_minimum_size = enemy_instance.resource.get_size_pixels()
	
	# Поднимаем врага выше дыма
	living_container.z_index = 10
	living_container.z_as_relative = false
	
	_add_aura_effect()
	_start_living_animation()
	_start_random_jitter()
	
	SignalManager.enemy_health_changed.connect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.connect(_on_enemy_status_changed)
	

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
	
	for child in intents_container.get_children():
		child.queue_free()
	
	if not enemy_instance or not enemy_instance.current_intent:
		return
	
	for effect in enemy_instance.current_intent.effects:
		var intent_panel = _create_intent_panel(effect)
		if intent_panel:
			intents_container.add_child(intent_panel)


func _create_intent_panel(effect: EffectEntry) -> HBoxContainer:
	var panel = HBoxContainer.new()
	panel.add_constant_override("separation", 5)
	
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	var value_label = Label.new()
	value_label.add_theme_font_size_override("font_size", 16)
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.ATTACK)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.BLOCK:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEFEND)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.HEAL:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.HEAL)
			value_label.text = str(effect.base_value)
		DataManager.EffectCategory.APPLY_STATUS:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.DEBUFF)
			if effect.status:
				value_label.text = "%d %s" % [effect.value, effect.status.get_localized_name()]
		DataManager.EffectCategory.APPLY_PASSIVE:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.BUFF)
			if effect.passive:
				value_label.text = effect.passive.get_localized_name()
		_:
			icon.texture = DataManager.get_intent_icon(DataManager.IntentType.UNKNOWN)
			if effect.passive:
				value_label.text = effect.passive.get_localized_name()
	
	panel.add_child(icon)
	panel.add_child(value_label)
	
	return panel


func update_statuses():
	if not status_container:
		return
	
	for child in status_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for status_data in enemy_instance.get_active_statuses_for_ui():
		var tooltip = "%s: %d" % [status_data["name"], status_data["stacks"]]
		if status_data.get("duration", 0) > 0:
			tooltip += " (осталось: %d)" % status_data["duration"]
		var icon = _create_icon(status_data["icon"], 32, tooltip)
		status_container.add_child(icon)


func update_passives():
	if not passive_container:
		return
	
	for child in passive_container.get_children():
		child.queue_free()
	
	if not enemy_instance:
		return
	
	for passive_data in enemy_instance.get_active_passives_for_ui():
		var tooltip = "%s\n%s" % [passive_data["name"], passive_data["description"]]
		var icon = _create_icon(passive_data["icon"], 32, tooltip)
		passive_container.add_child(icon)


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
	SignalManager.enemy_health_changed.disconnect(_on_enemy_health_changed)
	SignalManager.enemy_status_changed.disconnect(_on_enemy_status_changed)


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

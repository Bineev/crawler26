# scripts/ui/card_ui.gd
extends Node2D
class_name CardUI

#enum CardState { IDLE, HOVERED, SELECTED, AIMING, PLAYED, BURNED }
var state: DataManager.CardState = DataManager.CardState.IDLE

## ============================================================
## ССЫЛКИ НА НОДЫ
## ============================================================
var template: MarginContainer = null
var cost_label: Label = null
var name_label: Label = null
var art_image: TextureRect = null
var art_background: ColorRect = null
var description_label: RichTextLabel = null
var left_icons: VBoxContainer = null
var right_icons: VBoxContainer = null
var card_control: Control = null
var click_area: Area2D = null
var collision_shape: CollisionShape2D = null
var effect_overlay: ColorRect = null
var effect_overlay2: ColorRect = null
var effect_overlay3: ColorRect = null
var background : TextureRect = null
var art_shader: ColorRect = null


## ============================================================
## ДАННЫЕ КАРТЫ
## ============================================================
@export var card_data: CardData

## ============================================================
## КОНСТАНТЫ
## ============================================================
const ICON_SIZE: int = DataManager.CARD_ICON_SIZE
const CARD_BASE_WIDTH: int = DataManager.CARD_BASE_WIDTH
const CARD_BASE_HEIGHT: int = DataManager.CARD_BASE_HEIGHT
const CARD_SCALE_HOVER: float = DataManager.CARD_SCALE_HOVER
const CARD_SCALE_IN_HAND: float = DataManager.CARD_SCALE_IN_HAND
var shader_time: float = 0.0
## ============================================================
## СОСТОЯНИЕ
## ============================================================
var original_scale: Vector2 = Vector2.ONE
var original_position: Vector2 = Vector2.ZERO
var original_z_index: int = 0
var original_parent: Node = null
var hand_ui_ref: HandUI = null
var current_tween: Tween = null
var highlight_tween: Tween = null

var _needs_appear_animation: bool = false
var _appear_delay: float = 0.0
var highlight_material: ShaderMaterial = null
var base_material: ShaderMaterial = null
var is_highlighted: bool = false
## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================
func _ready():
	# Инициализируем ссылки на ноды
	template = $CardTemplate
	cost_label = $CardTemplate/CardBackground/CostLabel
	background = $CardTemplate/CardBackground
	name_label = $CardTemplate/MarginContainer/MainLayout/HeaderLayout/Control/CardName
	art_image = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/ArtContainer/ArtImage
	art_background = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/ArtContainer/ArtBackground
	description_label = $CardTemplate/MarginContainer/MainLayout/DescriptionContainer/Control/CardDescription
	left_icons = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/LeftIcons
	right_icons = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/RightIcons
	card_control = $CardTemplate
	click_area = $ClickArea
	collision_shape = $ClickArea/CollisionShape2D
	effect_overlay = $CardTemplate/ShaderRect
	effect_overlay2 = $CardTemplate/ShaderRect2
	effect_overlay3 = $CardTemplate/ShaderRect3
	art_shader = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/ArtContainer/ArtShader
	
	original_position = position
	original_z_index = z_index
	
	card_control.mouse_entered.connect(_on_mouse_entered)
	card_control.mouse_exited.connect(_on_mouse_exited)
	
	left_icons.custom_minimum_size = Vector2(32, 0)
	right_icons.custom_minimum_size = Vector2(32, 0)

	#set_glow(false)
	#_apply_highlight(false)
	#effect_overlay.show()
		# Делаем материал уникальным для этой конкретной карты
	if effect_overlay.material:
		effect_overlay.material = effect_overlay.material.duplicate()
	if effect_overlay2.material:
		effect_overlay2.material = effect_overlay2.material.duplicate()

	_setup_click_area()


## ============================================================
## ОСНОВНОЙ МЕТОД ЗАПОЛНЕНИЯ КАРТЫ
## ============================================================
func display():
	if not card_data:
		return
	
	cost_label.text = str(card_data.cost)
	name_label.text = _smart_wrap_card_name(card_data.get_localized_name())
	
	var illustration = card_data.get_illustration()
	if illustration and art_image:
		art_image.texture = illustration
	
	# Уменьшаем ArtImage на 20%
	if art_image:
		var scale_factor = 0.8
		art_image.scale = Vector2(scale_factor, scale_factor)
		# Центрируем
		art_image.position = Vector2(
			art_image.size.x * (1 - scale_factor) / 2,
			art_image.size.y * (1 - scale_factor) / 2
		)
		# 🆕 Устанавливаем цвет свечения по биому
		
	# 🆕 Устанавливаем цвет свечения по карте
	set_glow_color_by_biome(card_data)
	
	description_label.text = card_data.generate_dynamic_description()
	
	var card_bg = $CardTemplate/CardBackground as TextureRect
	if card_bg:
		var bg_texture = card_data.get_card_background()
		if bg_texture:
			card_bg.texture = bg_texture
	
	art_background.color = card_data.get_art_background_color(true)
	
	clear_icons()
	fill_left_icons()
	fill_right_icons()


func _smart_wrap_card_name(name: String) -> String:
	var words = name.split(" ")
	if words.size() <= 1:
		return name
	
	var prepositions = ["of", "the", "and", "to", "for", "with", "by", "in", "on", "at", "from", "into", "through", "during", "without", "against", "among", "along", "between", "about", "like", "via", "per"]
	
	if words.size() == 2:
		if words[0].to_lower() in prepositions or words[1].to_lower() in prepositions:
			return name
		return words[0] + "\n" + words[1]
	
	var split_index = words.size() / 2
	for i in range(words.size()):
		if words[i].to_lower() in prepositions:
			split_index = i
			break
	
	return " ".join(words.slice(0, split_index)) + "\n" + " ".join(words.slice(split_index, words.size()))


## ============================================================
## ИКОНКИ
## ============================================================
func clear_icons():
	if left_icons:
		for child in left_icons.get_children():
			child.queue_free()
	if right_icons:
		for child in right_icons.get_children():
			child.queue_free()


func fill_left_icons():
	if not left_icons:
		return
	
	var items: Array[Dictionary] = []
	_collect_left_icons_from_effects(card_data.effects, items)
	
	for item in _unique_items(items):
		add_icon(left_icons, item["texture"], item["is_status"], item["id"])


func _collect_left_icons_from_effects(effects: Array[EffectEntry], items: Array[Dictionary]):
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.status:
					var icon = DataManager.get_status_icon(effect.status.id)
					if icon:
						items.append({
							"texture": icon,
							"is_status": true,
							"id": effect.status.id
						})
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive:
					var icon = DataManager.get_passive_icon(effect.passive.id)
					if icon:
						items.append({
							"texture": icon,
							"is_status": false,
							"id": effect.passive.id
						})
			DataManager.EffectCategory.CONDITIONAL:
				if effect.true_effect:
					_collect_left_icons_from_effects([effect.true_effect], items)
				if effect.false_effect:
					_collect_left_icons_from_effects([effect.false_effect], items)
			DataManager.EffectCategory.BLOCK:  # 🆕
				var icon = DataManager.get_status_icon(DataManager.Status.SHIELD)
				if icon:
					items.append({
						"texture": icon,
						"is_status": true,
						"id": DataManager.Status.SHIELD
					})


func fill_right_icons():
	if not right_icons:
		return
	
	var items: Array[Dictionary] = []
	
	for card_type in card_data.get_card_types():
		var icon = DataManager.get_card_type_icon(card_type)
		if not icon:
			continue
		
		items.append({
			"texture": icon,
			"is_status": false,
			"id": card_type,
			"is_card_type": true,
		})
	
	for item in _unique_items(items):
		add_icon(right_icons, item["texture"], false, item["id"], true)  # 🆕 передаём is_card_type 


func _add_right_icon(icon: Texture2D, tooltip: String, icons: Array[Texture2D], tooltips: Array[String]):
	if not icons.has(icon):
		icons.append(icon)
		tooltips.append(tooltip)

func add_icon(container: VBoxContainer, texture: Texture2D, is_status: bool = true, id: int = -1, is_card_type: bool = false):
	var icon_node: Control
	
	if is_status:
		# Статусы
		icon_node = preload("res://scenes/status_icon.tscn").instantiate() as StatusIcon
		container.add_child(icon_node)
		
		var data = {
			"status_id": id,
			"icon": texture,
			"name": DataManager.get_status_name(id),
			"stacks": 0,
			"duration": 0,
		}
		icon_node.setup(data, DataManager.COLOR_PENITENT_ART_BG_DARK, self)
		icon_node.mouse_entered.connect(_on_status_icon_hovered.bind(id))
		icon_node.mouse_exited.connect(_on_icon_mouse_exited)
	
	elif is_card_type:
		# Типы карт (правые иконки)
		var icon = TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_PASS
		container.add_child(icon)
		icon.mouse_entered.connect(_on_card_type_icon_hovered.bind(id))
		icon.mouse_exited.connect(_on_icon_mouse_exited)
	else:
		# Пассивки
		icon_node = preload("res://scenes/passive_icon.tscn").instantiate() as PassiveIcon
		container.add_child(icon_node)
		
		var passive_resource = DataManager.get_passive_resource(id)
		var data = {
			"passive_id": id,
			"icon": texture,
			"name": passive_resource.get_localized_name(),
			"description": passive_resource.get_localized_description(),
			"charges": 0,
		}
		icon_node.setup(data, DataManager.COLOR_PENITENT_ART_BG_DARK, self)
		icon_node.mouse_entered.connect(_on_passive_icon_hovered.bind(id))
		icon_node.mouse_exited.connect(_on_icon_mouse_exited)

func _get_status_id_from_tooltip(tooltip_text: String) -> int:
	for status_id in DataManager.Status.values():
		var name = DataManager.get_status_name(status_id)
		if tooltip_text == name:
			return status_id
	return -1

func _get_passive_id_from_tooltip(tooltip_text: String) -> int:
	for passive_id in DataManager.Passive.values():
		var name = DataManager.get_passive_name(passive_id)
		if tooltip_text == name:
			return passive_id
	return -1
	
	
func set_glow(enabled: bool):
	var mat = effect_overlay.material as ShaderMaterial
	if not mat: 
		return
	
	if enabled:
		# Выставляем рабочие значения параметров
		mat.set_shader_parameter("glow_softness", 0.15)
		mat.set_shader_parameter("flash_speed", 2.0)
	else:
		# Полностью сбрасываем в ноль, убирая эффекты
		mat.set_shader_parameter("glow_softness", 0.0)
		mat.set_shader_parameter("flash_speed", 0.0)


func _unique_icons(icons: Array[Texture2D], tooltips: Array[String]) -> Array[Dictionary]:
	var unique: Array[Dictionary] = []
	for i in range(icons.size()):
		var exists = false
		for u in unique:
			if u["texture"] == icons[i]:
				exists = true
				break
		if not exists:
			unique.append({"texture": icons[i], "tooltip": tooltips[i]})
	return unique


## ============================================================
## ВЗАИМОДЕЙСТВИЕ
## ============================================================
func on_card_clicked():
	print("on_card_clicked called, current state: ", state)  # Отладка
	
	if state != DataManager.CardState.HOVERED:
		print("Not in HOVERED state, ignoring")
		return
	
	if not BattleManager.is_player_turn():
		SignalManager.log_message.emit(tr("msg_not_player_turn"))
		return
	
	var player_stats = BattleManager.get_player()
	if not player_stats:
		return
	
	if player_stats.get_flat(DataManager.FlatStat.ENERGY) < card_data.cost:
		SignalManager.log_message.emit(tr("msg_not_enough_energy"))
		return
	
	#TODO
	state = DataManager.CardState.SELECTED
	#set_glow(true)
	set_highlight(true)
	
	
#func _apply_highlight(enabled: bool):
	#if not background:
		#return
	#
	#if enabled:
		#if not highlight_material:
			#var shader = preload("res://shaders/highlight_enemy2.gdshader")
			#highlight_material = ShaderMaterial.new()
			#highlight_material.shader = shader
		#highlight_material.set_shader_parameter("pulse_color", DataManager.COLOR_BONE_LABYRINTH_CARD_BG)  # оранжевый
		#base_material = background.material
		#highlight_material.set_shader_parameter("hover_intensity", 0.3)
		#background.material = highlight_material
		#
		## Анимируем интенсивность пульсации через Tween
		#var tween = create_tween()
		#tween.set_loops()
		#tween.tween_property(highlight_material, "shader_parameter/hover_intensity", 0.5, 0.4)
		#tween.tween_property(highlight_material, "shader_parameter/hover_intensity", 1.5, 0.4)
	#else:
		#if highlight_material:
			#highlight_material.set_shader_parameter("hover_intensity", 0.0)
			#background.material = base_material
			#highlight_material = null


func _apply_highlight_shader(enabled: bool):
	if not background:
		return
	
	if enabled:
		var shader = preload("res://shaders/highlight_enemy3.gdshader")
		var shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		
		# Настройки шейдера
		shader_material.set_shader_parameter("contrast", 1.8)
		shader_material.set_shader_parameter("grayscale_intensity", 0.8)
		shader_material.set_shader_parameter("tint_color", Color(1.0, 0.85, 0.3, 1.0))
		shader_material.set_shader_parameter("tint_intensity", 0.15)
		
		background.material = shader_material
	else:
		background.material = null


func play_card(target = null):
	if state != DataManager.CardState.AIMING:
		return
	
	state = DataManager.CardState.PLAYED
	
	var player_stats = BattleManager.get_player()
	if not player_stats:
		state = DataManager.CardState.IDLE
		return
	
	# Списываем энергию
	player_stats.modify_flat(DataManager.FlatStat.ENERGY, -card_data.cost)

	# 🆕 Обрабатываем артефакты с триггером CARD_PLAYED_COUNTER
	RunManager.process_artifacts_on_card_played(card_data)
	

	
	if target and target is EnemyInstance:
		await animate_to_target(target)  # ← await
	else:
		await animate_to_center()        # ← await

	var battle_deck = BattleManager.get_battle_deck()
	if battle_deck:
		battle_deck.play_card(self, card_data, target)


func _needs_target() -> bool:
	for effect in card_data.effects:
		if effect.target in [DataManager.EffectTarget.ENEMY, DataManager.EffectTarget.ANY]:
			return true
	return false


func _get_targets_for_effect(effect: EffectEntry, selected_target) -> Array:
	match effect.target:
		DataManager.EffectTarget.SELF:
			return [BattleManager.get_player()]
		DataManager.EffectTarget.ENEMY:
			if selected_target:
				return [selected_target]
			var enemies = BattleManager.get_enemies()
			return [enemies[0]] if enemies.size() > 0 else []
		DataManager.EffectTarget.ALL_ENEMIES:
			return BattleManager.get_enemies()
		DataManager.EffectTarget.ALL_ALLIES:
			return [BattleManager.get_player()]
		DataManager.EffectTarget.ANY:
			return [selected_target] if selected_target else []
	return []


func cancel_selection():
	if state == DataManager.CardState.SELECTED or state == DataManager.CardState.AIMING:
		if current_tween:
			current_tween.kill()
			current_tween = null
		
		_return_to_original()
		state = DataManager.CardState.IDLE
		
		if hand_ui_ref:
			hand_ui_ref.set_all_cards_input_enabled(true)
			hand_ui_ref.clear_hovered_card(self)
		
		SignalManager.target_selection_cancelled.emit()
		reset_highlight()


func confirm_target(target):
	if state == DataManager.CardState.AIMING:
		play_card(target)


## ============================================================
## АНИМАЦИИ
## ============================================================
func _on_mouse_entered():
	if state == DataManager.CardState.IDLE:
		state = DataManager.CardState.HOVERED
		print('go hovered')
		
		SoundManager.play(null, DataManager.get_sound(DataManager.SoundType.CARD_HOVER))
		
		if current_tween:
			current_tween.kill()
			current_tween = null
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2(CARD_SCALE_HOVER, CARD_SCALE_HOVER), 0.1)
		
		var screen_center_x = get_viewport().get_visible_rect().size.x / 2
		var card_center_x = global_position.x + (get_card_size().x / 2)
		var offset_to_center = (screen_center_x - card_center_x) * DataManager.CARD_HOVER_CENTER_FORCE
		tween.tween_property(self, "position", original_position + Vector2(offset_to_center, -DataManager.CARD_HOVER_RAISE), 0.1)
		
		z_index = 10
		current_tween = tween
		
		if hand_ui_ref:
			hand_ui_ref.try_set_hovered_card(self)


func _on_mouse_exited():
	if state == DataManager.CardState.HOVERED:
		state = DataManager.CardState.IDLE
		print('go idle')
		
		if current_tween:
			current_tween.kill()
			current_tween = null
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", original_scale, 0.1)
		tween.tween_property(self, "position", original_position, 0.1)
		tween.tween_callback(func(): z_index = original_z_index)
		current_tween = tween
		
		if hand_ui_ref:
			hand_ui_ref.clear_hovered_card(self)


func _move_to_center():
	if current_tween:
		current_tween.kill()
		current_tween = null
	
	var viewport = get_viewport()
	var screen_center_x = viewport.get_visible_rect().size.x / 2
	var card_size = get_card_size()
	
	# Целевая позиция: центр по X, Y остаётся текущий (от наведения)
	var target_global_x = screen_center_x - card_size.x / 2
	var target_local_x = get_parent().to_local(Vector2(target_global_x, 0)).x
	
	# Сохраняем текущую Y позицию (от наведения)
	var target_pos = Vector2(target_local_x, position.y)
	
	# Сохраняем текущий масштаб
	var current_scale = scale
	original_scale = current_scale
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.2)
	tween.tween_callback(func(): z_index = 100)
	current_tween = tween


func _return_to_original():
	if current_tween:
		current_tween.kill()
		current_tween = null
	
	# Возвращаемся к исходной позиции (до наведения)
	var target_pos = original_position
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.2)
	tween.tween_property(self, "scale", original_scale, 0.2)
	tween.tween_callback(func(): 
		z_index = original_z_index
		state = DataManager.CardState.IDLE
	)
	current_tween = tween


func _process(delta):
	if state == DataManager.CardState.IDLE:
		# Получаем позицию мыши относительно центра самой карты
		var mouse_pos2 = get_local_mouse_position()
		var card_size2 = get_card_size()
		
		# Переводим координаты в диапазон от -0.5 до 0.5
		var relative_mouse = Vector2(
			(mouse_pos2.x / card_size2.x) - 0.5,
			(mouse_pos2.y / card_size2.y) - 0.5
		).clamp(Vector2(-1.0, -1.0), Vector2(1.0, 1.0))
		
		# 1. СЛЕГКА УМЕНЬШИЛИ НАКЛОН (Снизили множитель с 0.12 до 0.05)
		var target_rotation = relative_mouse.x * 0.05 
		rotation = lerp(rotation, target_rotation, 8.0 * delta)
		
		# 2. МЯГКАЯ ИМИТАЦИЯ 3D (Снизили деформацию краев с 0.04 до 0.015)
		var target_scale_x = 1.0 - abs(relative_mouse.y) * 0.015
		var target_scale_y = 1.0 - abs(relative_mouse.x) * 0.015
		scale.x = lerp(scale.x, target_scale_x, 8.0 * delta)
		scale.y = lerp(scale.y, target_scale_y, 8.0 * delta)
		
		# 3. Передаем наклон в шейдер
		var mat = effect_overlay2.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("mouse_offset", relative_mouse)
	else:
		# --- ВОЗВРАЩАЕМ В НЕПОДВИЖНОЕ СОСТОЯНИЕ И ВЫПРЯМЛЯЕМ КАРТУ ---
		# Плавно возвращаем поворот в ноль
		rotation = lerp(rotation, 0.0, 12.0 * delta)
		
		# Плавно возвращаем масштаб в стандартный 1.0 по обеим осям
		scale.x = lerp(scale.x, DataManager.CARD_SCALE_HOVER, 12.0 * delta)
		scale.y = lerp(scale.y, DataManager.CARD_SCALE_HOVER, 12.0 * delta)
		
		# Плавно возвращаем параллакс грязи в шейдере в центр
		var mat = effect_overlay2.material as ShaderMaterial
		if mat:
			var current_offset = mat.get_shader_parameter("mouse_offset")
			if current_offset:
				# Используем lerp для Vector2, чтобы грязь мягко «встала на место»
				var target_offset = current_offset.lerp(Vector2.ZERO, 12.0 * delta)
				mat.set_shader_parameter("mouse_offset", target_offset)
		
	if state == DataManager.CardState.SELECTED:
		var mouse_pos = get_viewport().get_mouse_position()
		var card_rect = Rect2(global_position - get_card_size() / 2, get_card_size())
		
		# Если мышь выше верхнего края карты или на определённом расстоянии
		var threshold = 200  # пикселей от верхнего края
		if mouse_pos.y < card_rect.position.y + threshold:
			print("Mouse above card, moving to center")
			state = DataManager.CardState.AIMING
			#TODO Вернуть, если будет нужно
			#_move_to_center()
			SignalManager.target_selection_requested.emit(self)
	
	# ПКМ для отмены
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if state == DataManager.CardState.SELECTED or state == DataManager.CardState.AIMING:
			cancel_selection()


## ============================================================
## НАСТРОЙКИ
## ============================================================
func set_hand_scale():
	original_scale = Vector2(CARD_SCALE_IN_HAND, CARD_SCALE_IN_HAND)
	scale = original_scale
	
	if collision_shape:
		var scaled_size = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * CARD_SCALE_IN_HAND
		var rect_shape = collision_shape.shape as RectangleShape2D
		if rect_shape:
			rect_shape.size = scaled_size
			collision_shape.position = scaled_size / 2


func _setup_click_area():
	if not click_area or not collision_shape:
		return
	
	# Отключаем старый сигнал, если он уже подключён
	if click_area.input_event.is_connected(_on_click_area_input):
		click_area.input_event.disconnect(_on_click_area_input)
	
	var rect_shape = RectangleShape2D.new()
	var card_size = Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT)
	rect_shape.size = card_size
	collision_shape.shape = rect_shape
	collision_shape.position = card_size / 2
	
	click_area.input_event.connect(_on_click_area_input)


func get_card_size() -> Vector2:
	return Vector2(CARD_BASE_WIDTH, CARD_BASE_HEIGHT) * scale


func get_actual_size() -> Vector2:
	var s = card_control.size
	var sc = card_control.scale
	return card_control.size * card_control.scale


func set_hand_ui(hand_ui: HandUI):
	hand_ui_ref = hand_ui


func _on_click_area_input(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_card_clicked()
#
#
#func set_highlight(enabled: bool):
	#modulate = Color(1, 0.5, 0.2) if enabled else Color.WHITE


func _on_animation_finished():
	if hand_ui_ref:
		hand_ui_ref.remove_card(self)
	else:
		queue_free()


func play_burn_animation():
	if not effect_overlay3:
		return
	
	var burn_material = effect_overlay3.material as ShaderMaterial
	if not burn_material:
		return
		
	# Гарантируем, что пока карта едет, шейдер еще не горит
	burn_material.set_shader_parameter("death_progress", 0.0)
	
	# Высчитываем целевую глобальную позицию (замените вектор на нужный вам)
	var target_global_position = Vector2(50, 600)
	
	var tween = create_tween()
	
	# Настраиваем плавность для движения (плавный старт и торможение)
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	
	# ШАГ 1: Карта отъезжает (например, за 1.5 секунды)
	tween.tween_property(
		self,
		"global_position", 
		target_global_position, 
		0.5
	)
	
	effect_overlay3.show()
	
	# ШАГ 2: Включается шейдер горения (займет 2.0 секунды)
	# Этот шаг начнется автоматически, как только завершится ШАГ 1
	tween.tween_property(
		burn_material, 
		"shader_parameter/death_progress", 
		1.0, 
		1
	)

	# Сигнал сработает в самом конце, когда шейдер полностью догорит


func animate_to_target(target_node: Node2D):
	if current_tween:
		current_tween.kill()
		current_tween = null
	
	var target_global_pos = target_node.global_position
	var target_local_pos = get_parent().to_local(target_global_pos)
	
	current_tween = create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "position", target_local_pos, 0.25).set_ease(Tween.EASE_IN)
	current_tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.25)
	current_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)
	
	await current_tween.finished
	#queue_free()


func animate_to_center():
	if current_tween:
		current_tween.kill()
		current_tween = null
	
	var screen_center = get_viewport().get_visible_rect().size / 2
	var target_local_pos = get_parent().to_local(screen_center)
	
	current_tween = create_tween()
	current_tween.set_parallel(true)
	current_tween.tween_property(self, "position", target_local_pos, 0.3).set_ease(Tween.EASE_IN)
	current_tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
	current_tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.25)
	
	await current_tween.finished


func play_appear_animation(target_position: Vector2, delay: float = 0.0):
	# Стартовая позиция: сбоку от экрана (справа)
	var start_pos = Vector2(2200, target_position.y)
	position = start_pos
	scale = Vector2(0.7, 0.7)
	modulate = Color(1, 1, 1, 1)

	# Ставим карту поверх всех во время анимации
	z_index = 100
	z_as_relative = false
	
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Летим к цели
	tween.tween_property(self, "position", target_position, 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target_position + Vector2(0, -8), 0.02).set_delay(0.23)
	tween.tween_property(self, "position", target_position, 0.02).set_delay(0.25)
	
	await tween.finished

	# Возвращаем правильный z_index
	z_index = original_z_index
	z_as_relative = false

#func move_to_position(target_position: Vector2, delay: float = 0.0):
	#if delay > 0:
		#await get_tree().create_timer(delay).timeout
	#
	#var tween = create_tween()
	#tween.tween_property(self, "position", target_position, 0.12).set_ease(Tween.EASE_OUT)
	#
	#await tween.finished
	#original_position = target_position


func move_to_position(target_position: Vector2, delay: float = 0.0):
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.15).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	original_position = target_position


func fly_away_left(delay: float = 0.0):
	if delay > 0:
		await get_tree().create_timer(delay).timeout
	
	var target_pos = Vector2(-300, position.y - 50)  # улетает влево и вверх
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_pos, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.3)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.25)
	
	await tween.finished
	queue_free()


func set_highlight(enabled: bool):
	if is_highlighted == enabled:
		return
	
	is_highlighted = enabled
	
	if enabled:
		# Сохраняем оригинальную позицию
		#original_position = position
		
		# Применяем шейдер подсветки
		_apply_highlight_shader(true)
		
		# Запускаем раскачивание
		_start_bobbing()
	else:
		# Останавливаем раскачивание
		_stop_bobbing()
		
		# Убираем шейдер
		_apply_highlight_shader(false)


func _start_bobbing():
	if highlight_tween:
		highlight_tween.kill()
	
	var start_pos = position
	
	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.tween_property(self, "position", start_pos + Vector2(0, -10), 0.5).set_ease(Tween.EASE_OUT_IN)
	highlight_tween.tween_property(self, "position", start_pos + Vector2(0, 10), 0.5).set_ease(Tween.EASE_OUT_IN)


func _stop_bobbing():
	if highlight_tween:
		highlight_tween.kill()
		highlight_tween = null
	
	# Возвращаемся в исходную позицию (из original_position)
	position = original_position


func reset_highlight():
	set_highlight(false)
	position = original_position
	scale = original_scale
	modulate = Color(1, 1, 1, 1)


func set_reward_state() -> void:
	state = DataManager.CardState.REWARD
	# Отключаем взаимодействие
	card_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Убираем анимации наведения и т.д.


func set_glow_color_by_biome(card: CardData) -> void:
	if not art_shader:
		return
	
	var mat = art_shader.material as ShaderMaterial
	if not mat:
		return
	
	var color = DataManager.get_glow_color_for_card(card)
	mat.set_shader_parameter("glow_color", color)


func _on_status_icon_hovered(status_id: DataManager.Status):
	var pos = get_global_mouse_position()
	TooltipManager.request_status_tooltip(status_id, pos)

func _on_passive_icon_hovered(passive_id: DataManager.Passive):
	var pos = get_global_mouse_position()
	TooltipManager.request_passive_tooltip(passive_id, pos)


func _unique_items(items: Array[Dictionary]) -> Array[Dictionary]:
	var unique: Array[Dictionary] = []
	for item in items:
		var exists = false
		for u in unique:
			if u["texture"] == item["texture"]:
				exists = true
				break
		if not exists:
			unique.append(item)
	return unique


func _on_card_type_icon_hovered(card_type: DataManager.CardType):
	var pos = get_global_mouse_position()
	TooltipManager.request_card_type_tooltip(card_type, pos)


func _on_icon_mouse_exited():
	SignalManager.hide_tooltip.emit()

extends TextureRect
class_name PotionIcon

var potion_data: PotionResource = null
var is_selected: bool = false
var use_button: Button = null
var is_interactable: bool = true
var is_in_combat: bool = false

func _ready():
	use_button = Button.new()
	use_button.text = tr("potion_use")
	use_button.modulate = Color(1, 1, 1, 0)  # 🆕 прозрачный
	use_button.disabled = true
	use_button.pressed.connect(_on_use_pressed)
	
	use_button.add_theme_font_override("font", DataManager.FONT_HEADERS)
	use_button.add_theme_font_size_override("font_size", 16)
	use_button.custom_minimum_size = Vector2(80, 30)
	
	add_child(use_button)

	# 🆕 Подписываемся на сигналы хода
	# 🆕 Подключаем сигнал
	gui_input.connect(_on_gui_input)
	SignalManager.player_turn_started.connect(_on_player_turn_started)
	SignalManager.enemy_turn_started.connect(_on_enemy_turn_started)
	SignalManager.battle_started.connect(_on_battle_started)
	SignalManager.battle_victory.connect(_on_battle_ended)
	SignalManager.battle_defeat.connect(_on_battle_ended)

	# Позиционируем кнопку под зельем
	use_button.position = Vector2(
		(size.x - use_button.size.x) / 2,
		size.y + 5
	)

func setup(potion: PotionResource) -> void:
	potion_data = potion
	
	var icon_texture = DataManager.get_potion_icon(potion.potion_type)
	if icon_texture:
		texture = icon_texture
	else:
		pass
		#texture = preload("res://img/potions/default.png")
	
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	custom_minimum_size = Vector2(64, 64)
	size = Vector2(64, 64)
	DataManager.apply_shader_to_icon(self, "res://shaders/highlight_item2.gdshader", {'hover_intensity' : 1.0})
	DataManager.apply_shader_overlay(self, "res://shaders/horror_shader.gdshader")
	# Тултип
	var tooltip = potion.get_localized_name()
	var desc = potion.get_localized_description()
	if not desc.is_empty():
		tooltip += "\n" + desc
	tooltip_text = tooltip

func select() -> void:
	is_selected = true
	use_button.modulate = Color(1, 1, 1, 1)  # 🆕 становимся видимой
	use_button.disabled = false
	#modulate = Color(1, 0.8, 0.2, 1)  # подсветка

func deselect() -> void:
	is_selected = false
	use_button.modulate = Color(1, 1, 1, 0)  # 🆕 прозрачная
	use_button.disabled = true
	#modulate = Color(1, 1, 1, 1)

func _on_use_pressed() -> void:
	if is_in_combat:
		SignalManager.potion_used.emit(self)
	else:
		SignalManager.potion_discarded.emit(self)
		deselect()

func _on_gui_input(event: InputEvent) -> void:
	if not is_interactable:
		return
	
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				# Снимаем выделение со всех других зелий
				SignalManager.potion_deselect_all.emit()
				
				# Переключаем состояние текущего
				if is_selected:
					deselect()
				else:
					select()
			
			MOUSE_BUTTON_RIGHT:
				# Деселект текущего зелья по ПКМ
				if is_selected:
					deselect()


func set_interactable(enabled: bool) -> void:
	is_interactable = enabled


func _on_player_turn_started() -> void:
	set_interactable(true)

func _on_enemy_turn_started() -> void:
	set_interactable(false)
	if is_selected:
		deselect()


func _on_battle_started() -> void:
	is_in_combat = true
	set_interactable(true)  # или false, зависит от логики
	_update_button_text()

func _on_battle_ended() -> void:
	is_in_combat = false
	set_interactable(true)  # 🆕 делаем интерактивными после боя
	if is_selected:
		deselect()
	_update_button_text()

func _update_button_text() -> void:
	if use_button:
		if is_in_combat:
			use_button.text = tr("potion_use")
		else:
			use_button.text = tr("potion_discard")

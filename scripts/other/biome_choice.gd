extends Control
class_name BiomeChoice

@onready var center_container: CenterContainer = $CenterContainer
@onready var vbox: VBoxContainer = $CenterContainer/VBoxContainer
@onready var hbox: HBoxContainer = $CenterContainer/VBoxContainer/HBoxContainer
@onready var title_label: Label = $CenterContainer/VBoxContainer/Title

var selected_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
var biome_buttons: Array[Control] = []


func _ready():
	_setup_ui()


func _setup_ui():
	title_label.text = tr("biome_choice_title")
	title_label.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Получаем доступные биомы
	var biomes = ProgressManager.get_random_biomes(2)
	
	# Показываем столько карточек, сколько биомов доступно
	for biome in biomes:
		var card = _create_biome_card(biome)
		hbox.add_child(card)


func _create_biome_card(biome: DataManager.Biome) -> Control:
	var card = VBoxContainer.new()
	card.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_theme_constant_override("separation", 30)
	card.custom_minimum_size = Vector2(300, 0)
	
	# Название
	var title = Label.new()
	title.text = DataManager.get_biome_name(biome)
	title.add_theme_font_override("font", DataManager.FONT_HEADERS)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	
	# Превью
	var preview = TextureRect.new()
	preview.texture = DataManager.get_biome_preview(biome)
	preview.custom_minimum_size = Vector2(400, 400)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter = Control.MOUSE_FILTER_STOP
	preview.set_meta("biome", biome)
	
	# Подсветка при наведении
	var shader = preload("res://shaders/highlight_enemy.gdshader")
	var highlight_material = ShaderMaterial.new()
	highlight_material.shader = shader
	highlight_material.set_shader_parameter("hover_intensity", 0.0)
	preview.material = highlight_material
	
	preview.mouse_entered.connect(_on_preview_hovered.bind(preview, true))
	preview.mouse_exited.connect(_on_preview_hovered.bind(preview, false))
	preview.gui_input.connect(_on_preview_clicked.bind(preview, biome))
	
	card.add_child(preview)
	
	# Описание
	var desc = Label.new()
	desc.text = DataManager.get_biome_description(biome)
	desc.add_theme_font_override("font", DataManager.FONT_MAIN)
	desc.add_theme_font_size_override("font_size", 20)
	desc.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.custom_minimum_size = Vector2(350, 0)
	card.add_child(desc)
	
	biome_buttons.append(preview)
	
	return card


func _on_preview_hovered(preview: TextureRect, enabled: bool):
	if preview.material and preview.material is ShaderMaterial:
		var mat = preview.material as ShaderMaterial
		mat.set_shader_parameter("hover_intensity", 1.0 if enabled else 0.0)


func _on_preview_clicked(event: InputEvent, preview: TextureRect, biome: DataManager.Biome):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Анимация выбора
		var tween = create_tween()
		tween.tween_property(preview, "scale", Vector2(1.05, 1.05), 0.1)
		tween.tween_property(preview, "scale", Vector2(1.0, 1.0), 0.1)
		
		await tween.finished
		
		# 🆕 Устанавливаем биом через GameTestManager
		GameTestManager.set_biome(biome)
		
		# 🆕 Отправляем сигнал StartBiome
		SignalManager.start_biome.emit()

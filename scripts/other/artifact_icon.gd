extends ColorRect
class_name ArtifactIcon

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var counter_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CounterLabel
@onready var filler: Control = $MarginContainer/VBoxContainer/HBoxContainer/Filler
@onready var text_container: HBoxContainer = $MarginContainer/VBoxContainer/HBoxContainer


var artifact_id: DataManager.ArtifactId
var artifact_resource: ArtifactResource

func _ready():
	_setup_label()
	SignalManager.artifact_triggered.connect(_on_artifact_triggered)
	SignalManager.artifact_counter_changed.connect(_on_artifact_counter_changed)

func _setup_label():
	counter_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	counter_label.add_theme_font_size_override("font_size", 14)
	counter_label.add_theme_color_override("font_color", DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT2)
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter_label.visible = false

func setup(artifact: ArtifactResource, is_in_reward: bool) -> void:
	artifact_id = artifact.id
	artifact_resource = artifact
	icon.texture = artifact.get_icon()
	custom_minimum_size  = Vector2(64, 64)
	icon.custom_minimum_size = Vector2(48, 48)
	filler.custom_minimum_size = Vector2(5, 0)
	if is_in_reward:
		custom_minimum_size = Vector2(128, 128)
		icon.custom_minimum_size = Vector2(96, 96)
		text_container.hide()
		color = Color(0, 0, 0, 0)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	#DataManager.apply_shader_to_icon(icon, "res://shaders/highlight_item.gdshader", {'hover_intensity' : 1.0})
	#DataManager.apply_shader_overlay(icon, "res://shaders/horror_shader.gdshader", {})
	
	# 🆕 Подключаем кастомный тултип
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	_show_counter(artifact)

func _show_counter(artifact: ArtifactResource) -> void:
	var counter_value = 0
	var max_value = 0
	var show_counter = false
	
	for trigger in artifact.triggers:
		match trigger:
			DataManager.ArtifactTrigger.TURN_COUNT_START, DataManager.ArtifactTrigger.TURN_COUNT_END:
				max_value = artifact.trigger_count
				counter_value = RunManager.get_artifact_counter(artifact.id)
				show_counter = true
			DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER:
				max_value = artifact.card_count_threshold
				counter_value = RunManager.get_artifact_counter(artifact.id)
				show_counter = true
			_:
				continue
	
	if show_counter:
		# 🆕 Просто показываем значение без пересчётов
		counter_label.text = "%d/%d" % [counter_value, max_value]
		counter_label.visible = true
	else:
		counter_label.visible = false

func update_counter() -> void:
	if not artifact_resource:
		return
	_show_counter(artifact_resource)

func animate() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "position", icon.position + Vector2(0, -5), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(icon, "scale", Vector2(1, 1), 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)
	tween.tween_property(icon, "position", icon.position - Vector2(0, -5), 0.15).set_delay(0.15).set_ease(Tween.EASE_IN)


func _on_artifact_counter_changed(artifact_id: DataManager.ArtifactId, counter: int) -> void:
	if self.artifact_id != artifact_id:
		return
	# 🆕 Обновляем счётчик без анимации
	update_counter()

func _on_artifact_triggered(artifact: ArtifactResource) -> void:
	if artifact_id != artifact.id:
		return
	# 🆕 Только анимация (счётчик уже обновился через counter_changed)
	animate()


func _on_mouse_entered():
	if artifact_resource:
		var pos = get_global_mouse_position()
		TooltipManager.request_artifact_tooltip(artifact_resource, pos)

func _on_mouse_exited():
	SignalManager.hide_tooltip.emit()

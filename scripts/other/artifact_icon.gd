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
	icon.tooltip_text = _build_tooltip()
	DataManager.apply_shader_to_icon(icon, "res://shaders/highlight_item.gdshader", {'hover_intensity' : 1.0})
	DataManager.apply_shader_overlay(icon, "res://shaders/horror_shader.gdshader", {})
	
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

func _build_tooltip() -> String:
	var name = artifact_resource.get_localized_name()
	var desc = artifact_resource.get_localized_description()
	var lore = artifact_resource.get_localized_lore()
	
	var tooltip = "%s\n%s" % [name, desc]
	if not lore.is_empty():
		tooltip += "\n\n%s" % lore
	
	#var trigger_texts: Array[String] = []
	#for trigger in artifact_resource.triggers:
		#match trigger:
			#DataManager.ArtifactTrigger.ONE_TIME:
				#trigger_texts.append(tr("artifact_trigger_one_time"))
			#DataManager.ArtifactTrigger.TURN_COUNT_START:
				#trigger_texts.append(tr("artifact_trigger_turn_count_start") % artifact_resource.trigger_count)
			#DataManager.ArtifactTrigger.TURN_COUNT_END:
				#trigger_texts.append(tr("artifact_trigger_turn_count_end") % artifact_resource.trigger_count)
			#DataManager.ArtifactTrigger.ON_START_FIGHT:
				#trigger_texts.append(tr("artifact_trigger_on_start_fight"))
			#DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER:
				#trigger_texts.append(tr("artifact_trigger_card_played_counter") % artifact_resource.card_count_threshold)
			#DataManager.ArtifactTrigger.HEALTH_DROPPED_BELOW:
				#trigger_texts.append(tr("artifact_trigger_conditional"))
			#DataManager.ArtifactTrigger.CUSTOM:
				#trigger_texts.append(tr("artifact_trigger_custom"))
	#
	#if not trigger_texts.is_empty():
		#tooltip += "\n\n" + "\n".join(trigger_texts)
	
	return tooltip

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

extends ColorRect
class_name ArtifactIcon

@onready var icon: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var counter_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/CounterLabel

var artifact_id: DataManager.ArtifactId
var artifact_resource: ArtifactResource

func _ready():
	_setup_label()

func _setup_label():
	counter_label.add_theme_font_override("font", DataManager.FONT_MAIN)
	counter_label.add_theme_font_size_override("font_size", 10)
	counter_label.add_theme_color_override("font_color", DataManager.COLOR_PENITENT_ART_BG_DARK)
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	counter_label.visible = false

func setup(artifact: ArtifactResource) -> void:
	artifact_id = artifact.id
	artifact_resource = artifact
	
	icon.texture = artifact.get_icon()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = _build_tooltip()
	
	_show_counter(artifact)

func _show_counter(artifact: ArtifactResource) -> void:
	var counter_value = 0
	var show_counter = false
	
	for trigger in artifact.triggers:
		match trigger:
			DataManager.ArtifactTrigger.TURN_COUNT_START, DataManager.ArtifactTrigger.TURN_COUNT_END:
				counter_value = artifact.trigger_count
				show_counter = true
			DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER:
				counter_value = RunManager.get_artifact_counter(artifact.id)
				show_counter = true
			_:
				continue
	
	if show_counter and counter_value > 0:
		counter_label.text = str(counter_value)
		counter_label.visible = true

func _build_tooltip() -> String:
	var name = artifact_resource.get_localized_name()
	var desc = artifact_resource.get_localized_description()
	var lore = artifact_resource.get_localized_lore()
	
	var tooltip = "%s\n%s" % [name, desc]
	if not lore.is_empty():
		tooltip += "\n\n%s" % lore
	
	var trigger_texts: Array[String] = []
	for trigger in artifact_resource.triggers:
		match trigger:
			DataManager.ArtifactTrigger.ONE_TIME:
				trigger_texts.append(tr("artifact_trigger_one_time"))
			DataManager.ArtifactTrigger.TURN_COUNT_START:
				trigger_texts.append(tr("artifact_trigger_turn_count_start") % artifact_resource.trigger_count)
			DataManager.ArtifactTrigger.TURN_COUNT_END:
				trigger_texts.append(tr("artifact_trigger_turn_count_end") % artifact_resource.trigger_count)
			DataManager.ArtifactTrigger.ON_START_FIGHT:
				trigger_texts.append(tr("artifact_trigger_on_start_fight"))
			DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER:
				trigger_texts.append(tr("artifact_trigger_card_played_counter") % artifact_resource.card_count_threshold)
			DataManager.ArtifactTrigger.HEALTH_DROPPED_BELOW:
				trigger_texts.append(tr("artifact_trigger_conditional"))
			DataManager.ArtifactTrigger.CUSTOM:
				trigger_texts.append(tr("artifact_trigger_custom"))
	
	if not trigger_texts.is_empty():
		tooltip += "\n\n" + "\n".join(trigger_texts)
	
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

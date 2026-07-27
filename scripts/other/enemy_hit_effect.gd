extends SubViewportContainer

@export var duration: float = 0.3
@onready var sub_viewport: SubViewport = $SubViewport

func play_slash_effect() -> void:
	if not material:
		return
	
	material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/progress", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func(): material.set_shader_parameter("progress", 0.0))
	await tween.finished


# 🆕 Проброс инпутов для ClickArea внутри SubViewport
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var local_event = event.duplicate()
		local_event.position = get_global_transform().affine_inverse() * event.global_position
		
		sub_viewport.push_input(local_event)
		sub_viewport.push_unhandled_input(local_event)

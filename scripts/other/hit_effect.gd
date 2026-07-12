# scripts/effects/hit_effect.gd
extends ColorRect
class_name HitEffect

@export var duration: float = 0.2

func _ready():
	material.set_shader_parameter("progress", 0.0)
	# Игнорируем клики, чтобы не мешать
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func play_slash_effect() -> void:
	# 1. Сбрасываем ползунок в чистый ноль перед ударом
	material.set_shader_parameter("progress", 0.0)
	
	var tween = create_tween()
	visible = true
	# 2. Быстро проносим порез от 0.0 до 1.0
	tween.tween_property(material, "shader_parameter/progress", 1.0, duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	# 3. Как только анимация завершилась, возвращаем progress в 0.0.
	# Из-за effect_active экран моментально станет идеально чистым, 
	# а шейдеры на картах ниже снова включатся в работу.
	tween.tween_callback(func(): material.set_shader_parameter("progress", 0.0))
	await tween.finished
	visible = false

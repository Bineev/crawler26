# scripts/room/object_room.gd
extends Room
class_name ObjectRoom

var object_type: DataManager.ObjectType
var room_object: RoomObject = null
var label: Label
@onready var vinniete_overlay: ColorRect = $VinnieteOverlay
@onready var shader_layer: ColorRect = $ShaderLayer


func _ready():
	super._ready()
	SignalManager.hide_room_object_title.connect(hide_title)


func setup(room_data: Dictionary) -> void:
	object_type = room_data.get("object_type", DataManager.ObjectType.CHEST)
	super.setup(room_data)

func _init_content(room_data: Dictionary) -> void:
	# Создаём объект комнаты
	var object_scene = preload("res://scenes/room_object.tscn")
	room_object = object_scene.instantiate() as RoomObject
	content.add_child(room_object)
	
	if object_type == DataManager.ObjectType.SHOP or object_type == DataManager.ObjectType.EVENT:
		# Магазин занимает всю комнату
		room_object.position = Vector2.ZERO
		room_object.custom_minimum_size = Vector2(DataManager.ROOM_WIDTH, DataManager.ROOM_HEIGHT)
	else:
		# 🆕 Устанавливаем позицию
		var room_center_x = DataManager.ROOM_CENTER_X
		var room_height = DataManager.ROOM_HEIGHT
		var y_offset_from_bottom = DataManager.ENEMY_Y_OFFSET_FROM_BOTTOM
		
		room_object.position = Vector2(
			room_center_x - room_object.size.x / 2,
			DataManager.ROOM_HEIGHT - y_offset_from_bottom
		)

	if object_type == DataManager.ObjectType.EVENT:
		## Получаем копию материала
		#var mat = vinniete_overlay.material.duplicate()
		## Применяем копию к узлу
		#vinniete_overlay.material = mat
#
		## Теперь можно менять параметры
		#mat.set_shader_parameter("shader_parameter/dirt_amount", 0.0)
		#mat.set_shader_parameter("shader_parameter/darkness_power", 0.0)
		vinniete_overlay.hide()
		horror_overlay.hide()

	var event_resource: EventResource
	if object_type == DataManager.ObjectType.EVENT:
		# 🆕 Получаем ресурс события для текущего биома
		event_resource = DataManager.get_event_for_biome(current_biome)
		# 🆕 Добавляем Label вверху комнаты
		_add_object_label(object_type, event_resource.get_localized_name())
	else:
		_add_object_label(object_type)
	
	
	room_object.setup(object_type, current_biome, event_resource)
	SignalManager.log_message.emit("Object room initialized")
	print("Object room initialized")
	
	
func _add_object_label(object_type: DataManager.ObjectType, title_text: String = '') -> void:
	label = Label.new()
	
	# Создаём LabelSettings с полными настройками
	var settings = LabelSettings.new()
	settings.font = DataManager.FONT_HEADERS
	settings.font_size = 48
	settings.font_color = DataManager.COLOR_MOLE_TUNNELS_ART_BG_LIGHT
	settings.outline_color = Color.BLACK
	settings.outline_size = 5
	
	label.label_settings = settings
	if object_type == DataManager.ObjectType.EVENT:
		label.hide()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if object_type != DataManager.ObjectType.EVENT:
		label.text = _get_object_label_text(object_type)
	else:
		label.text = title_text

	
	# Добавляем в content
	content.add_child(label)

	# Позиция вверху комнаты по центру
	label.position = Vector2(
		DataManager.ROOM_CENTER_X - label.size.x / 2,
		150
	)

	# Анимация появления Label
	label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(label, "modulate", Color(1, 1, 1, 1), 2)


func _get_object_label_text(object_type: DataManager.ObjectType) -> String:
	match object_type:
		DataManager.ObjectType.CHEST:
			return tr("object_chest")
		DataManager.ObjectType.SHOP:
			return tr("object_shop")
		DataManager.ObjectType.IDOL:
			return tr("object_idol")
		DataManager.ObjectType.TRAP:
			return tr("object_trap")
		DataManager.ObjectType.CAULDRON:
			return tr("object_cauldron")
		DataManager.ObjectType.TORTURE_RACK:
			return tr("object_torture_rack")
		DataManager.ObjectType.BONFIRE:
			return tr("object_bonfire")
		DataManager.ObjectType.EVENT:
			return tr("object_event")
		_:
			return tr("object_unknown")


func hide_title():
	if label:
		label.hide()

# scripts/room/combat_room.gd
extends Room
class_name CombatRoom

var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
var enemies: Array[EnemyInstance] = []
var _pending_enemies: Array[EnemyResource] = []

# Загружаем сцену врага один раз
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")


func setup(room_data: Dictionary):
	combat_type = room_data.get("combat_type", DataManager.CombatType.NORMAL)
	_pending_enemies = room_data.get("enemies", [])
	super.setup(room_data)


func _init_content(room_data: Dictionary):
	spawn_enemies(_pending_enemies)


func spawn_enemies(enemy_resources: Array[EnemyResource]):
	clear_content()
	enemies.clear()
	
	# Создаём всех врагов
	for res in enemy_resources:
		# Инстанциируем сцену врага
		var enemy_instance_node = ENEMY_SCENE.instantiate()
		var enemy_ui = enemy_instance_node as Control
		
		# Получаем компоненты
		var enemy_instance = enemy_instance_node.get_node("EnemyInstance") as EnemyInstance
		var enemy_ui_component = enemy_instance_node.get_node("EnemyUI") as EnemyUI
		
		# Настраиваем размер врага (до добавления в дерево)
		var size = DataManager.get_enemy_size_pixels(res.size)
		if enemy_ui:
			enemy_ui.size = size
		
		# Добавляем в контент
		content.add_child(enemy_instance_node)
		
		# Настраиваем врага
		if enemy_instance:
			enemy_instance.resource = res
			enemy_instance.init(1, 1)
			enemy_instance.load_intents()
		
		# Настраиваем UI
		if enemy_ui_component and enemy_instance:
			enemy_ui_component.setup(enemy_instance)
		
		# Сохраняем для последующего позиционирования
		enemies.append(enemy_instance)
	
	# Позиционируем врагов
	layout_enemies()


func layout_enemies():
	var count = enemies.size()
	if count == 0:
		return
	
	var room_center_x = DataManager.ROOM_CENTER_X
	var room_height = DataManager.ROOM_HEIGHT
	var y_offset_from_bottom = DataManager.ENEMY_Y_OFFSET_FROM_BOTTOM
	var spacing = DataManager.ENEMY_SPACING
	
	var y_base = room_height - y_offset_from_bottom
	
	# Собираем размеры всех врагов
	var enemy_sizes: Array[Vector2] = []
	for enemy in enemies:
		var size = DataManager.get_enemy_size_pixels(enemy.resource.size)
		enemy_sizes.append(size)
	
	# Вычисляем общую ширину группы
	var total_width = 0
	for size in enemy_sizes:
		total_width += size.x
	total_width += spacing * (count - 1)
	
	# Стартовая X позиция (чтобы группа была по центру)
	var start_x = room_center_x - total_width / 2
	
	# Размещаем каждого врага
	for i in range(count):
		var enemy_node = enemies[i].get_parent()
		if not enemy_node:
			continue
		
		var size = enemy_sizes[i]
		var x_pos = start_x
		var y_pos = y_base - size.y
		
		enemy_node.position = Vector2(x_pos, y_pos)
		
		start_x += size.x + spacing


func get_enemies() -> Array[EnemyInstance]:
	return enemies


func get_combat_type() -> DataManager.CombatType:
	return combat_type

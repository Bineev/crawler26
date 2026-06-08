# scripts/room/combat_room.gd
extends Room
class_name CombatRoom

var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
var enemies: Array[EnemyInstance] = []
var _pending_enemies: Array[EnemyResource] = []


func setup(room_data: Dictionary):
	combat_type = room_data.get("combat_type", DataManager.CombatType.NORMAL)
	_pending_enemies = room_data.get("enemies", [])
	super.setup(room_data)


func _init_content(room_data: Dictionary):
	spawn_enemies(_pending_enemies)


func spawn_enemies(enemy_resources: Array[EnemyResource]):
	clear_content()
	enemies.clear()
	
	for res in enemy_resources:
		var enemy_scene = preload("res://scenes/enemy.tscn").instantiate()
		content.add_child(enemy_scene)
		
		var enemy_instance = enemy_scene.get_node("EnemyInstance")
		var enemy_ui = enemy_scene.get_node("EnemyUI")
		
		enemy_instance.resource = res
		enemy_instance.init(1, 1)
		enemy_instance.load_intents()
		
		if enemy_ui and enemy_ui.has_method("setup"):
			enemy_ui.setup(enemy_instance)
		
		enemies.append(enemy_instance)
	
	layout_enemies()


func layout_enemies():
	var count = enemies.size()
	if count == 0:
		return
	
	var room_width = 1024
	var room_center = 512
	var y_pos = 400
	var spacing = 40
	
	var enemy_sizes: Array[Vector2] = []
	for enemy in enemies:
		var size_px = DataManager.get_enemy_size_pixels(enemy.resource.size)
		enemy_sizes.append(size_px)
	
	var total_width = 0
	for size in enemy_sizes:
		total_width += size.x
	total_width += spacing * (count - 1)
	
	var start_x = room_center - total_width / 2
	
	for i in range(count):
		var enemy_node = content.get_child(i)
		var x_pos = start_x + enemy_sizes[i].x / 2
		enemy_node.position = Vector2(x_pos, y_pos)
		start_x += enemy_sizes[i].x + spacing


func get_enemies() -> Array[EnemyInstance]:
	return enemies


func get_combat_type() -> DataManager.CombatType:
	return combat_type

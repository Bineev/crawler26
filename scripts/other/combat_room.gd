# scripts/room/combat_room.gd
extends Room
class_name CombatRoom

var hand_ui : HandUI = null
var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
var enemies: Array[EnemyInstance] = []
var _pending_enemies: Array[EnemyResource] = []
var current_floor: int = 1
var current_biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS
# Загружаем сцену врага один раз
const ENEMY_SCENE: PackedScene = preload("res://scenes/enemy.tscn")


func _ready():
	super._ready()
	#SignalManager.battle_victory.connect(on_battle_victory)


func setup(room_data: Dictionary):
	combat_type = room_data.get("combat_type", DataManager.CombatType.NORMAL)
	_pending_enemies = room_data.get("enemies", [])
	current_floor = room_data.get("floor_level", 1)
	current_biome = room_data.get("biome", DataManager.Biome.MOLE_TUNNELS)
	hand_ui = room_data.get("hand_ui", null)
	super.setup(room_data)


func _init_content(room_data: Dictionary):
	GameTestManager._create_energy_display()
	spawn_enemies(_pending_enemies)
	# После того как враги созданы, начинаем бой
	call_deferred("_start_battle")

func spawn_enemies(enemy_resources: Array[EnemyResource]):
	clear_content()
	enemies.clear()
	
	for res in enemy_resources:
		# Инстанциируем сцену врага (корневая нода теперь EnemyInstance)
		var enemy_instance = ENEMY_SCENE.instantiate() as EnemyInstance
		
		# Получаем EnemyUI (дочерняя нода)
		var enemy_ui = enemy_instance.get_node("EnemyUI") as EnemyUI
		
		# Настраиваем размер врага
		var size = DataManager.get_enemy_size_pixels(res.size)
		if enemy_ui:
			enemy_ui.size = size
		
		# Добавляем в контент
		content.add_child(enemy_instance)
		
		# Настраиваем врага
		enemy_instance.resource = res
		enemy_instance.init(current_floor)  # нужно передать floor_level и biome
		enemy_instance.load_intents()
		
		# Настраиваем UI
		if enemy_ui:
			enemy_ui.setup(enemy_instance)
		
		# Сохраняем для позиционирования
		enemies.append(enemy_instance)
		if enemy_ui:
			enemy_ui.play_appear_animation()
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
		var enemy = enemies[i]  # ← сам враг (EnemyInstance)
		
		var size = enemy_sizes[i]
		var x_pos = start_x
		var y_pos = y_base - size.y
		
		enemy.position = Vector2(x_pos, y_pos)  # ← позиционируем врага напрямую
		
		start_x += size.x + spacing


func get_enemies() -> Array[EnemyInstance]:
	return enemies


func get_combat_type() -> DataManager.CombatType:
	return combat_type


func _start_battle():
	# Создаём HandUI
	if not hand_ui:
		hand_ui = _create_hand_ui()
		# Отправляем наверх для добавления в game_world
		SignalManager.hand_ui_created.emit(hand_ui)
	
	var player = BattleManager.get_player()
	if not player:
		player = PenitentStats.new()
		BattleManager.set_player(player)
	
	var deck_data = RunManager.get_player_deck()
	var battle_deck = deck_data.create_battle_copy()
	battle_deck.hand_ui = hand_ui
	
	BattleManager.start_battle(player, enemies, battle_deck, hand_ui, current_floor, current_biome, self)


func _create_hand_ui() -> HandUI:
	var hand_ui_scene = preload("res://scenes/hand_ui.tscn")
	var hand_ui_instance = hand_ui_scene.instantiate() as HandUI
	# НЕ добавляем в дерево здесь!
	return hand_ui_instance


func on_battle_victory():
	var hand_ui = BattleManager.get_hand_ui()
	if hand_ui:
		hand_ui.fly_hand_away()
		await hand_ui.wait_for_fly_away()
	
	await get_tree().create_timer(0.2).timeout

	# Анимация закрытия комнаты
	await _close_room_animation()

	GameTestManager.clear_ui()
	FloorManager.process_next()
	queue_free()


func _on_battle_defeat():
	# Карты улетают
	var hand_ui = BattleManager.get_hand_ui()
	if hand_ui:
		hand_ui.fly_hand_away()
	
	await get_tree().create_timer(0.6).timeout
	
	# Удаляем комнату
	queue_free()
	
	# Очищаем UI
	GameTestManager.clear_ui()
	
	SignalManager.battle_defeat.emit()

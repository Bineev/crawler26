# scripts/room/combat_room.gd
extends Room
class_name CombatRoom

var hand_ui : HandUI = null
var combat_type: DataManager.CombatType = DataManager.CombatType.NORMAL
var enemies: Array[EnemyInstance] = []
var _pending_enemies: Array[EnemyResource] = []
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
		var enemy_instance = ENEMY_SCENE.instantiate() as EnemyInstance
		var enemy_ui = enemy_instance.get_node("EnemyUI") as EnemyUI
		
		var size = DataManager.get_enemy_size_pixels(res.size)
		if enemy_ui:
			enemy_ui.size = size
		
		content.add_child(enemy_instance)
		
		enemy_instance.resource = res
		enemy_instance.init(current_floor)
		enemy_instance.load_intents()
		
		if enemy_ui:
			enemy_ui.setup(enemy_instance)
		
		# 🆕 Делаем врага невидимым
		enemy_instance.modulate = Color(1, 1, 1, 0)
		
		enemies.append(enemy_instance)
	
	# 🆕 Выбираем первое намерение для каждого врага
	for enemy in enemies:
		if enemy.is_alive():
			var intent = enemy.select_next_intent()
			if intent:
				SignalManager.enemy_intent_changed.emit(enemy, intent)
	
	await get_tree().process_frame

	layout_enemies()
	# 🆕 Ждём один кадр, чтобы позиции обновились
	await get_tree().process_frame
	# 🆕 После позиционирования — показываем врагов
	for enemy in enemies:
		enemy.modulate = Color(1, 1, 1, 1)
		pass


func layout_enemies():
	var count = enemies.size()
	if count == 0:
		return
	
	var room_center_x = DataManager.ROOM_CENTER_X
	var room_height = DataManager.ROOM_HEIGHT
	var y_offset_from_bottom = DataManager.ENEMY_Y_OFFSET_FROM_BOTTOM
	var spacing = DataManager.ENEMY_SPACING
	var base_scale = 0.85
	
	var y_base = room_height - y_offset_from_bottom
	
	var enemy_sizes: Array[Vector2] = []
	for enemy in enemies:
		var base_size = DataManager.get_enemy_size_pixels(enemy.resource.size)
		enemy_sizes.append(base_size * base_scale)
	
	var total_width = 0
	for size in enemy_sizes:
		total_width += size.x
	total_width += spacing * (count - 1)
	
	var start_x = room_center_x - total_width / 2
	
	for i in range(count):
		var enemy = enemies[i]
		var enemy_ui = enemy.get_node("EnemyUI") as EnemyUI
		
		var size = enemy_sizes[i]
		var x_pos = start_x
		var y_pos = y_base - size.y
		
		enemy.position = Vector2(x_pos, y_pos)
		
		if enemy_ui:
			enemy_ui.scale = Vector2(base_scale, base_scale)
			enemy_ui.original_scale = enemy_ui.scale
		
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

	# 🆕 Показываем панель наград
	show_rewards()


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

#TODO uncomment after test
#func show_rewards() -> void:
	#var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	#var reward_types: Array[DataManager.RewardType] = []
	#
	#match combat_type:
		#DataManager.CombatType.NORMAL:
			#reward_types = [DataManager.RewardType.CARD_BIOM, DataManager.RewardType.GOLD]
			#reward_panel.gold_mod = 1
		#
		#DataManager.CombatType.ELITE:
			#reward_types = [DataManager.RewardType.ARTIFACT, DataManager.RewardType.GOLD]
			#reward_panel.gold_mod = 2
		#
		#DataManager.CombatType.BOSS:
			#reward_types = [DataManager.RewardType.ARTIFACT_ELITE, DataManager.RewardType.CARD_CHARACTER, DataManager.RewardType.GOLD]
			#reward_panel.gold_mod = 3
	#
	#reward_panel.reward_types = reward_types
	#SignalManager.show_reward.emit(reward_panel)


func show_rewards() -> void:
	var reward_panel = preload("res://scenes/reward_panel.tscn").instantiate() as RewardPanel
	var reward_types: Array[DataManager.RewardType] = []
	
	match combat_type:
		DataManager.CombatType.NORMAL:
			reward_types = [DataManager.RewardType.CARD_BIOM, DataManager.RewardType.GOLD]
			reward_panel.gold_mod = 2

		DataManager.CombatType.ELITE:
			reward_types = [DataManager.RewardType.ARTIFACT, DataManager.RewardType.GOLD]
			reward_panel.gold_mod = 1

		DataManager.CombatType.CONCRETE_COMBAT:
			reward_types = [DataManager.RewardType.GOLD]
			reward_panel.gold_mod = 3
			
		DataManager.CombatType.ELITE_AFTER_ROB:
			reward_types = [DataManager.RewardType.CARD_WITHOUT_CHOICE, DataManager.RewardType.GOLD, DataManager.RewardType.POTION]
			reward_panel.gold_mod = 5
		
		DataManager.CombatType.BOSS:
			reward_types = [DataManager.RewardType.ARTIFACT_COMBO, DataManager.RewardType.CARD_CHARACTER, DataManager.RewardType.GOLD]
			reward_panel.gold_mod = 3
	
	reward_panel.reward_types = reward_types
	SignalManager.show_reward.emit(reward_panel)

# autoload/room_manager.gd
extends Node

## ============================================================
## ЗАГРУЖЕННЫЕ СЦЕНЫ
## ============================================================

var room_scene: PackedScene = preload("res://scenes/room.tscn")
var combat_room_scene: PackedScene = preload("res://scenes/combat_room.tscn")


## ============================================================
## ПУБЛИЧНЫЕ МЕТОДЫ
## ============================================================

func create_room(room_node: RoomNode, floor_level: int, biome: DataManager.Biome, room_index: int = 0, hand_ui: HandUI = null) -> Room:
	match room_node.room_type:
		DataManager.RoomType.COMBAT:
			return _create_combat_room(room_node, floor_level, biome, room_index, hand_ui)
		DataManager.RoomType.EVENT:
			return _create_event_room(room_node, biome)
		DataManager.RoomType.OBJECT:
			return _create_object_room(room_node, biome)
	
	return null


## ============================================================
## ПРИВАТНЫЕ МЕТОДЫ
## ============================================================

func _create_combat_room(room_node: RoomNode, floor_level: int, biome: DataManager.Biome, room_index: int, hand_ui: HandUI) -> Room:
	# Подбираем врагов
	var enemies = EnemySelector.select_enemies(
		room_node.combat_type,
		biome,
		floor_level,
		room_index
	)
	
	print("  Creating combat room with ", enemies.size(), " enemies")
	for enemy in enemies:
		print("    - ", DataManager.get_enemy_resource_name(enemy.enemy_id))
	
	var background_texture = DataManager.get_random_background(biome)
	var room_instance = combat_room_scene.instantiate()
	
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.COMBAT,
			"combat_type": room_node.combat_type,
			"biome": biome,
			"floor_level": floor_level,
			"enemies": enemies,
			"background": background_texture,
			"hand_ui": hand_ui,  # ← передаём HandUI
		})
	
	return room_instance


func _create_event_room(room_node: RoomNode, biome: DataManager.Biome) -> Room:
	print("  Creating event room")
	
	var background_texture = DataManager.get_random_background(biome)
	
	var room_instance = room_scene.instantiate()
	
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.EVENT,
			"biome": biome,
			"background": background_texture,  # ← передаём фон
		})
	
	return room_instance


func _create_object_room(room_node: RoomNode, biome: DataManager.Biome) -> Room:
	print("  Creating object room")
	
	var background_texture = DataManager.get_random_background(biome)
	
	var room_instance = room_scene.instantiate()
	
	if room_instance.has_method("setup"):
		room_instance.setup({
			"type": DataManager.RoomType.OBJECT,
			"biome": biome,
			"background": background_texture,  # ← передаём фон
		})
	
	return room_instance

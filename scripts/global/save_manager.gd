# autoload/save_manager.gd
extends Node

const SAVE_PATH: String = "user://savegame.save"
const SAVE_VERSION: int = 1

var current_save_data: Dictionary = {}


func save_game() -> void:
	var save_data = _collect_save_data()
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Game saved successfully")
	else:
		printerr("Failed to save game")


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		printerr("Failed to parse save file")
		return false
	
	current_save_data = json.data
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"is_run_ended": false,  # 🆕 false — игрок жив, true — игрок умер
		"progress": _collect_progress_data(),
		"run": _collect_run_data(),
		"player": _collect_player_data(),
		"game_state": _collect_game_state_data(),
	}


func save_game_with_run_ended() -> void:
	# 🆕 Сбрасываем доступные биомы перед сохранением
	ProgressManager.reset_available_biomes()
	var save_data = _collect_save_data()
	save_data["is_run_ended"] = true
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Game saved with run_ended flag")

func _collect_progress_data() -> Dictionary:
	# 🆕 Пересчитываем уровень перед сохранением (если он не обновлялся)
	var char_levels = {}
	for class_type in ProgressManager.character_experience.keys():
		char_levels[class_type] = ProgressManager.calculate_character_level(class_type)
	
	var biome_levels = {}
	for biome in ProgressManager.biome_experience.keys():
		biome_levels[biome] = ProgressManager.calculate_biome_level(biome)

	return {
		"unlocked_classes": ProgressManager.unlocked_classes.duplicate(),
		"unlocked_card_ids": ProgressManager.unlocked_card_ids.duplicate(),
		"unlocked_artifact_ids": ProgressManager.unlocked_artifact_ids.duplicate(),
		"meta_currency": ProgressManager.meta_currency,
		"available_biomes": ProgressManager.available_biomes.duplicate(),
		"total_runs": ProgressManager.total_runs,
		"total_victories": ProgressManager.total_victories,
		"total_defeats": ProgressManager.total_defeats,
		# ============================================================
		# ОПЫТ И УРОВНИ (основной прогресс)
		# ============================================================
		"character_experience": ProgressManager.character_experience.duplicate(),
		"character_level": char_levels,  # пересчитанные уровни
		"biome_experience": ProgressManager.biome_experience.duplicate(),
		"biome_level": biome_levels,  # пересчитанные уровни
		
		# ============================================================
		# СНИМКИ НА НАЧАЛО ЗАБЕГА (для расчёта прогресса за забег)
		# ============================================================
		"run_start_character_experience": ProgressManager.run_start_character_experience.duplicate(),
		"run_start_character_level": ProgressManager.run_start_character_level.duplicate(),
		"run_start_biome_experience": ProgressManager.run_start_biome_experience.duplicate(),
		"run_start_biome_level": ProgressManager.run_start_biome_level.duplicate(),
	}


func _collect_run_data() -> Dictionary:
	var deck = RunManager.get_player_deck()
	
	# 🆕 Сохраняем полные данные карт (с улучшениями и трансформациями)
	var deck_cards = _collect_deck_cards(deck)
	
	# Сохраняем артефакты
	var artifacts_data: Array = []
	for artifact in RunManager.artifacts:
		artifacts_data.append({
			"id": artifact.id,
		})
	
	# Сохраняем зелья
	var potions_data: Array = []
	for potion in RunManager.potions:
		potions_data.append({
			"type": potion.potion_type,
		})
	
	return {
		# === Состояние забега ===
		"current_character": RunManager.current_character,
		"current_biome": RunManager.current_biome,
		
		# === Колода ===
		"deck_cards": deck_cards,
		
		# === Артефакты и счётчики ===
		"artifacts": artifacts_data,
		"artifact_counters": RunManager.artifact_counters.duplicate(),
		
		# === Зелья ===
		"potions": potions_data,
		
		# === Валюты ===
		"coins": RunManager.coins,
		"bones": RunManager.bones,
		"keys": RunManager.keys,
		
		# === Статусные константы (враги) ===
		"poison_damage_per_stack": RunManager.poison_damage_per_stack,
		"bleed_damage_per_stack": RunManager.bleed_damage_per_stack,
		"burn_damage_per_stack": RunManager.burn_damage_per_stack,
		"burn_threshold_stacks": RunManager.burn_threshold_stacks,
		"cold_freeze_threshold": RunManager.cold_freeze_threshold,
		"cold_effect_percent": RunManager.cold_effect_percent,
		"cold_min_multiplier": RunManager.cold_min_multiplier,
		"regen_heal_per_stack": RunManager.regen_heal_per_stack,
		"strength_bonus_per_stack": RunManager.strength_bonus_per_stack,
		"weakness_damage_multiplier": RunManager.weakness_damage_multiplier,
		"vulnerability_damage_multiplier": RunManager.vulnerability_damage_multiplier,
		"poison_healing_reduction": RunManager.poison_healing_reduction,
		"shame_damage_taken_multiplier": RunManager.shame_damage_taken_multiplier,
		"shame_atonement_multiplier": RunManager.shame_atonement_multiplier,
		"frozen_energy_loss": RunManager.frozen_energy_loss,
		"infection_bleed_multiplier": RunManager.infection_bleed_multiplier,
		"infection_multiplier": RunManager.infection_multiplier,  # 🆕
		
		# === Статусные константы (игрок) ===
		"player_poison_damage_per_stack": RunManager.player_poison_damage_per_stack,
		"player_bleed_damage_per_stack": RunManager.player_bleed_damage_per_stack,
		"player_burn_damage_per_stack": RunManager.player_burn_damage_per_stack,
		"player_regen_heal_per_stack": RunManager.player_regen_heal_per_stack,
		"player_bleed_duration_bonus": RunManager.player_bleed_duration_bonus,
		
		# === Балансные константы ===
		"starting_hand_size": RunManager.starting_hand_size,
		"cards_to_draw_per_turn": RunManager.cards_to_draw_per_turn,
		"max_energy": RunManager.max_energy,
		"hand_size_increment_per_biome": RunManager.hand_size_increment_per_biome,  # 🆕
		
		# === Ресурсы ===
		"default_item_cost": RunManager.default_item_cost,
		"reward_gold_default": RunManager.reward_gold_default,
		"reward_damage_default": RunManager.reward_damage_default,
		"rest_default_heal": RunManager.rest_default_heal,
		
		# === Флаги ===
		"has_lucky_pick": RunManager.has_lucky_pick,
		"is_robber": RunManager.is_robber,
		
		# === Временные баффы ===
		"temp_buffs": RunManager.temp_buffs.duplicate(),
		"deck_size_buff_remaining": RunManager.deck_size_buff_remaining,
		"deck_size_bonus": RunManager.deck_size_bonus,
		
		# === Проклятие идола ===
		"idol_curse_biome": RunManager.idol_curse_biome,
		"idol_curse_remaining": RunManager.idol_curse_remaining,
		
		# === Взаимодействия статусов ===
		"is_bleed_poison_interaction_enabled": RunManager.is_bleed_poison_interaction_enabled,
		"is_poison_burn_interaction_enabled": RunManager.is_poison_burn_interaction_enabled,
		"is_bleed_cold_interaction_enabled": RunManager.is_bleed_cold_interaction_enabled,
		
		# === Отложенные статусы ===
		"pending_statuses": RunManager.pending_statuses.duplicate(),
	}


func _collect_player_data() -> Dictionary:
	var player = BattleManager.get_player()
	if not player:
		return {}
	
	return {
		"character_class": RunManager.current_character,  # 🆕
		"health": player.get_health(),
		"max_health": player.get_max_health(),
		"energy": player.get_energy(),
		"max_energy": player.get_max_energy(),
		"atonement": player.get_flat(DataManager.FlatStat.ATONEMENT),
		"max_atonement": player.get_flat(DataManager.FlatStat.MAX_ATONEMENT),
		"hand_size": player.get_flat(DataManager.FlatStat.HAND_SIZE),
		"draw_per_turn": player.get_flat(DataManager.FlatStat.DRAW_PER_TURN),
		
		# 🆕 Модификаторы (сохраняем)
		"modifiers": player.modifiers.duplicate(),
		
		# 🆕 Пассивки и статусы НЕ сохраняем
		# Они сбрасываются при загрузке комнаты
	}


func _collect_game_state_data() -> Dictionary:
	return {
		"current_room_node": _collect_room_data(),
		"floor_manager": _collect_floor_manager_data(),
		"turn_counter": BattleManager.turn_counter,
		"battle_state": BattleManager.current_state,
	}


func _collect_room_data() -> Dictionary:
	# TODO: сохранить данные текущей комнаты (враги, их здоровье, статусы и т.д.)
	return {}


func _collect_floor_manager_data() -> Dictionary:
	var rooms_data: Array = []
	for room in FloorManager.all_rooms:
		rooms_data.append({
			"room_type": room.room_type,
			"combat_type": room.combat_type,
			"object_type": room.object_type,
			"is_revealed": room.is_revealed,
			"is_visited": room.is_visited,
		})
	
	var paths_data: Array = []
	for segment in FloorManager.all_paths:
		var segment_data: Array = []
		for path in segment:
			var path_data: Array = []
			for room in path:
				path_data.append({
					"room_type": room.room_type,
					"combat_type": room.combat_type,
					"object_type": room.object_type,
					"is_revealed": room.is_revealed,
					"is_visited": room.is_visited,
				})
			segment_data.append(path_data)
		paths_data.append(segment_data)
	
	return {
		"current_path_index": FloorManager.current_path_index,
		"current_path_progress": FloorManager.current_path_progress,
		"current_segment_index": FloorManager.current_segment_index,
		"current_room_index": GameTestManager.current_room_index,  # 🆕
		"boss_generated": FloorManager.boss_generated,
		"current_floor": FloorManager.current_floor,
		"current_biome": FloorManager.current_biome,
		"all_rooms": rooms_data,
		"all_paths": paths_data,
	}

func _collect_deck_cards(deck) -> Array:
	if not deck:
		return []
	
	var card_data: Array = []
	for card in deck.master_cards:
		# Сохраняем полную копию карты (с улучшениями и трансформациями)
		var card_copy = {
			"id": card.id,
			"cost": card.cost,
			"upgrade_type": card.upgrade_type,
			"is_can_upgrade": card.is_can_upgrade,
			"is_burned": card.is_burned,
			# Сохраняем эффекты (они могут быть изменены трансформацией)
			"effects": _collect_effects(card.effects),
		}
		card_data.append(card_copy)
	
	return card_data


func _collect_effects(effects: Array) -> Array:
	var effect_data: Array = []
	for effect in effects:
		var effect_copy = {
			"category": effect.category,
			"target": effect.target,
			"base_value": effect.base_value,
			"value": effect.value,
			"duration": effect.duration,
			"amount": effect.amount,
			"delta": effect.delta,
			# 🆕 Добавляем поддержку кастомных эффектов
			"is_direct_damage": effect.is_direct_damage,
			"stat_multiplier": effect.stat_multiplier,
			"stat_divisor": effect.stat_divisor,
			"scaled_values": effect.scaled_values.duplicate(),
			"scaled_thresholds": effect.scaled_thresholds.duplicate(),
			"scaled_type": effect.scaled_type,
			"scaled_resource": effect.scaled_resource,
			"scaled_compare": effect.scaled_compare,
			"scaled_spend_resource": effect.scaled_spend_resource,
			"from_stat": effect.from_stat,
			"to_stat": effect.to_stat,
			"conversion_ratio": effect.conversion_ratio,
			"convert_from_status": effect.convert_from_status,
			"convert_to_stat": effect.convert_to_stat,
			"convert_conversion_ratio": effect.convert_conversion_ratio,
			"target_stat": effect.target_stat,
			"target_modifier": effect.target_modifier,
			"delta_percent": effect.delta_percent,
			"modifier_duration": effect.modifier_duration,
			"grow_type": effect.grow_type,
			"grow_value": effect.grow_value,
			"grow_target": effect.grow_target,
			"passive_duration": effect.passive_duration,
		}
		
		# 🆕 СОХРАНЯЕМ КАСТОМНЫЙ СКРИПТ
		if effect.custom_script:
			effect_copy["custom_script_path"] = effect.custom_script.resource_path
		
		# 🆕 СОХРАНЯЕМ КАСТОМНОЕ ОПИСАНИЕ
		if not effect.custom_description.is_empty():
			effect_copy["custom_description"] = effect.custom_description
		
		# 🆕 СОХРАНЯЕМ СКРИПТ УСЛОВИЯ (для CONDITIONAL эффектов)
		if effect.condition_script:
			effect_copy["condition_script_path"] = effect.condition_script.resource_path
		
		# Если есть статус
		if effect.status:
			effect_copy["status_id"] = effect.status.id
		
		# Если есть пассивка
		if effect.passive:
			effect_copy["passive_id"] = effect.passive.id
		
		# Если условный эффект
		if effect.category == DataManager.EffectCategory.CONDITIONAL:
			if effect.true_effect:
				effect_copy["true_effect"] = _collect_effects([effect.true_effect])[0]
			if effect.false_effect:
				effect_copy["false_effect"] = _collect_effects([effect.false_effect])[0]
		
		effect_data.append(effect_copy)
	
	return effect_data


func _collect_artifacts() -> Array:
	var result: Array = []
	for artifact in RunManager.artifacts:
		result.append({
			"id": artifact.id,
		})
	return result


func _collect_potions() -> Array:
	var result: Array = []
	for potion in RunManager.potions:
		result.append({
			"type": potion.potion_type,
		})
	return result


func _collect_statuses(player) -> Array:
	var result: Array = []
	for status_id in player.active_statuses.keys():
		var data = player.active_statuses[status_id]
		result.append({
			"id": status_id,
			"stacks": data.stacks,
			"duration": data.duration,
		})
	return result


func _collect_passives(player) -> Array:
	var result: Array = []
	for passive in player.active_passives:
		result.append({
			"id": passive.id,
			"current_charges": passive.current_charges,
			"starting_charges": passive.starting_charges,
		})
	return result


func load_and_apply_save() -> bool:
	if not load_game():
		return false
	
	var data = current_save_data
	var is_run_ended = data.get("is_run_ended", false)
	
	restore_progress(data.get("progress", {}))
	
	if is_run_ended:
		SignalManager.start_game_requested.emit()
		return true
	
	var run_data = data.get("run", {})
	
	# 🆕 Вручную восстанавливаем биом (без удаления из available_biomes)
	var biome = run_data.get("current_biome", DataManager.Biome.MOLE_TUNNELS)
	GameTestManager.current_biome = biome
	RunManager.current_biome = biome
	FloorManager.current_biome = biome
	DataManager.load_biome_enemies(biome)
	
	GameTestManager.current_floor = run_data.get("current_floor", 1)
	GameTestManager.current_room_index = run_data.get("current_room_index", 0)
	
	restore_run_manager(run_data)
	restore_player(data.get("player", {}))
	restore_game_state(data.get("game_state", {}))
	
	SignalManager.loaded_save_with_run.emit()
	
	return true


func restore_progress(progress_data: Dictionary) -> void:
	# ============================================================
	# МЕТА-ПРОГРЕСС (открытый контент)
	# ============================================================
	ProgressManager.unlocked_classes.clear()
	for class_id in progress_data.get("unlocked_classes", []):
		ProgressManager.unlocked_classes.append(int(class_id))
	
	ProgressManager.unlocked_card_ids.clear()
	for card_id in progress_data.get("unlocked_card_ids", []):
		ProgressManager.unlocked_card_ids.append(int(card_id))
	
	ProgressManager.unlocked_artifact_ids.clear()
	for artifact_id in progress_data.get("unlocked_artifact_ids", []):
		ProgressManager.unlocked_artifact_ids.append(int(artifact_id))
	
	ProgressManager.meta_currency = int(progress_data.get("meta_currency", 0))
	
	ProgressManager.available_biomes.clear()
	for biome in progress_data.get("available_biomes", []):
		ProgressManager.available_biomes.append(int(biome))
	
	# ============================================================
	# СТАТИСТИКА
	# ============================================================
	ProgressManager.total_runs = int(progress_data.get("total_runs", 0))
	ProgressManager.total_victories = int(progress_data.get("total_victories", 0))
	ProgressManager.total_defeats = int(progress_data.get("total_defeats", 0))
	
	# ============================================================
	# ОПЫТ И УРОВНИ (основной прогресс)
	# ============================================================
	ProgressManager.character_experience.clear()
	var char_exp = progress_data.get("character_experience", {})
	for key in char_exp.keys():
		ProgressManager.character_experience[int(key)] = int(char_exp[key])
	
	ProgressManager.character_level.clear()
	var char_lvl = progress_data.get("character_level", {})
	for key in char_lvl.keys():
		ProgressManager.character_level[int(key)] = int(char_lvl[key])
	
	ProgressManager.biome_experience.clear()
	var biome_exp = progress_data.get("biome_experience", {})
	for key in biome_exp.keys():
		ProgressManager.biome_experience[int(key)] = int(biome_exp[key])
	
	ProgressManager.biome_level.clear()
	var biome_lvl = progress_data.get("biome_level", {})
	for key in biome_lvl.keys():
		ProgressManager.biome_level[int(key)] = int(biome_lvl[key])
	
	# ============================================================
	# СНИМКИ НА НАЧАЛО ЗАБЕГА (для расчёта прогресса за забег)
	# ============================================================
	ProgressManager.run_start_character_experience.clear()
	var run_char_exp = progress_data.get("run_start_character_experience", {})
	for key in run_char_exp.keys():
		ProgressManager.run_start_character_experience[int(key)] = int(run_char_exp[key])
	
	ProgressManager.run_start_character_level.clear()
	var run_char_lvl = progress_data.get("run_start_character_level", {})
	for key in run_char_lvl.keys():
		ProgressManager.run_start_character_level[int(key)] = int(run_char_lvl[key])
	
	ProgressManager.run_start_biome_experience.clear()
	var run_biome_exp = progress_data.get("run_start_biome_experience", {})
	for key in run_biome_exp.keys():
		ProgressManager.run_start_biome_experience[int(key)] = int(run_biome_exp[key])
	
	ProgressManager.run_start_biome_level.clear()
	var run_biome_lvl = progress_data.get("run_start_biome_level", {})
	for key in run_biome_lvl.keys():
		ProgressManager.run_start_biome_level[int(key)] = int(run_biome_lvl[key])
		

func restore_run_manager(run_data: Dictionary) -> void:
	# === Состояние забега ===
	RunManager.current_character = run_data.get("current_character", DataManager.CharacterClass.PENITENT)
	RunManager.current_biome = run_data.get("current_biome", DataManager.Biome.MOLE_TUNNELS)
	
	# === Валюты ===
	RunManager.coins = run_data.get("coins", 0)
	RunManager.bones = run_data.get("bones", 0)
	RunManager.keys = run_data.get("keys", 0)
	
	# === Статусные константы (враги) ===
	RunManager.poison_damage_per_stack = run_data.get("poison_damage_per_stack", DataManager.POISON_BASE_DAMAGE_PER_STACK)
	RunManager.bleed_damage_per_stack = run_data.get("bleed_damage_per_stack", DataManager.BLEED_BASE_DAMAGE_PER_STACK)
	RunManager.burn_damage_per_stack = run_data.get("burn_damage_per_stack", DataManager.BURN_BASE_DAMAGE_PER_STACK)
	RunManager.burn_threshold_stacks = run_data.get("burn_threshold_stacks", DataManager.BURN_THRESHOLD_STACKS)
	RunManager.cold_freeze_threshold = run_data.get("cold_freeze_threshold", DataManager.COLD_FREEZE_THRESHOLD)
	RunManager.cold_effect_percent = run_data.get("cold_effect_percent", DataManager.COLD_EFFECT_PERCENT_PER_STACK)
	RunManager.cold_min_multiplier = run_data.get("cold_min_multiplier", DataManager.COLD_MIN_EFFECT_MULTIPLIER)
	RunManager.regen_heal_per_stack = run_data.get("regen_heal_per_stack", DataManager.REGEN_HEAL_PER_STACK)
	RunManager.strength_bonus_per_stack = run_data.get("strength_bonus_per_stack", DataManager.STRENGTH_FLAT_BONUS_PER_STACK)
	RunManager.weakness_damage_multiplier = run_data.get("weakness_damage_multiplier", DataManager.WEAKNESS_DAMAGE_MULTIPLIER)
	RunManager.vulnerability_damage_multiplier = run_data.get("vulnerability_damage_multiplier", DataManager.VULNERABILITY_DAMAGE_MULTIPLIER)
	RunManager.poison_healing_reduction = run_data.get("poison_healing_reduction", DataManager.POISON_HEALING_REDUCTION)
	RunManager.shame_damage_taken_multiplier = run_data.get("shame_damage_taken_multiplier", DataManager.SHAME_DAMAGE_TAKEN_MULTIPLIER)
	RunManager.shame_atonement_multiplier = run_data.get("shame_atonement_multiplier", DataManager.SHAME_ATONEMENT_MULTIPLIER)
	RunManager.frozen_energy_loss = run_data.get("frozen_energy_loss", DataManager.FROZEN_ENERGY_LOSS)
	RunManager.infection_bleed_multiplier = run_data.get("infection_bleed_multiplier", DataManager.INFECTION_BLEED_MULTIPLIER)
	RunManager.infection_multiplier = run_data.get("infection_multiplier", DataManager.INFECTION_MULTIPLIER)  # 🆕
	
	# === Статусные константы (игрок) ===
	RunManager.player_poison_damage_per_stack = run_data.get("player_poison_damage_per_stack", DataManager.POISON_BASE_DAMAGE_PER_STACK)
	RunManager.player_bleed_damage_per_stack = run_data.get("player_bleed_damage_per_stack", DataManager.BLEED_BASE_DAMAGE_PER_STACK)
	RunManager.player_burn_damage_per_stack = run_data.get("player_burn_damage_per_stack", DataManager.BURN_BASE_DAMAGE_PER_STACK)
	RunManager.player_regen_heal_per_stack = run_data.get("player_regen_heal_per_stack", DataManager.REGEN_HEAL_PER_STACK)
	RunManager.player_bleed_duration_bonus = run_data.get("player_bleed_duration_bonus", 0)
	
	# === Балансные константы ===
	RunManager.starting_hand_size = run_data.get("starting_hand_size", DataManager.STARTING_HAND_SIZE)
	RunManager.cards_to_draw_per_turn = run_data.get("cards_to_draw_per_turn", DataManager.CARDS_TO_DRAW_PER_TURN)
	RunManager.max_energy = run_data.get("max_energy", DataManager.MAX_ENERGY)
	RunManager.hand_size_increment_per_biome = run_data.get("hand_size_increment_per_biome", DataManager.HAND_SIZE_INCREMENT_PER_BIOME)  # 🆕

	# === Ресурсы ===
	RunManager.default_item_cost = run_data.get("default_item_cost", DataManager.DEFAULT_ITEM_COST)
	RunManager.reward_gold_default = run_data.get("reward_gold_default", DataManager.REWARD_GOLD_DEFAULT)
	RunManager.reward_damage_default = run_data.get("reward_damage_default", DataManager.REWARD_DAMAGE_DEFAULT)
	RunManager.rest_default_heal = run_data.get("rest_default_heal", DataManager.REST_DEFAULT_HEAL)
	
	# === Флаги ===
	RunManager.has_lucky_pick = run_data.get("has_lucky_pick", false)
	RunManager.is_robber = run_data.get("is_robber", false)
	
	# === Временные баффы ===
	RunManager.temp_buffs = run_data.get("temp_buffs", {
		"max_energy_buff": 0,
		"bonus_energy": 0
	})
	
	RunManager.deck_size_buff_remaining = run_data.get("deck_size_buff_remaining", 0)
	RunManager.deck_size_bonus = run_data.get("deck_size_bonus", 0)
	
	# === Проклятие идола ===
	RunManager.idol_curse_biome = run_data.get("idol_curse_biome", DataManager.Biome.MOLE_TUNNELS)
	RunManager.idol_curse_remaining = run_data.get("idol_curse_remaining", 0)
	
	# === Взаимодействия статусов ===
	RunManager.is_bleed_poison_interaction_enabled = run_data.get("is_bleed_poison_interaction_enabled", true)
	RunManager.is_poison_burn_interaction_enabled = run_data.get("is_poison_burn_interaction_enabled", false)
	RunManager.is_bleed_cold_interaction_enabled = run_data.get("is_bleed_cold_interaction_enabled", false)
	
	# === Отложенные статусы ===
	RunManager.pending_statuses.clear()
	var pending = run_data.get("pending_statuses", [])
	for status_data in pending:
		# 🆕 Приводим значения к int (только где нужно)
		var clean_data = {}
		for key in status_data.keys():
			var value = status_data[key]
			if typeof(value) == TYPE_FLOAT and key in ["status_id", "stacks", "duration"]:
				clean_data[key] = int(value)
			else:
				clean_data[key] = value
		RunManager.pending_statuses.append(clean_data)
	
	# === Артефакты ===
	_restore_artifacts(run_data.get("artifacts", []))
	
	# === Счётчики артефактов ===
	RunManager.artifact_counters.clear()
	var counters = run_data.get("artifact_counters", {})
	for key in counters.keys():
		# 🆕 Приводим ключ и значение к int
		RunManager.artifact_counters[int(key)] = int(counters[key])
	
	# === Зелья ===
	_restore_potions(run_data.get("potions", []))
	
	# === Колода ===
	var deck_cards = run_data.get("deck_cards", [])
	_restore_deck(deck_cards)
	
	
func restore_player(player_data: Dictionary) -> void:
	# 🆕 Если игрока нет — создаём через GameTestManager
	if not BattleManager.get_player():
		var character_class = int(player_data.get("character_class", DataManager.CharacterClass.PENITENT))
		GameTestManager.create_character(character_class)
		print("Player created during save restore")
	
	var player = BattleManager.get_player()
	if not player:
		return
	
	# Очищаем статусы и пассивки
	player.clear_all_statuses()
	
	# 🆕 Восстанавливаем статы — приводим к int()
	player.set_flat(DataManager.FlatStat.HEALTH, int(player_data.get("health", DataManager.PENITENT_STARTING_HEALTH)))
	player.set_flat(DataManager.FlatStat.MAX_HEALTH, int(player_data.get("max_health", DataManager.PENITENT_STARTING_HEALTH)))
	player.set_flat(DataManager.FlatStat.ENERGY, int(player_data.get("energy", RunManager.max_energy)))
	player.set_flat(DataManager.FlatStat.MAX_ENERGY, int(player_data.get("max_energy", RunManager.max_energy)))
	player.set_flat(DataManager.FlatStat.ATONEMENT, int(player_data.get("atonement", 0)))
	player.set_flat(DataManager.FlatStat.MAX_ATONEMENT, int(player_data.get("max_atonement", DataManager.PENITENT_MAX_ATONEMENT)))
	player.set_flat(DataManager.FlatStat.HAND_SIZE, int(player_data.get("hand_size", RunManager.starting_hand_size)))
	player.set_flat(DataManager.FlatStat.DRAW_PER_TURN, int(player_data.get("draw_per_turn", RunManager.cards_to_draw_per_turn)))
	
	# Восстанавливаем модификаторы
	var modifiers = player_data.get("modifiers", {})
	for stat in modifiers.keys():
		player.modifiers[stat] = modifiers[stat]
	
	# 🆕 Восстанавливаем character_class в RunManager — приводим к int()
	RunManager.current_character = int(player_data.get("character_class", DataManager.CharacterClass.PENITENT))
	
	
func restore_game_state(game_state_data: Dictionary) -> void:
	var floor_data = game_state_data.get("floor_manager", {})
	
	# 🆕 Восстанавливаем базовые данные — приводим к int()
	FloorManager.current_path_index = int(floor_data.get("current_path_index", 0))
	FloorManager.current_path_progress = int(floor_data.get("current_path_progress", 0))
	FloorManager.current_segment_index = int(floor_data.get("current_segment_index", 0))
	FloorManager.boss_generated = bool(floor_data.get("boss_generated", false))
	FloorManager.current_floor = int(floor_data.get("current_floor", 1))
	FloorManager.current_biome = int(floor_data.get("current_biome", DataManager.Biome.MOLE_TUNNELS))

	# 🆕 Восстанавливаем current_room_index в обоих местах
	var room_index = int(floor_data.get("current_room_index", 0))
	GameTestManager.current_room_index = room_index
	FloorManager.current_room_index = room_index  # ← СИНХРОНИЗИРУЕМ
	
	# Восстанавливаем all_rooms
	FloorManager.all_rooms.clear()
	var rooms_data = floor_data.get("all_rooms", [])
	for room_entry in rooms_data:
		var room = RoomNode.new()
		room.setup({
			"type": int(room_entry.get("room_type", DataManager.RoomType.COMBAT)),      # 🆕 int()
			"combat_type": int(room_entry.get("combat_type", DataManager.CombatType.NORMAL)),  # 🆕 int()
			"object_type": int(room_entry.get("object_type", DataManager.ObjectType.CHEST)),   # 🆕 int()
			"is_revealed": bool(room_entry.get("is_revealed", true)),                          # 🆕 bool()
		})
		room.is_visited = bool(room_entry.get("is_visited", false))  # 🆕 bool()
		FloorManager.all_rooms.append(room)
	
	# Восстанавливаем all_paths
	FloorManager.all_paths.clear()
	var paths_data = floor_data.get("all_paths", [])
	for segment_entry in paths_data:
		var segment: Array = []
		for path_entry in segment_entry:
			var path: Array = []
			for room_entry in path_entry:
				var room = RoomNode.new()
				room.setup({
					"type": int(room_entry.get("room_type", DataManager.RoomType.COMBAT)),      # 🆕 int()
					"combat_type": int(room_entry.get("combat_type", DataManager.CombatType.NORMAL)),  # 🆕 int()
					"object_type": int(room_entry.get("object_type", DataManager.ObjectType.CHEST)),   # 🆕 int()
					"is_revealed": bool(room_entry.get("is_revealed", true)),                          # 🆕 bool()
				})
				room.is_visited = bool(room_entry.get("is_visited", false))  # 🆕 bool()
				path.append(room)
			segment.append(path)
		FloorManager.all_paths.append(segment)
	
	# 🆕 Восстанавливаем BattleManager — приводим к int()
	BattleManager.turn_counter = int(game_state_data.get("turn_counter", 1))
	BattleManager.current_state = int(game_state_data.get("battle_state", DataManager.BattleState.IDLE))

func _restore_artifacts(artifacts_data: Array) -> void:
	# Очищаем текущие артефакты
	RunManager.artifacts.clear()
	
	for artifact_entry in artifacts_data:
		var artifact_id = int(artifact_entry.get("id"))  # 🆕 int()
		var artifact_resource = DataManager.get_artifact_resource(artifact_id)
		if artifact_resource:
			var instance = artifact_resource.duplicate_for_instance()
			RunManager.artifacts.append(instance)


func _restore_potions(potions_data: Array) -> void:
	RunManager.potions.clear()
	
	for potion_entry in potions_data:
		var potion_type = int(potion_entry.get("type"))  # 🆕 int()
		var potion_resource = DataManager.get_potion_resource_by_type(potion_type)
		if potion_resource:
			var instance = potion_resource.duplicate_for_instance()
			RunManager.potions.append(instance)


func _restore_deck(deck_cards_data: Array) -> void:
	var deck = RunManager.get_player_deck()
	if not deck:
		return
	
	deck.master_cards.clear()
	
	for card_entry in deck_cards_data:
		# 🆕 int()
		var card_id = int(card_entry.get("id"))
		var base_card = DataManager.get_card(card_id)
		if not base_card:
			continue
		
		var card = base_card.duplicate_for_instance()
		
		# 🆕 int() и bool()
		card.cost = int(card_entry.get("cost", base_card.cost))
		card.upgrade_type = int(card_entry.get("upgrade_type", base_card.upgrade_type))
		card.is_can_upgrade = bool(card_entry.get("is_can_upgrade", base_card.is_can_upgrade))
		card.is_burned = bool(card_entry.get("is_burned", base_card.is_burned))
		
		var effects_data = card_entry.get("effects", [])
		if not effects_data.is_empty():
			card.effects.clear()
			for effect_entry in effects_data:
				var effect = _restore_effect(effect_entry)
				if effect:
					card.effects.append(effect)
		
		deck.master_cards.append(card)


func _restore_effect(effect_entry: Dictionary) -> EffectEntry:
	var effect = EffectEntry.new()
	
	# === БАЗОВЫЕ ПОЛЯ ===
	effect.category = int(effect_entry.get("category", 0))
	effect.target = int(effect_entry.get("target", DataManager.EffectTarget.ENEMY))
	effect.base_value = int(effect_entry.get("base_value", 0))
	effect.value = int(effect_entry.get("value", 0))
	effect.duration = int(effect_entry.get("duration", 0))
	effect.amount = int(effect_entry.get("amount", 0))
	effect.delta = int(effect_entry.get("delta", 0))
	effect.is_direct_damage = bool(effect_entry.get("is_direct_damage", true))
	effect.stat_multiplier = int(effect_entry.get("stat_multiplier", 0))
	effect.stat_divisor = int(effect_entry.get("stat_divisor", 10))
	effect.scaled_type = int(effect_entry.get("scaled_type", 0))
	effect.scaled_resource = int(effect_entry.get("scaled_resource", 0))
	effect.scaled_compare = int(effect_entry.get("scaled_compare", 0))
	effect.scaled_spend_resource = bool(effect_entry.get("scaled_spend_resource", false))
	effect.from_stat = int(effect_entry.get("from_stat", 0))
	effect.to_stat = int(effect_entry.get("to_stat", 0))
	effect.conversion_ratio = float(effect_entry.get("conversion_ratio", 1.0))
	effect.convert_from_status = int(effect_entry.get("convert_from_status", 0))
	effect.convert_to_stat = int(effect_entry.get("convert_to_stat", 0))
	effect.convert_conversion_ratio = float(effect_entry.get("convert_conversion_ratio", 1.0))
	effect.target_stat = int(effect_entry.get("target_stat", 0))
	effect.target_modifier = int(effect_entry.get("target_modifier", 0))
	effect.delta_percent = float(effect_entry.get("delta_percent", 0.0))
	effect.modifier_duration = int(effect_entry.get("modifier_duration", 0))
	effect.grow_type = int(effect_entry.get("grow_type", 0))
	effect.grow_value = int(effect_entry.get("grow_value", 1))
	effect.grow_target = int(effect_entry.get("grow_target", 0))
	effect.passive_duration = int(effect_entry.get("passive_duration", 0))
	
	# === ВОССТАНАВЛИВАЕМ SCALED_VALUES (ОЧИЩАЕМ И ЗАПОЛНЯЕМ) ===
	var new_scaled_values = effect_entry.get("scaled_values", [0, 0, 0, 0])
	if new_scaled_values is Array:
		effect.scaled_values.clear()
		for val in new_scaled_values:
			effect.scaled_values.append(int(val))
	
	# === ВОССТАНАВЛИВАЕМ SCALED_THRESHOLDS (ОЧИЩАЕМ И ЗАПОЛНЯЕМ) ===
	var new_scaled_thresholds = effect_entry.get("scaled_thresholds", [0, 0, 0, 0])
	if new_scaled_thresholds is Array:
		effect.scaled_thresholds.clear()
		for val in new_scaled_thresholds:
			effect.scaled_thresholds.append(int(val))
	
	# === ВОССТАНАВЛИВАЕМ КАСТОМНЫЙ СКРИПТ ===
	var custom_script_path = effect_entry.get("custom_script_path", "")
	if not custom_script_path.is_empty():
		var script = load(custom_script_path)
		if script:
			effect.custom_script = script
		else:
			printerr("Failed to load custom script: ", custom_script_path)
	
	# === ВОССТАНАВЛИВАЕМ СКРИПТ УСЛОВИЯ (для CONDITIONAL) ===
	var condition_script_path = effect_entry.get("condition_script_path", "")
	if not condition_script_path.is_empty():
		var script = load(condition_script_path)
		if script:
			effect.condition_script = script
		else:
			printerr("Failed to load condition script: ", condition_script_path)
	
	# === ВОССТАНАВЛИВАЕМ КАСТОМНОЕ ОПИСАНИЕ ===
	if effect_entry.has("custom_description"):
		effect.custom_description = effect_entry.get("custom_description", "")
	
	# === ВОССТАНАВЛИВАЕМ STATUS ===
	if effect_entry.has("status_id"):
		var status_id = int(effect_entry.get("status_id"))
		var status_resource = DataManager.get_status_resource(status_id)
		if status_resource:
			effect.status = status_resource
	
	# === ВОССТАНАВЛИВАЕМ PASSIVE ===
	if effect_entry.has("passive_id"):
		var passive_id = int(effect_entry.get("passive_id"))
		var passive_resource = DataManager.get_passive_resource(passive_id)
		if passive_resource:
			effect.passive = passive_resource
	
	# === ВОССТАНАВЛИВАЕМ УСЛОВНЫЕ ЭФФЕКТЫ ===
	if effect.category == DataManager.EffectCategory.CONDITIONAL:
		if effect_entry.has("true_effect"):
			var true_effect_data = effect_entry.get("true_effect")
			if true_effect_data is Dictionary:
				effect.true_effect = _restore_effect(true_effect_data)
		if effect_entry.has("false_effect"):
			var false_effect_data = effect_entry.get("false_effect")
			if false_effect_data is Dictionary:
				effect.false_effect = _restore_effect(false_effect_data)
	
	return effect

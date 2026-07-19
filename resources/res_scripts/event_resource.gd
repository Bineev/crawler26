# resources/res_scripts/event_resource.gd
extends Resource
class_name EventResource

@export var event_type: DataManager.EventType
@export var name_key: String = ""
@export var narrative_key: String = ""

# === ПЕРВОЕ ДЕЙСТВИЕ ===
@export var first_action: DataManager.ActionType = DataManager.ActionType.EVENT_MINER_SEARCH
@export var first_action_success_rewards: Array[DataManager.RewardType] = []
@export var first_action_failure_rewards: Array[DataManager.RewardType] = []
@export var first_action_success_key: String = ""
@export var first_action_failure_key: String = ""

# Параметры для наград первого действия (успех)
@export var first_success_gold_mod: int = 1
@export var first_success_damage_mod: int = 1
@export var first_success_heal_mod: int = 1
@export var first_success_buff_duration: int = 3
@export var first_success_upgrade_count: int = 1
@export var first_success_choice_count: int = 3
@export var first_success_buff_amount: int = 1

# Параметры для наград первого действия (неудача)
@export var first_failure_gold_mod: int = 1
@export var first_failure_damage_mod: int = 1
@export var first_failure_heal_mod: int = 1
@export var first_failure_buff_duration: int = 3
@export var first_failure_upgrade_count: int = 1
@export var first_failure_choice_count: int = 3
@export var first_failure_buff_amount: int = 1

# === ВТОРОЕ ДЕЙСТВИЕ ===
@export var second_action: DataManager.ActionType = DataManager.ActionType.EVENT_MINER_HELP
@export var second_action_success_rewards: Array[DataManager.RewardType] = []
@export var second_action_failure_rewards: Array[DataManager.RewardType] = []
@export var second_action_success_key: String = ""
@export var second_action_failure_key: String = ""

# Параметры для наград второго действия (успех)
@export var second_success_gold_mod: int = 1
@export var second_success_damage_mod: int = 1
@export var second_success_heal_mod: int = 1
@export var second_success_buff_duration: int = 3
@export var second_success_upgrade_count: int = 1
@export var second_success_choice_count: int = 3
@export var second_success_buff_amount: int = 1

# Параметры для наград второго действия (неудача)
@export var second_failure_gold_mod: int = 1
@export var second_failure_damage_mod: int = 1
@export var second_failure_heal_mod: int = 1
@export var second_failure_buff_duration: int = 3
@export var second_failure_upgrade_count: int = 1
@export var second_failure_choice_count: int = 3
@export var second_failure_buff_amount: int = 1

# === КОНКРЕТНЫЕ РЕСУРСЫ И ТИПЫ ВРАГОВ ===

# Первое действие
@export var first_success_enemy: DataManager.EnemyId = DataManager.EnemyId.MOLE_MUTANT
@export var first_failure_enemy: DataManager.EnemyId = DataManager.EnemyId.MOLE_MUTANT
@export var first_success_concrete_artifact_id: DataManager.ArtifactId = DataManager.ArtifactId.STRANGE_MUSHROOM
@export var first_success_concrete_card_id: DataManager.CardId = DataManager.CardId.ATONEMENT_STRIKE
@export var first_failure_concrete_artifact_id: DataManager.ArtifactId = DataManager.ArtifactId.STRANGE_MUSHROOM
@export var first_failure_concrete_card_id: DataManager.CardId = DataManager.CardId.ATONEMENT_STRIKE

# Второе действие
@export var second_success_enemy: DataManager.EnemyId = DataManager.EnemyId.MOLE_MUTANT
@export var second_failure_enemy: DataManager.EnemyId = DataManager.EnemyId.MOLE_MUTANT
@export var second_success_concrete_artifact_id: DataManager.ArtifactId = DataManager.ArtifactId.STRANGE_MUSHROOM
@export var second_success_concrete_card_id: DataManager.CardId = DataManager.CardId.ATONEMENT_STRIKE
@export var second_failure_concrete_artifact_id: DataManager.ArtifactId = DataManager.ArtifactId.STRANGE_MUSHROOM
@export var second_failure_concrete_card_id: DataManager.CardId = DataManager.CardId.ATONEMENT_STRIKE

func get_localized_name() -> String:
	return tr(name_key)

func get_localized_narrative() -> String:
	return tr(narrative_key)

func get_actions() -> Array[DataManager.ActionType]:
	var result: Array[DataManager.ActionType] = []
	
	if first_action:
		result.append(first_action)
	
	if second_action:
		result.append(second_action)
	
	return result

func get_action_rewards(action: DataManager.ActionType, success: bool) -> Array[DataManager.RewardType]:
	if action == first_action:
		return first_action_success_rewards if success else first_action_failure_rewards
	elif action == second_action:
		return second_action_success_rewards if success else second_action_failure_rewards
	return []

func get_action_result_key(action: DataManager.ActionType, success: bool) -> String:
	if action == first_action:
		return first_action_success_key if success else first_action_failure_key
	elif action == second_action:
		return second_action_success_key if success else second_action_failure_key
	return ""

func get_action_params(action: DataManager.ActionType, success: bool) -> Dictionary:
	var prefix = "first" if action == first_action else "second"
	var outcome = "success" if success else "failure"
	
	var params = {
		"gold_mod": 1,
		"damage_mod": 1,
		"heal_mod": 1,
		"buff_duration": 3,
		"upgrade_count": 1,
		"choice_count": 3,
		"enemy": DataManager.EnemyId.MOLE_MUTANT,
		"concrete_artifact_id": DataManager.ArtifactId.STRANGE_MUSHROOM,
		"concrete_card_id": DataManager.CardId.ATONEMENT_STRIKE,
	}
	
	params["gold_mod"] = get(prefix + "_" + outcome + "_gold_mod")
	params["damage_mod"] = get(prefix + "_" + outcome + "_damage_mod")
	params["heal_mod"] = get(prefix + "_" + outcome + "_heal_mod")
	params["buff_duration"] = get(prefix + "_" + outcome + "_buff_duration")
	params["upgrade_count"] = get(prefix + "_" + outcome + "_upgrade_count")
	params["choice_count"] = get(prefix + "_" + outcome + "_choice_count")
	params["enemy"] = get(prefix + "_" + outcome + "_enemy")
	params["concrete_artifact_id"] = get(prefix + "_" + outcome + "_concrete_artifact_id")
	params["concrete_card_id"] = get(prefix + "_" + outcome + "_concrete_card_id")
	
	return params

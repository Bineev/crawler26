# autoload/tooltip_manager.gd
extends Node

func request_status_tooltip(status_id: DataManager.Status, position: Vector2):
	var data = _build_status_tooltip_data(status_id)
	SignalManager.tooltip_requested.emit(data, position)

func request_passive_tooltip(passive_id: DataManager.Passive, position: Vector2):
	var data = _build_passive_tooltip_data(passive_id)
	SignalManager.tooltip_requested.emit(data, position)

func _build_status_tooltip_data(status_id: DataManager.Status) -> Dictionary:
	var name = DataManager.get_status_name(status_id)
	var desc = _get_status_description(status_id)
	
	return {
		"icon": DataManager.get_status_icon(status_id),
		"title": name,
		"description": desc,
	}

func _build_passive_tooltip_data(passive_id: DataManager.Passive) -> Dictionary:
	var resource = DataManager.get_passive_resource(passive_id)
	return {
		"icon": DataManager.get_passive_icon(passive_id),
		"title": resource.get_localized_name(),
		"description": resource.get_localized_description(),
	}

func _get_status_description(status_id: DataManager.Status) -> String:
	match status_id:
		DataManager.Status.POISON:
			return tr("status_poison_desc") % [RunManager.poison_damage_per_stack, 25]
		DataManager.Status.BLEED:
			return tr("status_bleed_desc") % RunManager.bleed_damage_per_stack
		DataManager.Status.BURN:
			return tr("status_burn_desc") % [RunManager.burn_damage_per_stack, RunManager.burn_threshold_stacks]
		DataManager.Status.COLD:
			return tr("status_cold_desc") % [RunManager.cold_effect_percent * 100, RunManager.cold_freeze_threshold]
		DataManager.Status.WEAKNESS:
			return tr("status_weakness_desc") % [(1 - RunManager.weakness_damage_multiplier) * 100]
		DataManager.Status.VULNERABILITY:
			return tr("status_vulnerability_desc") % [(RunManager.vulnerability_damage_multiplier - 1) * 100]
		DataManager.Status.STRENGTH:
			return tr("status_strength_desc") % RunManager.strength_bonus_per_stack
		DataManager.Status.REGEN:
			return tr("status_regen_desc") % RunManager.regen_heal_per_stack
		DataManager.Status.SHIELD:
			return tr("status_shield_desc")
		DataManager.Status.FROZEN:
			return tr("status_frozen_desc")
		DataManager.Status.GANGRENE:
			return tr("status_gangrene_desc")
		_:
			return ""


func request_card_type_tooltip(card_type: DataManager.CardType, position: Vector2):
	var data = _build_card_type_tooltip_data(card_type)
	SignalManager.tooltip_requested.emit(data, position)

func _build_card_type_tooltip_data(card_type: DataManager.CardType) -> Dictionary:
	var name = _get_card_type_name(card_type)
	var desc = _get_card_type_description(card_type)
	
	return {
		"icon": DataManager.get_card_type_icon(card_type),
		"title": name,
		"description": desc,
	}

func _get_card_type_name(card_type: DataManager.CardType) -> String:
	match card_type:
		DataManager.CardType.ATTACK:
			return tr("ui_attack")
		DataManager.CardType.DEFEND:
			return tr("ui_defend")
		DataManager.CardType.HEAL:
			return tr("ui_heal")
		DataManager.CardType.BUFF_SELF:
			return tr("ui_buff")
		DataManager.CardType.DEBUFF:
			return tr("ui_debuff")
		DataManager.CardType.UTILITY:
			return tr("ui_utility")
		DataManager.CardType.RESOURCE:
			return tr("ui_resource")
		_:
			return ""

func _get_card_type_description(card_type: DataManager.CardType) -> String:
	match card_type:
		DataManager.CardType.ATTACK:
			return tr("card_type_attack_desc")
		DataManager.CardType.DEFEND:
			return tr("card_type_defend_desc")
		DataManager.CardType.HEAL:
			return tr("card_type_heal_desc")
		DataManager.CardType.BUFF_SELF:
			return tr("card_type_buff_desc")
		DataManager.CardType.DEBUFF:
			return tr("card_type_debuff_desc")
		DataManager.CardType.UTILITY:
			return tr("card_type_utility_desc")
		DataManager.CardType.RESOURCE:
			return tr("card_type_resource_desc")
		_:
			return ""

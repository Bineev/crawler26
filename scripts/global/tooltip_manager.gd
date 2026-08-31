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
	var additional = _get_status_additional_info(status_id)
	
	return {
		"icon": DataManager.get_status_icon(status_id),
		"title": name,
		"description": desc,
		"additional_info": additional,
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
			return tr("status_poison_desc") % [RunManager.poison_damage_per_stack, RunManager.poison_healing_reduction * 100]
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
		DataManager.Status.BLISTER:
			return tr("status_blister_desc")
		DataManager.Status.INFECTION:
			return tr("status_infection_desc")
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


func request_dynamic_status_tooltip(status_id: DataManager.Status, stacks: int, duration: int, status_data: Dictionary, position: Vector2):
	var data = _build_dynamic_status_tooltip_data(status_id, stacks, duration, status_data)
	SignalManager.tooltip_requested.emit(data, position)

func _build_dynamic_status_tooltip_data(status_id: DataManager.Status, stacks: int, duration: int, status_data: Dictionary) -> Dictionary:
	var name = DataManager.get_status_name(status_id)
	var desc = _get_dynamic_status_description(status_id, stacks, duration, status_data)  # ← передаём
	var additional = _get_status_additional_info(status_id, status_data)  # ← передаём status_data
	
	return {
		"icon": DataManager.get_status_icon(status_id),
		"title": name,
		"description": desc,
		"additional_info": additional,
	}


func _get_dynamic_status_description(status_id: DataManager.Status, stacks: int, duration: int, status_data: Dictionary = {}) -> String:
	match status_id:
		DataManager.Status.POISON:
			var damage = stacks * RunManager.poison_damage_per_stack
			var healing_reduction = RunManager.poison_healing_reduction * 100
			return tr("status_poison_dynamic_desc") % [damage, duration, healing_reduction]
		DataManager.Status.BLEED:
			var damage_per_stack = RunManager.bleed_damage_per_stack
			return tr("status_bleed_dynamic_desc") % [damage_per_stack, stacks, duration]
		DataManager.Status.BURN:
			var damage_per_stack = RunManager.burn_damage_per_stack
			var total_damage = stacks * damage_per_stack
			var threshold = RunManager.burn_threshold_stacks
			return tr("status_burn_dynamic_desc") % [damage_per_stack, stacks, duration, threshold]
		DataManager.Status.COLD:
			var percent = stacks * RunManager.cold_effect_percent * 100
			var threshold = RunManager.cold_freeze_threshold
			return tr("status_cold_dynamic_desc") % [percent, stacks, duration, threshold]
		DataManager.Status.WEAKNESS:  # 🆕
			var percent = (1 - RunManager.weakness_damage_multiplier) * 100
			return tr("status_weakness_dynamic_desc") % [percent, duration]
		DataManager.Status.VULNERABILITY:  # 🆕
			var percent = (RunManager.vulnerability_damage_multiplier - 1) * 100
			return tr("status_vulnerability_dynamic_desc") % [percent, duration]
		DataManager.Status.STRENGTH:
			var bonus = stacks * RunManager.strength_bonus_per_stack
			return tr("status_strength_dynamic_desc") % [bonus, duration]
		DataManager.Status.REGEN:
			var heal = stacks * RunManager.regen_heal_per_stack
			return tr("status_regen_dynamic_desc") % [heal, duration]
		DataManager.Status.SHIELD:
			return tr("status_shield_dynamic_desc") % [stacks, duration]
		DataManager.Status.FROZEN:
			return tr("status_frozen_desc")
		DataManager.Status.GANGRENE:
			return tr("status_gangrene_dynamic_desc") % [stacks, duration]
		DataManager.Status.BLISTER:
			var blister_data = _get_blister_data()
			if blister_data:
				return tr("status_blister_dynamic_desc") % [blister_data.current_health, blister_data.duration]
			return tr("status_blister_desc")
		DataManager.Status.INFECTION:
			# 🆕 Берём effect_per_stack из данных статуса на цели
			var damage = status_data.get("effect_per_stack", 1)
			return tr("status_infection_dynamic_desc") % [damage, duration]
		_:
			return ""

# ============================================================
# ДИНАМИЧЕСКИЕ ПАССИВКИ (для "живых" иконок)
# ============================================================

func request_dynamic_passive_tooltip(passive_data: Dictionary, position: Vector2):
	var data = _build_dynamic_passive_tooltip_data(passive_data)
	SignalManager.tooltip_requested.emit(data, position)


func _build_dynamic_passive_tooltip_data(passive_data: Dictionary) -> Dictionary:
	var passive = passive_data["passive"]
	
	# Статическое описание (из ресурса)
	var static_desc = passive.get_localized_description()
	
	# 🆕 Динамическая информация о зарядах/длительности
	var charges_info = _get_passive_charges_info(passive)
	
	return {
		"icon": passive_data["icon"],
		"title": passive_data["name"],
		"description": static_desc,
		"additional_info": charges_info,  # только информация о зарядах
	}
#func _build_dynamic_passive_tooltip_data(passive_data: Dictionary) -> Dictionary:
	#var passive = passive_data["passive"]
	#
	## 🆕 Статическое описание (из ресурса)
	#var static_desc = passive.get_localized_description()
	#
	## 🆕 Динамическое описание (триггеры, эффекты, модификаторы)
	#var dynamic_desc = _get_dynamic_passive_description(passive)
	#var charges_info = _get_passive_charges_info(passive)
	## 🆕 Если есть заряды — добавляем их в additional_info
	#var additional = dynamic_desc
	#if not charges_info.is_empty():
		#if not additional.is_empty():
			#additional += "\n"
		#additional += charges_info
	#return {
		#"icon": passive_data["icon"],
		#"title": passive_data["name"],
		#"description": static_desc,  # статическое описание
		#"additional_info": additional,  # динамическое описание (триггеры, эффекты)
	#}

func _get_dynamic_passive_description(passive: PassiveResource) -> String:
	var parts: Array[String] = []
	
	# Триггер
	match passive.trigger:
		DataManager.PassiveTrigger.ON_TURN_START:
			parts.append(tr("passive_trigger_turn_start"))
		DataManager.PassiveTrigger.ON_TURN_END:
			parts.append(tr("passive_trigger_turn_end"))
		DataManager.PassiveTrigger.ON_TAKE_DAMAGE:
			parts.append(tr("passive_trigger_take_damage"))
		DataManager.PassiveTrigger.ON_DEAL_DAMAGE:
			parts.append(tr("passive_trigger_deal_damage"))
		DataManager.PassiveTrigger.ON_PLAY_CARD:
			parts.append(tr("passive_trigger_play_card"))
		DataManager.PassiveTrigger.ON_APPLY_STATUS:
			parts.append(tr("passive_trigger_apply_status"))
		DataManager.PassiveTrigger.ON_GAIN_BLOCK:
			parts.append(tr("passive_trigger_gain_block"))
		DataManager.PassiveTrigger.ON_KILL_ENEMY:
			parts.append(tr("passive_trigger_kill_enemy"))
		DataManager.PassiveTrigger.ON_STATUS_TICK:
			parts.append(tr("passive_trigger_status_tick"))
	
	# Эффекты
	for effect in passive.effects:
		var effect_desc = _effect_to_description(effect)
		if not effect_desc.is_empty():
			parts.append(effect_desc)
	
	# Модификаторы
	for mod in passive.modifiers:
		var mod_desc = _modifier_to_description(mod)
		if not mod_desc.is_empty():
			parts.append(mod_desc)
	
	return ", ".join(parts)

func _effect_to_description(effect: EffectEntry) -> String:
	match effect.category:
		DataManager.EffectCategory.APPLY_STATUS:
			if effect.status:
				var target = tr("target_self") if effect.target == DataManager.EffectTarget.SELF else tr("target_enemy")
				
				# 🆕 Подсчитываем актуальные значения с учётом роста
				var value = _get_effect_value(effect)
				var duration = _get_effect_duration(effect)
				
				return tr("passive_effect_apply_status") % [target, value, effect.status.get_localized_name(), duration]
		DataManager.EffectCategory.HEAL:
			return tr("passive_effect_heal") % effect.base_value
		DataManager.EffectCategory.DAMAGE:
			return tr("passive_effect_damage") % effect.base_value
		DataManager.EffectCategory.BLOCK:
			return tr("passive_effect_block") % effect.base_value
		DataManager.EffectCategory.APPLY_PASSIVE:
			if effect.passive:
				return tr("passive_effect_apply_passive") % effect.passive.get_localized_name()
		_:
			return ""
	return ""

func _modifier_to_description(mod: ModifierEntry) -> String:
	match mod.stat:
		DataManager.ModifierStat.DAMAGE_DEALT_PERCENT:
			return tr("passive_modifier_damage_dealt") % [(mod.value - 1.0) * 100]
		DataManager.ModifierStat.DAMAGE_TAKEN_PERCENT:
			return tr("passive_modifier_damage_taken") % [mod.value * 100]
		DataManager.ModifierStat.ATONEMENT_GAIN_MULTIPLIER:
			return tr("passive_modifier_atonement") % [(mod.value - 1.0) * 100]
		_:
			return ""


func _get_passive_charges_info(passive: PassiveResource) -> String:
	if not passive.has_charges():
		return ""
	
	match passive.charge_type:
		DataManager.PassiveChargeType.TURN_BASED:
			return tr("passive_charges_turn_based") % passive.current_charges
		DataManager.PassiveChargeType.USAGE_BASED:
			return tr("passive_charges_usage_based") % passive.current_charges
		DataManager.PassiveChargeType.CONDITIONAL:
			return tr("passive_charges_conditional") % passive.current_charges
		_:
			return ""
#func _get_passive_charges_info(passive: PassiveResource) -> String:
	#if not passive.has_charges():
		#return ""
	#
	#match passive.charge_type:
		#DataManager.PassiveChargeType.TURN_BASED:
			#return tr("passive_charges_turn_based") % passive.current_charges
		#DataManager.PassiveChargeType.USAGE_BASED:
			#return tr("passive_charges_usage_based") % passive.current_charges
		#DataManager.PassiveChargeType.CONDITIONAL:
			#return tr("passive_charges_conditional") % passive.current_charges
		#_:
			#return ""
	#return ""


func _get_effect_value(effect: EffectEntry) -> int:
	if effect.grow_type == DataManager.GrowType.NONE:
		return int(effect.value) if effect.value != null else 1
	
	# 🆕 Пересчитываем только если grow_target = VALUE или BOTH
	if effect.grow_target in [DataManager.GrowTarget.VALUE, DataManager.GrowTarget.BOTH]:
		match effect.grow_type:
			DataManager.GrowType.ADD:
				return effect.current_value + effect.grow_value
			DataManager.GrowType.SUBTRACT:
				return effect.current_value - effect.grow_value
			DataManager.GrowType.MULTIPLY:
				return effect.current_value * effect.grow_value
			DataManager.GrowType.DIVIDE:
				return effect.current_value / effect.grow_value
			_:
				return effect.current_value
	else:
		# Если растёт только duration, value не меняется
		return int(effect.value) if effect.value != null else 1


func _get_effect_duration(effect: EffectEntry) -> int:
	if effect.grow_type == DataManager.GrowType.NONE:
		return int(effect.duration) if effect.duration != null else 1
	
	# 🆕 Пересчитываем только если grow_target = DURATION или BOTH
	if effect.grow_target in [DataManager.GrowTarget.DURATION, DataManager.GrowTarget.BOTH]:
		match effect.grow_type:
			DataManager.GrowType.ADD:
				return effect.current_duration + effect.grow_value
			DataManager.GrowType.SUBTRACT:
				return effect.current_duration - effect.grow_value
			DataManager.GrowType.MULTIPLY:
				return effect.current_duration * effect.grow_value
			DataManager.GrowType.DIVIDE:
				return effect.current_duration / effect.grow_value
			_:
				return effect.current_duration
	else:
		# Если растёт только value, duration не меняется
		return int(effect.duration) if effect.duration != null else 1


func _get_status_additional_info(status_id: DataManager.Status, status_data: Dictionary = {}) -> String:
	match status_id:
		DataManager.Status.POISON:
			return tr("status_poison_additional")
		DataManager.Status.BLEED:
			return tr("status_bleed_additional")
		DataManager.Status.BURN:
			return tr("status_burn_additional") % RunManager.burn_threshold_stacks
		DataManager.Status.COLD:
			return tr("status_cold_additional") % RunManager.cold_freeze_threshold
		DataManager.Status.WEAKNESS:
			return tr("status_weakness_additional")
		DataManager.Status.VULNERABILITY:
			return tr("status_vulnerability_additional")
		DataManager.Status.STRENGTH:
			return tr("status_strength_additional")
		DataManager.Status.REGEN:
			return tr("status_regen_additional")
		DataManager.Status.SHIELD:
			return tr("status_shield_additional")
		DataManager.Status.FROZEN:
			return tr("status_frozen_additional") % RunManager.frozen_energy_loss
		DataManager.Status.GANGRENE:
			return tr("status_gangrene_additional")
		DataManager.Status.BLISTER:
			var blister_data = status_data.get("blister_data", {})
			if blister_data and not blister_data.is_empty():
				var burn_on_destroy = blister_data.get("burn_stacks_on_create", 0) * blister_data.get("poison_duration_on_create", 0)
				var damage_on_expire = blister_data.get("current_health", 0)
				return tr("status_blister_additional") % [burn_on_destroy, damage_on_expire]
			return ""
		DataManager.Status.INFECTION:
			return tr("status_infection_additional")
		_:
			return ""
			return ""


func request_artifact_tooltip(artifact: ArtifactResource, position: Vector2):
	var data = _build_artifact_tooltip_data(artifact)
	SignalManager.tooltip_requested.emit(data, position)

func _build_artifact_tooltip_data(artifact: ArtifactResource) -> Dictionary:
	var desc = artifact.get_localized_description()
	#var additional = _get_artifact_additional_info(artifact)
	
	return {
		"icon": artifact.get_icon(),
		"title": artifact.get_localized_name(),
		"description": desc,
		#"additional_info": additional,
	}

func _get_artifact_additional_info(artifact: ArtifactResource) -> String:
	var parts: Array[String] = []
	
	# Триггеры
	for trigger in artifact.triggers:
		match trigger:
			DataManager.ArtifactTrigger.ONE_TIME:
				parts.append(tr("artifact_trigger_one_time"))
			DataManager.ArtifactTrigger.TURN_COUNT_START:
				parts.append(tr("artifact_trigger_turn_count_start") % artifact.trigger_count)
			DataManager.ArtifactTrigger.TURN_COUNT_END:
				parts.append(tr("artifact_trigger_turn_count_end") % artifact.trigger_count)
			DataManager.ArtifactTrigger.ON_START_FIGHT:
				parts.append(tr("artifact_trigger_on_start_fight"))
			DataManager.ArtifactTrigger.CARD_PLAYED_COUNTER:
				parts.append(tr("artifact_trigger_card_played_counter") % artifact.card_count_threshold)
			DataManager.ArtifactTrigger.HEALTH_DROPPED_BELOW:
				var value = str(artifact.amount_check_conditional)
				if artifact.is_amount_check_percent:
					value = tr("artifact_trigger_health_dropped_below_percent") % artifact.amount_check_conditional
				else:
					value = tr("artifact_trigger_health_dropped_below_flat") % artifact.amount_check_conditional
				parts.append(value)
			DataManager.ArtifactTrigger.CUSTOM:
				parts.append(tr("artifact_trigger_custom"))
	
	return ", ".join(parts)


func request_potion_tooltip(potion: PotionResource, position: Vector2):
	var data = _build_potion_tooltip_data(potion)
	SignalManager.tooltip_requested.emit(data, position)

func _build_potion_tooltip_data(potion: PotionResource) -> Dictionary:
	var desc = potion.get_localized_description()
	
	return {
		"icon": DataManager.get_potion_icon(potion.potion_type),
		"title": potion.get_localized_name(),
		"description": desc,
	}


func _get_blister_data() -> Dictionary:
	# Получаем данные о текущем блистере (нужно передавать извне)
	# Пока заглушка
	return {"current_health": 0, "duration": 0}


func request_intent_tooltip(effect: EffectEntry, position: Vector2):
	var data = _build_intent_tooltip_data(effect)
	SignalManager.tooltip_requested.emit(data, position)


func _build_intent_tooltip_data(effect: EffectEntry) -> Dictionary:
	return {
		"icon": null,  # 🆕 без иконки
		"title": "",   # 🆕 без заголовка
		"description": _get_intent_description(effect),
	}

func _get_intent_title(effect: EffectEntry) -> String:
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			return tr("intent_damage_title")
		DataManager.EffectCategory.BLOCK:
			return tr("intent_block_title")
		DataManager.EffectCategory.HEAL:
			return tr("intent_heal_title")
		DataManager.EffectCategory.APPLY_STATUS:
			return tr("intent_debuff_title")
		DataManager.EffectCategory.APPLY_PASSIVE:
			return tr("intent_buff_title")
		_:
			return tr("intent_unknown_title")


func _get_intent_description(effect: EffectEntry) -> String:
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			return tr("intent_desc_attack")
		
		DataManager.EffectCategory.BLOCK:
			return tr("intent_desc_defend")
		
		DataManager.EffectCategory.HEAL:
			match effect.target:
				DataManager.EffectTarget.SELF:
					return tr("intent_desc_heal_self")
				DataManager.EffectTarget.ALL_ALLIES:
					return tr("intent_desc_heal_allies")
				DataManager.EffectTarget.ENEMY:
					return tr("intent_desc_heal_enemy")
				_:
					return tr("intent_desc_heal_unknown")
		
		DataManager.EffectCategory.APPLY_STATUS:
			var is_negative = effect.status and DataManager.is_negative_status(effect.status.id)
			match effect.target:
				DataManager.EffectTarget.SELF:
					if is_negative:
						return tr("intent_desc_debuff_self")
					else:
						return tr("intent_desc_buff_self")
				DataManager.EffectTarget.ENEMY:
					if is_negative:
						return tr("intent_desc_debuff_enemy")
					else:
						return tr("intent_desc_buff_enemy")
				DataManager.EffectTarget.ALL_ENEMIES:
					if is_negative:
						return tr("intent_desc_debuff_all_enemies")
					else:
						return tr("intent_desc_buff_all_enemies")
				DataManager.EffectTarget.ALL_ALLIES:
					if is_negative:
						return tr("intent_desc_debuff_all_allies")
					else:
						return tr("intent_desc_buff_all_allies")
				DataManager.EffectTarget.ANY:
					if is_negative:
						return tr("intent_desc_debuff_any")
					else:
						return tr("intent_desc_buff_any")
				_:
					return tr("intent_desc_unknown")
		
		DataManager.EffectCategory.APPLY_PASSIVE:
			match effect.target:
				DataManager.EffectTarget.SELF:
					return tr("intent_desc_buff_self")
				DataManager.EffectTarget.ALL_ALLIES:
					return tr("intent_desc_buff_allies")
				DataManager.EffectTarget.ENEMY:
					return tr("intent_desc_buff_enemy")
				_:
					return tr("intent_desc_unknown")
		
		_:
			return tr("intent_desc_unknown")

# resources/res_scripts/potion_resource.gd
extends Resource
class_name PotionResource

## Тип зелья
@export var potion_type: DataManager.PotionType

## Грейд стоимости в магазине
@export var cost_grade: DataManager.CostGrade = DataManager.CostGrade.NORMAL

## Ключ локализации для названия
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Эффекты зелья
@export var effects: Array[EffectEntry] = []

func get_localized_name() -> String:
	if not name_key.is_empty():
		return tr(name_key)
	return DataManager.PotionType.keys()[potion_type]

func get_localized_description() -> String:
	return generate_dynamic_description()

func duplicate_for_instance() -> PotionResource:
	var copy = PotionResource.new()
	copy.potion_type = potion_type
	copy.name_key = name_key
	copy.description_key = description_key
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	return copy

func generate_dynamic_description() -> String:
	var desc_parts: Array[String] = []
	
	for effect in effects:
		var effect_desc = _effect_to_string(effect)
		if not effect_desc.is_empty():
			desc_parts.append(effect_desc)
	
	if desc_parts.is_empty():
		return tr("card_no_effect_description")
	
	# 🆕 Пост-парсинг: объединяем и чистим
	var full_desc = "\n".join(desc_parts)
	full_desc = _post_process_description(full_desc)
	
	return full_desc

func _effect_to_string(effect: EffectEntry) -> String:
	var target_text = _get_target_action(effect.target)
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			return tr("effect_damage") % [target_text, effect.base_value]
		
		DataManager.EffectCategory.BLOCK:
			return tr("effect_block") % [target_text, effect.base_value]
		
		DataManager.EffectCategory.HEAL:
			return tr("effect_heal") % [target_text, effect.base_value]
		
		DataManager.EffectCategory.APPLY_STATUS:
			if effect.status:
				var status_name = effect.status.get_localized_name()
				var target_action = _get_target_action_for_status(effect.target)
				if effect.value > 0 and effect.duration > 0:
					return tr("effect_apply_status_stacks_duration") % [target_action, effect.value, status_name, effect.duration]
				elif effect.value > 0:
					return tr("effect_apply_status_stacks") % [target_action, effect.value, status_name]
				elif effect.duration > 0:
					return tr("effect_apply_status_duration") % [target_action, status_name, effect.duration]
			return ""

		DataManager.EffectCategory.APPLY_PASSIVE:
			if effect.passive:
				return tr("effect_apply_passive") % [_get_target_action_for_status(effect.target), effect.passive.get_localized_name()]
			return ""
		
		DataManager.EffectCategory.MODIFY_STAT:
			var stat_name = DataManager.FlatStat.keys()[effect.target_stat]
			return tr("effect_modify_stat") % [_get_target_action(effect.target), stat_name, effect.delta]
		
		DataManager.EffectCategory.DRAW_CARD:
			return tr("effect_draw_card") % effect.amount
		
		DataManager.EffectCategory.GAIN_ENERGY:
			return tr("effect_gain_energy") % effect.amount
		
		DataManager.EffectCategory.SCALED_VALUE:
			var resource_name = DataManager.ScaledResource.keys()[effect.scaled_resource]
			match effect.scaled_type:
				DataManager.ScaledType.DAMAGE:
					return tr("effect_scaled_damage") % [resource_name]
				DataManager.ScaledType.BLOCK:
					return tr("effect_scaled_block") % [resource_name]
				DataManager.ScaledType.HEAL:
					return tr("effect_scaled_heal") % [resource_name]
				DataManager.ScaledType.GAIN_ENERGY:
					return tr("effect_scaled_energy") % resource_name
				DataManager.ScaledType.DRAW_CARD:
					return tr("effect_scaled_draw") % resource_name
			return ""
		
		DataManager.EffectCategory.CONDITIONAL:
			var condition_name = _get_condition_name(effect.condition_script)
			
			var true_desc = ""
			var false_desc = ""
			
			if effect.true_effect:
				true_desc = _effect_to_string(effect.true_effect)
			
			# Проверяем, есть ли false_effect и он не пустой
			if effect.false_effect:
				# Проверяем, что false_effect имеет значение > 0
				var has_effect = false
				match effect.false_effect.category:
					DataManager.EffectCategory.DAMAGE, DataManager.EffectCategory.BLOCK, DataManager.EffectCategory.HEAL:
						if effect.false_effect.base_value > 0:
							has_effect = true
					_:
						has_effect = true  # для других типов эффектов считаем, что он есть
				
				if has_effect:
					false_desc = _effect_to_string(effect.false_effect)
			
			# Формируем описание
			if not true_desc.is_empty() and not false_desc.is_empty():
				return tr("effect_conditional_both") % [condition_name, true_desc, false_desc]
			elif not true_desc.is_empty():
				return tr("effect_conditional_true") % [condition_name, true_desc]
			elif not false_desc.is_empty():
				return tr("effect_conditional_false") % [condition_name, false_desc]
			
			return ""
		
		DataManager.EffectCategory.CONVERT:
			return tr("effect_convert") % [
				DataManager.FlatStat.keys()[effect.from_stat],
				DataManager.FlatStat.keys()[effect.to_stat],
				effect.conversion_ratio
			]
		
		DataManager.EffectCategory.CONVERT_EXCESS_TO_BLOCK:
			return tr("effect_convert_excess_to_block")
		
		DataManager.EffectCategory.SACRIFICE_CARD:
			return tr("effect_sacrifice_card") % effect.amount
		
		DataManager.EffectCategory.CUSTOM:
			if not effect.custom_description.is_empty():
				return tr(effect.custom_description)  # 🆕 используем tr()
			return tr("effect_custom")
		
		_:
			return ""

func _get_target_action(target: DataManager.EffectTarget) -> String:
	match target:
		DataManager.EffectTarget.SELF:
			return tr("action_self")
		DataManager.EffectTarget.ENEMY:
			return tr("action_enemy")
		DataManager.EffectTarget.ALL_ENEMIES:
			return tr("action_all_enemies")
		DataManager.EffectTarget.ALL_ALLIES:
			return tr("action_all_allies")
		DataManager.EffectTarget.ANY:
			return tr("action_any")
		_:
			return ""

func _get_target_action_for_status(target: DataManager.EffectTarget) -> String:
	match target:
		DataManager.EffectTarget.SELF:
			return tr("status_action_self")
		DataManager.EffectTarget.ENEMY:
			return tr("status_action_enemy")
		DataManager.EffectTarget.ALL_ENEMIES:
			return tr("status_action_all_enemies")
		DataManager.EffectTarget.ALL_ALLIES:
			return tr("status_action_all_allies")
		DataManager.EffectTarget.ANY:
			return tr("status_action_any")
		_:
			return ""

func _get_condition_name(condition_script: Script) -> String:
	if not condition_script:
		return tr("condition_unknown")
	
	var script_path = condition_script.resource_path
	match script_path:
		"res://scripts/conditions/has_bleed.gd":
			return tr("condition_has_bleed")
		"res://scripts/conditions/has_cold.gd":
			return tr("condition_has_cold")
		"res://scripts/conditions/health_less_than_30.gd":
			return tr("condition_health_less_than_30")
		"res://scripts/conditions/no_negative_status.gd":
			return tr("condition_no_negative_status")
		_:
			return tr("condition_unknown")


func _post_process_description(desc: String) -> String:
	var lang = TranslationServer.get_locale()
	
	match lang:
		"ru":
			# 🆕 Заменяем 2+ точек подряд на 1 точку
			desc = _fix_multiple_dots(desc)
			
			# Исправляем окончания
			desc = _fix_russian_endings(desc)
		
		"en":
			desc = _fix_multiple_dots(desc)
	
	return desc


func _fix_multiple_dots(text: String) -> String:
	# Заменяем ".." на "." пока есть повторения
	while text.contains(".."):
		text = text.replace("..", ".")
	return text


func _fix_russian_endings(desc: String) -> String:
	# Словарь: [паттерн для поиска] = замена
	# Используем границы слова (пробел или начало строки)
	var replacements = {
		" 1 ход": " 1 ход",
		" 2 ход": " 2 хода",
		" 3 ход": " 3 хода",
		" 4 ход": " 4 хода",
		" 5 ход": " 5 ходов",
		" 6 ход": " 6 ходов",
		" 7 ход": " 7 ходов",
		" 8 ход": " 8 ходов",
		" 9 ход": " 9 ходов",
		
		# Стаки
		" стак": " cтаки",
		" 1 стак": " 1 стак",
		" 2 стак": " 2 стака",
		" 3 стак": " 3 стака",
		" 4 стак": " 4 стака",
		" 5 стак": " 5 стаков",
		" 6 стак": " 6 стаков",
		" 7 стак": " 7 стаков",
		" 8 стак": " 8 стаков",
		" 9 стак": " 9 стаков",
		
		# Карты
		" 1 карт": " 1 карту",
		" 2 карт": " 2 карты",
		" 3 карт": " 3 карты",
		" 4 карт": " 4 карты",
		" 5 карт": " 5 карт",
		" 6 карт": " 6 карт",
		" 7 карт": " 7 карт",
		" 8 карт": " 8 карт",
		" 9 карт": " 9 карт",
		
		# Блок — всегда "блока"
		" блок": " блока",
		
		# Урон — всегда "урона"
		" урон": " урона",
		
		# Энергия — всегда "энергии"
		" 0 энергия": " 0 энергии",
		" 1 энергия": " 1 энергию",
		" 2 энергия": " 2 энергии",
		" 3 энергия": " 3 энергии",
		" 4 энергия": " 4 энергии",
		" 5 энергия": " 5 энергии",
		" 6 энергия": " 6 энергии",
		" 7 энергия": " 7 энергии",
		" 8 энергия": " 8 энергии",
		" 9 энергия": " 9 энергии",
	}
	
	for pattern in replacements.keys():
		if desc.contains(pattern):
			desc = desc.replace(pattern, replacements[pattern])
	
	return desc


func get_cost_grade() -> DataManager.CostGrade:
	return cost_grade

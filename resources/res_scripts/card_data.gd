# resources/cards/card_data.gd
extends Resource
class_name CardData

## ============================================================
## ИДЕНТИФИКАЦИЯ
## ============================================================

## Уникальный ID карты
@export var id: DataManager.CardId

## 🆕 Сжигается ли карта после использования
@export var is_burned: bool = false

## Грейд стоимости в магазине
@export var cost_grade: DataManager.CostGrade = DataManager.CostGrade.NORMAL

## Происхождение карты (персонаж или биом)
@export var origin: DataManager.CardOrigin = DataManager.CardOrigin.CHARACTER

## Для карт персонажа
@export var character_class: DataManager.CharacterClass = DataManager.CharacterClass.PENITENT

## Для карт биома
@export var biome: DataManager.Biome = DataManager.Biome.MOLE_TUNNELS

## Тип улучшения карты (по умолчанию COST_MINUS_1)
@export var upgrade_type: DataManager.UpgradeType = DataManager.UpgradeType.COST_MINUS

## Ключ локализации для названия
@export var name_key: String = ""

## Ключ локализации для описания
@export var description_key: String = ""

## Иллюстрация карты
@export var texture: Texture2D

## Теги карты
@export var tags: Array[DataManager.CardTag] = []

## Можно ли улучшить карту (если false — карта не появляется в выборе для улучшения)
@export var is_can_upgrade: bool = true
## ============================================================
## ИГРОВЫЕ ПАРАМЕТРЫ
## ============================================================

## Грейд карты
@export var grade: DataManager.CardGrade = DataManager.CardGrade.COMMON

## Стоимость энергии
@export var cost: int = 1

## Список эффектов
@export var effects: Array[EffectEntry] = []

## ============================================================
## РУЧНЫЕ ИКОНКИ (для кастомных эффектов)
## ============================================================

## Статусы, которые нужно отобразить на карте (ручное указание)
@export var manual_status_icons: Array[DataManager.Status] = []

## Пассивки, которые нужно отобразить на карте (ручное указание)
@export var manual_passive_icons: Array[DataManager.Passive] = []
## ============================================================
## ВИЗУАЛЬНЫЕ ПАРАМЕТРЫ
## ============================================================

## Тип оверлея
@export var overlay_type: String = ""

## Ручное указание типов
@export var manual_card_types: Array[DataManager.CardType] = []


## ============================================================
## МЕТОДЫ
## ============================================================

func get_localized_name() -> String:
	if not name_key.is_empty():
		return tr(name_key)
	return DataManager.get_card_default_name(id)


func get_localized_description(placeholders: Dictionary = {}) -> String:
	if description_key.is_empty():
		return _generate_default_description()
	return tr(description_key).format(placeholders)


func get_card_background() -> Texture2D:
	match origin:
		DataManager.CardOrigin.CHARACTER:
			return DataManager.get_card_background_for_class(character_class)
		DataManager.CardOrigin.BIOME:
			return DataManager.get_card_background_for_biome(biome)
		_:
			return null


func get_base_color() -> Color:
	match origin:
		DataManager.CardOrigin.CHARACTER:
			match character_class:
				DataManager.CharacterClass.PENITENT:
					return Color(0.35, 0.15, 0.15)  # тёмно-бордовый
				_:
					return Color(0.2, 0.2, 0.2)
		DataManager.CardOrigin.BIOME:
			match biome:
				DataManager.Biome.MOLE_TUNNELS:
					return Color(0.15, 0.1, 0.05)  # тёмно-коричневый
				_:
					return Color(0.1, 0.1, 0.1)
		_:
			return Color(0.2, 0.2, 0.2)


func has_tag(tag: DataManager.CardTag) -> bool:
	return tag in tags


func get_card_types() -> Array[DataManager.CardType]:
	if not manual_card_types.is_empty():
		return manual_card_types.duplicate()
	return _analyze_card_types()


func _analyze_card_types() -> Array[DataManager.CardType]:
	var types: Array[DataManager.CardType] = []
	
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				_add_type_unique(types, DataManager.CardType.ATTACK)
			
			DataManager.EffectCategory.BLOCK:
				_add_type_unique(types, DataManager.CardType.DEFEND)
			
			DataManager.EffectCategory.HEAL:
				_add_type_unique(types, DataManager.CardType.HEAL)
			
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.target == DataManager.EffectTarget.SELF:
					# 🆕 Если статус негативный — не добавляем BUFF_SELF
					if effect.status and not DataManager.is_negative_status(effect.status.id):
						_add_type_unique(types, DataManager.CardType.BUFF_SELF)
				else:
					_add_type_unique(types, DataManager.CardType.DEBUFF)
			
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.target == DataManager.EffectTarget.SELF:
					_add_type_unique(types, DataManager.CardType.BUFF_SELF)
				else:
					_add_type_unique(types, DataManager.CardType.DEBUFF)
			
			DataManager.EffectCategory.DRAW_CARD, \
			DataManager.EffectCategory.GAIN_ENERGY, \
			DataManager.EffectCategory.SACRIFICE_CARD, \
			DataManager.EffectCategory.CONVERT, \
			DataManager.EffectCategory.CONVERT_EXCESS_TO_BLOCK, \
			DataManager.EffectCategory.MODIFY_STAT, \
			DataManager.EffectCategory.MODIFY_MODIFIER:
				_add_type_unique(types, DataManager.CardType.UTILITY)
			
			DataManager.EffectCategory.CONDITIONAL:
				# 🆕 Проверяем true_effect и false_effect
				if effect.true_effect:
					var true_types = _analyze_single_effect(effect.true_effect)
					for t in true_types:
						_add_type_unique(types, t)
				if effect.false_effect:
					var false_types = _analyze_single_effect(effect.false_effect)
					for t in false_types:
						_add_type_unique(types, t)
	
	return types

func _analyze_single_effect(effect: EffectEntry) -> Array[DataManager.CardType]:
	var types: Array[DataManager.CardType] = []
	
	match effect.category:
		DataManager.EffectCategory.DAMAGE:
			types.append(DataManager.CardType.ATTACK)
		DataManager.EffectCategory.BLOCK:
			types.append(DataManager.CardType.DEFEND)
		DataManager.EffectCategory.HEAL:
			types.append(DataManager.CardType.HEAL)
		DataManager.EffectCategory.APPLY_STATUS:
			if effect.target == DataManager.EffectTarget.SELF:
				if effect.status and not DataManager.is_negative_status(effect.status.id):
					types.append(DataManager.CardType.BUFF_SELF)
			else:
				types.append(DataManager.CardType.DEBUFF)
		DataManager.EffectCategory.APPLY_PASSIVE:
			if effect.target == DataManager.EffectTarget.SELF:
				types.append(DataManager.CardType.BUFF_SELF)
			else:
				types.append(DataManager.CardType.DEBUFF)
		DataManager.EffectCategory.DRAW_CARD, \
		DataManager.EffectCategory.GAIN_ENERGY, \
		DataManager.EffectCategory.SACRIFICE_CARD, \
		DataManager.EffectCategory.CONVERT, \
		DataManager.EffectCategory.CONVERT_EXCESS_TO_BLOCK, \
		DataManager.EffectCategory.MODIFY_STAT, \
		DataManager.EffectCategory.MODIFY_MODIFIER:
			types.append(DataManager.CardType.UTILITY)
	
	return types


func _add_type_unique(types: Array[DataManager.CardType], type: DataManager.CardType):
	if not types.has(type):
		types.append(type)


func _generate_default_description() -> String:
	var desc_parts = []
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.DAMAGE:
				desc_parts.append("Наносит %d урона." % effect.base_value)
			DataManager.EffectCategory.BLOCK:
				desc_parts.append("Даёт %d блока." % effect.base_value)
			DataManager.EffectCategory.HEAL:
				desc_parts.append("Лечит %d HP." % effect.base_value)
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.status:
					desc_parts.append("Накладывает %d %s." % [effect.value, effect.status.get_localized_name()])
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive:
					desc_parts.append("Накладывает %s." % effect.passive.get_localized_name())
			DataManager.EffectCategory.MODIFY_STAT:
				desc_parts.append("Изменяет %s на %d." % [DataManager.FlatStat.keys()[effect.target_stat], effect.delta])
			DataManager.EffectCategory.DRAW_CARD:
				desc_parts.append("Добирает %d карт." % effect.amount)
			DataManager.EffectCategory.GAIN_ENERGY:
				desc_parts.append("Даёт %d энергии." % effect.amount)
	return "\n".join(desc_parts)


func duplicate_for_instance() -> CardData:
	var copy = CardData.new()
	copy.id = id
	copy.origin = origin
	copy.character_class = character_class
	copy.biome = biome
	copy.name_key = name_key
	copy.description_key = description_key
	copy.texture = texture
	copy.tags = tags.duplicate()
	copy.grade = grade
	copy.cost = cost
	copy.overlay_type = overlay_type
	copy.manual_card_types = manual_card_types.duplicate()
	# 🆕 Копируем ручные иконки
	copy.manual_status_icons = manual_status_icons.duplicate()
	copy.manual_passive_icons = manual_passive_icons.duplicate()
	# 🆕 Добавляем новые поля
	copy.upgrade_type = upgrade_type
	copy.is_can_upgrade = is_can_upgrade
	copy.is_burned = is_burned  # 🆕
	
	for effect in effects:
		copy.effects.append(effect.duplicate_for_instance())
	
	return copy

func get_illustration() -> Texture2D:
	return DataManager.get_card_illustration(id)


func get_art_background_color(use_light: bool = false) -> Color:
	return DataManager.get_card_art_background_color(origin, character_class, biome, use_light)


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
			# 🆕 Для SELF урона используем другой ключ
			if effect.target == DataManager.EffectTarget.SELF:
				return tr("effect_damage_self") % effect.base_value
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
				var passive_name = effect.passive.get_localized_name()
				var charges_text = _get_passive_charges_text(effect)
				
				match effect.target:
					DataManager.EffectTarget.SELF:
						return tr("effect_apply_passive_self") % [passive_name, charges_text]
					DataManager.EffectTarget.ENEMY:
						return tr("effect_apply_passive_enemy") % [passive_name, charges_text]
					DataManager.EffectTarget.ALL_ENEMIES:
						return tr("effect_apply_passive_all_enemies") % [passive_name, charges_text]
					DataManager.EffectTarget.ALL_ALLIES:
						return tr("effect_apply_passive_all_allies") % [passive_name, charges_text]
					DataManager.EffectTarget.ANY:
						return tr("effect_apply_passive_any") % [passive_name, charges_text]
					_:
						return tr("effect_apply_passive") % [passive_name, charges_text]
			return ""
		
		DataManager.EffectCategory.MODIFY_STAT:
			var stat_name = _get_stat_name(effect.target_stat)
			var delta_text = _format_delta(effect.delta)
			
			match effect.target:
				DataManager.EffectTarget.SELF:
					return tr("effect_modify_stat_self") % [stat_name, delta_text]
				DataManager.EffectTarget.ENEMY:
					return tr("effect_modify_stat_enemy") % [stat_name, delta_text]
				DataManager.EffectTarget.ALL_ENEMIES:
					return tr("effect_modify_stat_all_enemies") % [stat_name, delta_text]
				DataManager.EffectTarget.ALL_ALLIES:
					return tr("effect_modify_stat_all_allies") % [stat_name, delta_text]
				DataManager.EffectTarget.ANY:
					return tr("effect_modify_stat_any") % [stat_name, delta_text]
				_:
					return tr("effect_modify_stat") % [target_text, stat_name, delta_text]
		
		DataManager.EffectCategory.DRAW_CARD:
			return tr("effect_draw_card") % effect.amount
		
		DataManager.EffectCategory.GAIN_ENERGY:
			return tr("effect_gain_energy") % effect.amount
		
		DataManager.EffectCategory.SCALED_VALUE:
			var resource_name = _get_scaled_resource_name(effect.scaled_resource)
			var values_text = _format_scaled_values(effect.scaled_values)
			var thresholds_text = _format_scaled_thresholds(effect.scaled_thresholds, effect.scaled_compare)
			var spend_text = _get_scaled_spend_text(effect.scaled_spend_resource)
			var type_name = _get_scaled_type_name(effect.scaled_type)
			
			# 🆕 Для DAMAGE используем другие ключи
			if effect.scaled_type == DataManager.ScaledType.DAMAGE:
				match effect.target:
					DataManager.EffectTarget.ENEMY:
						return tr("effect_scaled_damage_enemy") % [values_text, resource_name, thresholds_text, spend_text]
					DataManager.EffectTarget.ALL_ENEMIES:
						return tr("effect_scaled_damage_all_enemies") % [values_text, resource_name, thresholds_text, spend_text]
					DataManager.EffectTarget.ANY:
						return tr("effect_scaled_damage_any") % [values_text, resource_name, thresholds_text, spend_text]
					DataManager.EffectTarget.SELF:
						return tr("effect_scaled_damage_self") % [values_text, resource_name, thresholds_text, spend_text]
			
			# Для остальных типов
			match effect.target:
				DataManager.EffectTarget.SELF:
					return tr("effect_scaled_value_self") % [type_name, values_text, resource_name, thresholds_text, spend_text]
				DataManager.EffectTarget.ENEMY:
					return tr("effect_scaled_value_enemy") % [type_name, values_text, resource_name, thresholds_text, spend_text]
				DataManager.EffectTarget.ALL_ENEMIES:
					return tr("effect_scaled_value_all_enemies") % [type_name, values_text, resource_name, thresholds_text, spend_text]
				_:
					return tr("effect_scaled_value") % [type_name, values_text, resource_name, thresholds_text, spend_text]
		
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
		"res://scripts/conditions/target_has_weakness.gd":  # 🆕
			return tr("condition_target_has_weakness")
		"res://scripts/conditions/target_has_poison.gd":   # 🆕
			return tr("condition_target_has_poison")
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

	# 🆕 Добавляем информацию о сжигании, если карта сгораемая
	if is_burned:
		desc += "\n" + tr("card_is_burned")
	
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
		
		# Заряды
		"1 заряд": " 1 заряд",
		"2 заряд": " 2 заряда",
		"3 заряд": " 3 заряда",
		"4 заряд": " 4 заряда",
		"5 заряд": " 5 зарядов",
		"6 заряд": " 6 зарядов",
		"7 заряд": " 7 зарядов",
		"8 заряд": " 8 зарядов",
		"9 заряд": " 9 зарядов",
		
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

func _get_stat_name(stat: DataManager.FlatStat) -> String:
	match stat:
		DataManager.FlatStat.HEALTH:
			return tr("stat_health")
		DataManager.FlatStat.MAX_HEALTH:
			return tr("stat_max_health")
		DataManager.FlatStat.ENERGY:
			return tr("stat_energy")
		DataManager.FlatStat.MAX_ENERGY:
			return tr("stat_max_energy")
		DataManager.FlatStat.HAND_SIZE:
			return tr("stat_hand_size")
		DataManager.FlatStat.DRAW_PER_TURN:
			return tr("stat_draw_per_turn")
		DataManager.FlatStat.ATONEMENT:
			return tr("stat_atonement")
		DataManager.FlatStat.MAX_ATONEMENT:
			return tr("stat_max_atonement")
		_:
			return DataManager.FlatStat.keys()[stat]
			

func _format_delta(delta: int) -> String:
	if delta > 0:
		return "+" + str(delta)
	elif delta < 0:
		return str(delta)  # уже с минусом
	else:
		return "0"


func _get_passive_charges_text(effect: EffectEntry) -> String:
	if not effect.passive:
		return ""
	
	var charges = effect.passive_duration
	if charges <= 0:
		return ""
	
	return tr("passive_charges_info") % charges


# resources/cards/card_data.gd

func _get_scaled_resource_name(resource: DataManager.ScaledResource) -> String:
	match resource:
		DataManager.ScaledResource.ATONEMENT:
			return tr("scaled_resource_atonement")
		DataManager.ScaledResource.HEALTH:
			return tr("scaled_resource_health")
		DataManager.ScaledResource.MAX_HEALTH:
			return tr("scaled_resource_max_health")
		DataManager.ScaledResource.ENERGY:
			return tr("scaled_resource_energy")
		DataManager.ScaledResource.BLOCK:
			return tr("scaled_resource_block")
		DataManager.ScaledResource.ENEMY_STATUSES:
			return tr("scaled_resource_enemy_statuses")
		DataManager.ScaledResource.PLAYER_STATUSES:
			return tr("scaled_resource_player_statuses")
		DataManager.ScaledResource.BURN_STACKS:
			return tr("scaled_resource_burn_stacks")
		DataManager.ScaledResource.POISON_STACKS:
			return tr("scaled_resource_poison_stacks")
		DataManager.ScaledResource.BLEED_STACKS:
			return tr("scaled_resource_bleed_stacks")
		_:
			return DataManager.ScaledResource.keys()[resource]

func _get_scaled_type_name(type: DataManager.ScaledType) -> String:
	match type:
		DataManager.ScaledType.DAMAGE:
			return tr("scaled_type_damage")
		DataManager.ScaledType.BLOCK:
			return tr("scaled_type_block")
		DataManager.ScaledType.HEAL:
			return tr("scaled_type_heal")
		DataManager.ScaledType.GAIN_ENERGY:
			return tr("scaled_type_energy")
		DataManager.ScaledType.DRAW_CARD:
			return tr("scaled_type_draw")
		DataManager.ScaledType.APPLY_STATUS:
			return tr("scaled_type_apply_status")
		_:
			return DataManager.ScaledType.keys()[type]

func _format_scaled_values(values: Array[int]) -> String:
	var parts: Array[String] = []
	for value in values:
		parts.append(str(value))
	return "/".join(parts)

func _format_scaled_thresholds(thresholds: Array[int], compare: DataManager.ScaledCompare) -> String:
	var compare_symbol = _get_compare_symbol(compare)
	var parts: Array[String] = []
	for threshold in thresholds:
		parts.append(str(threshold))
	return "%s%s" % [compare_symbol, "/".join(parts)]

func _get_compare_symbol(compare: DataManager.ScaledCompare) -> String:
	match compare:
		DataManager.ScaledCompare.GREATER_EQUAL:
			return ">="
		DataManager.ScaledCompare.LESSER_EQUAL:
			return "<="
		DataManager.ScaledCompare.GREATER:
			return ">"
		DataManager.ScaledCompare.LESSER:
			return "<"
		DataManager.ScaledCompare.EQUAL:
			return "="
		_:
			return ""

func _get_scaled_spend_text(spend: bool) -> String:
	if spend:
		return tr("scaled_spend_resource")
	return ""

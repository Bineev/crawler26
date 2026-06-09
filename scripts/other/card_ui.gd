# scripts/ui/card_ui.gd
extends Node2D
class_name CardUI

## ============================================================
## ССЫЛКИ НА НОДЫ
## ============================================================
var template: MarginContainer = null
var cost_label: Label = null
var name_label: Label = null
var art_image: TextureRect = null
var art_background: ColorRect = null
var description_label: RichTextLabel = null
var left_icons: VBoxContainer = null
var right_icons: VBoxContainer = null
var card_control: Control = null

## ============================================================
## ДАННЫЕ КАРТЫ
## ============================================================

@export var card_data: CardData


## ============================================================
## КОНСТАНТЫ (из DataManager)
## ============================================================

const ICON_SIZE: int = DataManager.CARD_ICON_SIZE
const ART_SIZE: int = DataManager.CARD_ART_SIZE
const CARD_BASE_WIDTH: int = DataManager.CARD_BASE_WIDTH
const CARD_BASE_HEIGHT: int = DataManager.CARD_BASE_HEIGHT
const CARD_SCALE_NORMAL: float = DataManager.CARD_SCALE_NORMAL
const CARD_SCALE_HOVER: float = DataManager.CARD_SCALE_HOVER
const CARD_SCALE_IN_HAND: float = DataManager.CARD_SCALE_IN_HAND


## ============================================================
## СОСТОЯНИЕ
## ============================================================

var is_hovered: bool = false
var original_scale: Vector2 = Vector2.ONE
var is_in_hand: bool = false
var is_selectable: bool = true
var is_being_played: bool = false
var original_position: Vector2 = Vector2.ZERO
var original_z_index: int = 0

## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

func _ready():
	# Инициализируем ссылки на ноды по структуре сцены
	template = $CardTemplate
	cost_label = $CardTemplate/CardBackground/CostLabel
	name_label = $CardTemplate/MarginContainer/MainLayout/HeaderLayout/CardName
	art_image = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/ArtContainer/ArtImage
	art_background = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/ArtContainer/ArtBackground
	description_label = $CardTemplate/MarginContainer/MainLayout/DesccriptionContainer/CardDescription
	left_icons = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/LeftIcons
	right_icons = $CardTemplate/MarginContainer/MainLayout/MiddleLayout/RightIcons
	card_control = $CardTemplate
	original_position = position
	original_z_index = z_index
	card_control.mouse_entered.connect(_on_mouse_entered)
	card_control.mouse_exited.connect(_on_mouse_exited)
	card_control.gui_input.connect(_on_gui_input)
	left_icons.custom_minimum_size = Vector2(32, 0)
	right_icons.custom_minimum_size = Vector2(32, 0)
## ============================================================
## ОСНОВНОЙ МЕТОД ЗАПОЛНЕНИЯ КАРТЫ
## ============================================================

func display():
	if not card_data:
		return
	
	cost_label.text = str(card_data.cost)
	
	# Разбиваем название на части для переноса
	var full_name = card_data.get_localized_name()
	name_label.text = _smart_wrap_card_name(full_name)
	
	# Иллюстрация
	var illustration = card_data.get_illustration()
	if illustration and art_image:
		art_image.texture = illustration
	
	description_label.text = card_data.get_localized_description()
	print(description_label.text)
	# Фон карты
	var card_bg = $CardTemplate/CardBackground as TextureRect
	if card_bg:
		var bg_texture = card_data.get_card_background()
		if bg_texture:
			card_bg.texture = bg_texture
	
	art_background.color = card_data.get_art_background_color(true)
	
	clear_icons()
	fill_left_icons()
	fill_right_icons()


func _smart_wrap_card_name(name: String) -> String:
	var words = name.split(" ")
	
	# Если одно слово
	if words.size() <= 1:
		return name
	
	# Список предлогов
	var prepositions = ["of", "the", "and", "to", "for", "with", "by", "in", "on", "at", "from", "into", "through", "during", "without", "against", "among", "along", "between", "about", "like", "via", "per"]
	
	# Если два слова
	if words.size() == 2:
		# Если есть предлог — не переносим
		if words[0].to_lower() in prepositions or words[1].to_lower() in prepositions:
			return name
		# Иначе — переносим
		return words[0] + "\n" + words[1]
	
	# Если три слова и больше — делим на две строки
	# Ищем предлог для красивого переноса
	var split_index = words.size() / 2
	for i in range(words.size()):
		if words[i].to_lower() in prepositions:
			split_index = i
			break
	
	var first_line = " ".join(words.slice(0, split_index))
	var second_line = " ".join(words.slice(split_index, words.size()))
	
	return first_line + "\n" + second_line

## ============================================================
## ОЧИСТКА ИКОНОК
## ============================================================

func clear_icons():
	if left_icons:
		for child in left_icons.get_children():
			child.queue_free()
	if right_icons:
		for child in right_icons.get_children():
			child.queue_free()


## ============================================================
## ЛЕВАЯ КОЛОНКА (статусы и пассивки)
## ============================================================

func fill_left_icons():
	if not left_icons:
		return
	
	var icons: Array[Texture2D] = []
	var tooltips: Array[String] = []
	
	_collect_left_icons_from_effects(card_data.effects, icons, tooltips)
	
	var unique_icons = _unique_icons(icons, tooltips)
	
	for i in range(unique_icons.size()):
		add_icon(left_icons, unique_icons[i]["texture"], unique_icons[i]["tooltip"])


func _collect_left_icons_from_effects(effects: Array[EffectEntry], icons: Array[Texture2D], tooltips: Array[String]):
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.status:
					var icon = DataManager.get_status_icon(effect.status.id)
					if icon:
						icons.append(icon)
						tooltips.append(effect.status.get_localized_name())
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive:
					var icon = DataManager.get_passive_icon(effect.passive.id)
					if icon:
						icons.append(icon)
						tooltips.append(effect.passive.get_localized_name())
			DataManager.EffectCategory.CONDITIONAL:
				if effect.true_effect:
					_collect_left_icons_from_effects([effect.true_effect], icons, tooltips)
				if effect.false_effect:
					_collect_left_icons_from_effects([effect.false_effect], icons, tooltips)


## ============================================================
## ПРАВАЯ КОЛОНКА (типы действий)
## ============================================================

func fill_right_icons():
	if not right_icons:
		return
	
	var icons: Array[Texture2D] = []
	var tooltips: Array[String] = []
	
	for card_type in card_data.get_card_types():
		var icon = DataManager.get_card_type_icon(card_type)
		if not icon:
			continue
		
		match card_type:
			DataManager.CardType.ATTACK:
				_add_right_icon(icon, tr("ui_attack"), icons, tooltips)
			DataManager.CardType.DEFEND:
				_add_right_icon(icon, tr("ui_defend"), icons, tooltips)
			DataManager.CardType.HEAL:
				_add_right_icon(icon, tr("ui_heal"), icons, tooltips)
			DataManager.CardType.RESOURCE:
				_add_right_icon(icon, tr("ui_resource"), icons, tooltips)
			DataManager.CardType.BUFF_SELF:
				_add_right_icon(icon, tr("ui_buff"), icons, tooltips)
			DataManager.CardType.DEBUFF:
				_add_right_icon(icon, tr("ui_debuff"), icons, tooltips)
			DataManager.CardType.UTILITY:
				_add_right_icon(icon, tr("ui_utility"), icons, tooltips)
	
	var unique_icons = _unique_icons(icons, tooltips)
	
	for i in range(unique_icons.size()):
		add_icon(right_icons, unique_icons[i]["texture"], unique_icons[i]["tooltip"])


func _add_right_icon(icon: Texture2D, tooltip: String, icons: Array[Texture2D], tooltips: Array[String]):
	if not icons.has(icon):
		icons.append(icon)
		tooltips.append(tooltip)


## ============================================================
## ДОБАВЛЕНИЕ ИКОНКИ
## ============================================================

func add_icon(container: VBoxContainer, texture: Texture2D, tooltip: String):
	var icon = TextureRect.new()
	icon.texture = texture
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.tooltip_text = tooltip
	container.add_child(icon)


## ============================================================
## ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func _unique_icons(icons: Array[Texture2D], tooltips: Array[String]) -> Array[Dictionary]:
	var unique: Array[Dictionary] = []
	for i in range(icons.size()):
		var exists = false
		for u in unique:
			if u["texture"] == icons[i]:
				exists = true
				break
		if not exists:
			unique.append({"texture": icons[i], "tooltip": tooltips[i]})
	return unique


## ============================================================
## МАСШТАБИРОВАНИЕ
## ============================================================


func set_normal_scale():
	is_in_hand = false
	original_scale = Vector2(CARD_SCALE_NORMAL, CARD_SCALE_NORMAL)
	scale = original_scale


## ============================================================
## АНИМАЦИИ И ВЗАИМОДЕЙСТВИЕ
## ============================================================


func _on_gui_input(event: InputEvent):
	if not is_selectable:
		return
	if is_being_played:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		on_card_clicked()


func on_card_clicked():
	if not is_selectable:
		return
	if is_being_played:
		return
	
	if not BattleManager.is_player_turn():
		return
	
	var player_stats = BattleManager.get_player()
	if not player_stats:
		return
	
	if player_stats.get_flat(DataManager.FlatStat.ENERGY) < card_data.cost:
		SignalManager.log_message.emit(tr("msg_not_enough_energy"))
		return
	
	play_card()


func play_card(target = null):
	if is_being_played:
		return
	
	is_being_played = true
	
	var player_stats = BattleManager.get_player()
	if not player_stats:
		is_being_played = false
		return
	
	# Списываем энергию
	player_stats.modify_flat(DataManager.FlatStat.ENERGY, -card_data.cost)
	
	# Выполняем эффекты карты
	for effect in card_data.effects:
		var targets = _get_targets_for_effect(effect, target)
		EffectExecutor.execute(effect, player_stats, targets, {"card": card_data})
	
	# Отправляем карту в сброс или удаляем
	var battle_deck = BattleManager.get_battle_deck()
	if battle_deck:
		battle_deck.play_card(self, card_data, target)
	else:
		queue_free()
	
	SignalManager.card_played.emit(card_data)
	
	is_being_played = false


func _get_targets_for_effect(effect: EffectEntry, selected_target) -> Array:
	match effect.target:
		DataManager.EffectTarget.SELF:
			return [BattleManager.get_player()]
		DataManager.EffectTarget.ENEMY:
			if selected_target:
				return [selected_target]
			var enemies = BattleManager.get_enemies()
			if enemies.size() > 0:
				return [enemies[0]]
			return []
		DataManager.EffectTarget.ALL_ENEMIES:
			return BattleManager.get_enemies()
		DataManager.EffectTarget.ALL_ALLIES:
			return [BattleManager.get_player()]
		DataManager.EffectTarget.ANY:
			if selected_target:
				return [selected_target]
			return []
	return []


## ============================================================
## ДОПОЛНИТЕЛЬНЫЕ МЕТОДЫ
## ============================================================

func set_selectable(selectable: bool):
	is_selectable = selectable


func get_card_data() -> CardData:
	return card_data


func _on_mouse_entered():
	print('hui')
	if not is_hovered:
		is_hovered = true
		var tween = create_tween()
		tween.set_parallel(true)
		# Увеличиваем масштаб
		tween.tween_property(self, "scale", Vector2(CARD_SCALE_HOVER, CARD_SCALE_HOVER), 0.1)
		# Поднимаем вверх
		tween.tween_property(self, "position", position + Vector2(0, -DataManager.CARD_HOVER_RAISE), 0.1)
		# Поднимаем Z-index, чтобы карта была поверх других
		z_index = 10


func _on_mouse_exited():
	if is_hovered:
		is_hovered = false
		var tween = create_tween()
		tween.set_parallel(true)
		# Возвращаем масштаб
		tween.tween_property(self, "scale", original_scale, 0.1)
		# Возвращаем позицию
		tween.tween_property(self, "position", original_position, 0.1)
		# Возвращаем Z-index
		tween.tween_callback(func(): z_index = original_z_index)


func set_hand_scale():
	is_in_hand = true
	original_scale = Vector2(DataManager.CARD_SCALE_IN_HAND, DataManager.CARD_SCALE_IN_HAND)
	original_position = position
	original_z_index = z_index
	scale = original_scale

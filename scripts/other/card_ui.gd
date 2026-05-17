# scripts/ui/card_ui.gd
extends Node2D
class_name CardUI

## ============================================================
## ССЫЛКИ НА НОДЫ (%)
## ============================================================

@onready var template: MarginContainer = %CardTemplate
@onready var cost_label: Label = %CostLabel
@onready var name_label: Label = %CardName
@onready var art_image: TextureRect = %ArtImage
@onready var art_background: ColorRect = %ArtBackground
@onready var description_label: RichTextLabel = %CardDescription
@onready var left_icons: VBoxContainer = %LeftIcons
@onready var right_icons: VBoxContainer = %RightIcons


## ============================================================
## ДАННЫЕ КАРТЫ
## ============================================================

@export var card_data: CardData


## ============================================================
## КОНСТАНТЫ (из DataManager)
## ============================================================

const ICON_SIZE: int = DataManager.CARD_ICON_SIZE
const ART_SIZE: int = DataManager.CARD_ART_SIZE
const CARD_WIDTH: int = DataManager.CARD_WIDTH
const CARD_HEIGHT: int = DataManager.CARD_HEIGHT
const CARD_SCALE_NORMAL: float = DataManager.CARD_SCALE_NORMAL
const CARD_SCALE_HOVER: float = DataManager.CARD_SCALE_HOVER
const CARD_SCALE_IN_HAND: float = DataManager.CARD_SCALE_IN_HAND


## ============================================================
## СОСТОЯНИЕ
## ============================================================

var is_hovered: bool = false
var original_scale: Vector2 = Vector2.ONE


## ============================================================
## ИНИЦИАЛИЗАЦИЯ
## ============================================================

func _ready():
	if card_data:
		display()


## ============================================================
## ОСНОВНОЙ МЕТОД ЗАПОЛНЕНИЯ КАРТЫ
## ============================================================

func display():
	if not card_data:
		return
	
	# Базовые поля
	cost_label.text = str(card_data.cost)
	name_label.text = card_data.get_localized_name()
	art_image.texture = card_data.texture
	description_label.text = card_data.get_localized_description()
	
	# Цвет подложки иллюстрации (из персонажа / биома)
	art_background.color = card_data.get_base_color()
	
	# Очистка и заполнение иконок
	clear_icons()
	fill_left_icons()
	fill_right_icons()


## ============================================================
## ОЧИСТКА ИКОНОК
## ============================================================

func clear_icons():
	for child in left_icons.get_children():
		child.queue_free()
	for child in right_icons.get_children():
		child.queue_free()


## ============================================================
## ЛЕВАЯ КОЛОНКА (статусы и пассивки, которые карта накладывает)
## ============================================================

func fill_left_icons():
	var icons: Array[Texture2D] = []
	var tooltips: Array[String] = []
	
	_collect_left_icons_from_effects(card_data.effects, icons, tooltips)
	
	# Убираем дубликаты (по текстуре)
	var unique_icons = _unique_icons(icons, tooltips)
	
	for i in range(unique_icons.size()):
		add_icon(left_icons, unique_icons[i]["texture"], unique_icons[i]["tooltip"])


func _collect_left_icons_from_effects(effects: Array[EffectEntry], icons: Array[Texture2D], tooltips: Array[String]):
	for effect in effects:
		match effect.category:
			DataManager.EffectCategory.APPLY_STATUS:
				if effect.status and effect.status.icon:
					icons.append(effect.status.icon)
					tooltips.append(effect.status.get_localized_name())
			DataManager.EffectCategory.APPLY_PASSIVE:
				if effect.passive and effect.passive.icon:
					icons.append(effect.passive.icon)
					tooltips.append(effect.passive.get_localized_name())
			DataManager.EffectCategory.CONDITIONAL:
				if effect.true_effect:
					_collect_left_icons_from_effects([effect.true_effect], icons, tooltips)
				if effect.false_effect:
					_collect_left_icons_from_effects([effect.false_effect], icons, tooltips)


## ============================================================
## ПРАВАЯ КОЛОНКА (глобальные категории действий)
## ============================================================

func fill_right_icons():
	var icons: Array[Texture2D] = []
	var tooltips: Array[String] = []
	
	for card_type in card_data.get_card_types():
		match card_type:
			DataManager.CardType.ATTACK:
				_add_right_icon(DataManager.ICON_DAMAGE, "Атака", icons, tooltips)
			DataManager.CardType.BLOCK:
				_add_right_icon(DataManager.ICON_BLOCK, "Защита", icons, tooltips)
			DataManager.CardType.HEAL:
				_add_right_icon(DataManager.ICON_HEAL, "Лечение", icons, tooltips)
			DataManager.CardType.RESOURCE:
				_add_right_icon(DataManager.ICON_RESOURCE, "Ресурс (Искупление)", icons, tooltips)
			DataManager.CardType.BUFF_SELF:
				_add_right_icon(DataManager.ICON_BUFF, "Бафф на себя", icons, tooltips)
			DataManager.CardType.DEBUFF:
				_add_right_icon(DataManager.ICON_DEBUFF, "Дебафф на врага", icons, tooltips)
			DataManager.CardType.UTILITY:
				_add_right_icon(DataManager.ICON_UTILITY, "Утилити", icons, tooltips)
	
	var unique_icons = _unique_icons(icons, tooltips)
	
	for i in range(unique_icons.size()):
		add_icon(right_icons, unique_icons[i]["texture"], unique_icons[i]["tooltip"])


func _add_right_icon(icon: Texture2D, tooltip: String, icons: Array[Texture2D], tooltips: Array[String]):
	if not icons.has(icon):
		icons.append(icon)
		tooltips.append(tooltip)


## ============================================================
## ДОБАВЛЕНИЕ ИКОНКИ В КОНТЕЙНЕР
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
## АНИМАЦИИ И ВЗАИМОДЕЙСТВИЕ
## ============================================================

func _on_mouse_entered():
	is_hovered = true
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(CARD_SCALE_HOVER, CARD_SCALE_HOVER), 0.1)

func _on_mouse_exited():
	is_hovered = false
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, 0.1)

func set_hand_scale():
	original_scale = Vector2(CARD_SCALE_IN_HAND, CARD_SCALE_IN_HAND)
	scale = original_scale

func set_normal_scale():
	original_scale = Vector2(CARD_SCALE_NORMAL, CARD_SCALE_NORMAL)
	scale = original_scale

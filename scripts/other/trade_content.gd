extends VBoxContainer
class_name TradeContent

var shop_items: Array[Dictionary] = []
var is_processing: bool = false
const ARTIFACT_ICON_SCENE = preload("res://scenes/artifact_icon.tscn")

@onready var cards_container: HBoxContainer = $CardsContainer
@onready var artifacts_container: HBoxContainer = $ArtifactsContainer
@onready var potions_container: HBoxContainer = $PotionsContainer


func setup(items: Array[Dictionary]) -> void:
	shop_items = items
	
	for item in items:
		match item["type"]:
			"card":
				_add_card_item(item)
			"artifact":
				_add_artifact_item(item)
			"potion":
				_add_potion_item(item)
	
	_update_buttons()
	SignalManager.coins_changed.connect(_on_coins_changed)
	await get_tree().create_timer(0.2).timeout
	cards_container.custom_minimum_size = cards_container.size
	artifacts_container.custom_minimum_size = artifacts_container.size
	potions_container.custom_minimum_size = potions_container.size

func _add_card_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	var card_ui = load("res://scenes/card.tscn").instantiate() as CardUI
	card_ui.card_data = item["data"]
	var card_container = Container.new()
	card_container.add_child(card_ui)
	# Сначала добавляем card_ui в container
	container.add_child(card_container)
	# Добавляем container в дерево
	cards_container.add_child(container)
	# Теперь можно настраивать
	card_ui.display()
	card_ui.card_control.scale = Vector2(0.7, 0.7)
	card_ui.set_reward_state()
	card_container.custom_minimum_size = card_ui.get_actual_size() * 1.2
	
	var buy_button = Button.new()
	var price = _get_price(item)
	buy_button.text = str(price)
	buy_button.add_theme_font_override("font", DataManager.FONT_MAIN)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.custom_minimum_size = Vector2(100, 30)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE

func _add_artifact_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 5)
	
	var artifact_icon = load("res://scenes/artifact_icon.tscn").instantiate() as ArtifactIcon
	
	# Сначала добавляем artifact_icon в container
	container.add_child(artifact_icon)
	
	# Добавляем container в дерево
	artifacts_container.add_child(container)
	
	# Теперь можно настраивать
	artifact_icon.setup(item["data"], true)
	artifact_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var buy_button = Button.new()
	var price = _get_price(item)
	buy_button.text = str(price)
	buy_button.add_theme_font_override("font", DataManager.FONT_MAIN)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.custom_minimum_size = Vector2(100, 30)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE

func _add_potion_item(item: Dictionary) -> void:
	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 10)
	
	var potion_icon = load("res://scenes/potion_icon.tscn").instantiate() as PotionIcon
	
	# Сначала добавляем potion_icon в container
	container.add_child(potion_icon)
	
	# Добавляем container в дерево
	potions_container.add_child(container)
	
	# Теперь можно настраивать
	potion_icon.setup(item["data"])
	potion_icon.set_interactable(false)
	
	var buy_button = Button.new()
	var price = _get_price(item)
	buy_button.text = str(price)
	buy_button.add_theme_font_override("font", DataManager.FONT_MAIN)
	buy_button.add_theme_font_size_override("font_size", 16)
	buy_button.custom_minimum_size = Vector2(100, 30)
	buy_button.pressed.connect(_on_buy_pressed.bind(item, container))
	buy_button.set_meta("price", price)
	container.add_child(buy_button)
	buy_button.focus_mode = Control.FOCUS_NONE

func _get_price(item: Dictionary) -> int:
	var data = item["data"]
	var grade = DataManager.CostGrade.NORMAL
	
	# Если у ресурса есть cost_grade — используем его
	if data.has_method("get_cost_grade"):
		grade = data.get_cost_grade()
	
	return int(grade) * DataManager.DEFAULT_ITEM_COST


func _update_buttons() -> void:
	var coins = RunManager.get_coins()
	
	for container in [cards_container, artifacts_container, potions_container]:
		for vbox in container.get_children():
			var button = vbox.get_child(-1)
			if button is Button:
				var price = button.get_meta("price", 0)
				button.disabled = coins < price

func _on_coins_changed(amount: int) -> void:
	_update_buttons()

func _on_buy_pressed(item: Dictionary, container: Control) -> void:
	if is_processing:
		return
	is_processing = true
	
	var price = _get_price(item)
	
	if RunManager.get_coins() < price:
		SignalManager.log_message.emit("Недостаточно золота!")
		is_processing = false
		return
	
	RunManager.spend_coins(price)
	
	match item["type"]:
		"card":
			RunManager.add_card(item["data"])
			SignalManager.log_message.emit("Куплена карта: %s" % item["data"].get_localized_name())
		"artifact":
			RunManager.add_artifact(item["data"])
			SignalManager.log_message.emit("Куплен артефакт: %s" % item["data"].get_localized_name())
		"potion":
			RunManager.add_potion(item["data"])
			SignalManager.log_message.emit("Куплено зелье: %s" % item["data"].get_localized_name())
	
	container.queue_free()
	is_processing = false
